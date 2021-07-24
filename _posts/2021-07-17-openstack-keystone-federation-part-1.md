---
title: Keystone federation++
series: OpenStack dev stories
layout: post
toc: true
---

At [Chameleon](https://www.chameleoncloud.org), I help develop and operate a series of
[OpenStack](https://openstack.org) cloud deployments, which have been modded to serve as
a powerful general-purpose testbed for Computer Science research. Currently Chameleon is
deployed at three separate host institutions and provides over six thousand CS
researchers with bare metal access to a diverse range of state-of-the-art hardware
configurations.

Last year we worked to replace our old legacy authentication and identity system. Users
up until that time had to register for a separate account for Chameleon, and used that
username and password to authenticate against
[Keystone](https://docs.openstack.org/keystone/latest/), OpenStack's identity system. We
first had Keystone verify the user's credentials against our central account database,
but this made it a single point of failure, so at some point we switched to provisioning
the accounts directly in Keystone at user registration time so Keystone could locally
verify credentials. Because we had multiple sites at different locations that we needed
to keep in sync with the accounts we had active in the system, we also experimented with
running a [geo-distributed MariaDB
cluster](https://galeracluster.com/2015/07/geo-distributed-database-clusters-with-galera/)
just for Keystone in order to transparently share user accounts between multiple cloud
sites: every OpenStack site effectively would be sharing a single user and project
database, but would use its own database(s) for the other services. This
however required us to coordinate changes to the Keystone database schema (e.g., during
OpenStack upgrades) across all the sites, making upgrades much harder than they had to
be. It also made it harder to add and integrate additional sites.

It was time for a change. We wanted a system that was simpler for users to use
and be onboarded into, while also scaling well to arbitrary numbers of cloud
deployment sites. Federated identity provided the solution, but it took some
hacking to get us there.

## Goals for a federated identity system

Early on, we identified a few goals of the system from a product perspective:

**Users should be able to log in with existing credentials.** Chameleon caters
to the research community, many of whom already have accounts at their host
institution or national laboratory. For those who do not have such accounts, we
would support a general-purpose identity such as Google or
[ORCiD](https://orcid.org).

**A user's login session should carry across applications.** Prior, users of
Chameleon's various OpenStack clouds would have to log in to each cloud
separately, though with the same credentials. Single Sign-On (SSO) makes sense
to use for our systems and is a better user experience.

**The system should integrate with all existing applications.** Besides various
Keystone deployments, Chameleon also has a user management portal, which is a
Django web application, and a [JupyterHub](https://jupyter.org/hub) deployment.
The identity system should support all of these, and should be flexible enough
to support more applications in the future.

**CLI/API authentication must be supported.** Many users use CLI interfaces to
Chameleon's cloud systems and we had to ensure we did not break this or make it
significantly more onerous. If you've used OpenStack's clients before, you know
how burdensome figuring out the right authentication parameters can already be.

**Store as little user inforation as possible.** We don't want to be responsible
for storing sensitive data about users, such as passwords, which may be re-used
on other sites. Similarly, we don't want to store a lot of contact information
about the users. To whatever extent we can rely on information fetched from an
upstream source, such as Google or [Globus](https://globus.org), we should. This
approach is also in-line with data privacy regulations such as
[GDPR](https://gdpr-info.eu).

#### Additional constraints

There are a few important rules about Chameleon accounts:

1. Users can be members of one or more projects.
2. Every project has one user acting as the project owner, who can add other users to
   the project.
3. Projects are authorized to use cloud resources by having an "allocation": this is
   effectively a "budget" they are allowed to spend over a fixed amount of time.
3. Both projects and users can be disabled, e.g., if the project's allocation expires
   or the project/user demonstrates irresponsible use or abuse of resources.

These constraints added some additional goals:

**Authorization policies should be flexible and per-client.** When a user first joins
Chameleon, they will likely not be a part of any projects. Similarly, if returning after
a long time, it's possible their pre-existing projects have expired. Depending on the
application, users not belonging to any authorized projects should still have access,
i.e., login shouldn't simply fail as a general rule.

**Changes to project memberships should propagate as soon as possible.** Users often
wrote in to support asking why they didn't have access to a project, when in fact
they did, but the change had not yet been synced to all the Keystone services.

**Users should not be allowed to perform actions under disabled projects.**
This is somewhat obvious, but important enough to call out, as it's how we
prevent unauthorized usage of cloud resources.

#### Final design

Ultimately, we decided on a design that uses [Keycloak](https://keycloak.org) as a
central identity provider. Keycloak keeps track of all users, projects (groups) and the
group memberships. From an application like Keystone's perspective, Keycloak serves as
the [OpenID Provider
(OP)](https://openid.net/specs/openid-connect-core-1_0.html#Terminology). The
applications use standard OpenID Connect authentication flows to log in the user and
obtain some claims about the user from Keycloak. Project memberships are included in
claims so that at login time, the client application knows what projects the user
belongs to. This is particularly important for Keystone, which has no support for
fetching user information after login (via, e.g. OpenID's
[UserInfo](https://openid.net/specs/openid-connect-core-1_0.html#UserInfo) endpoint).

Keystone needed several adjustments to properly integrate with our design, which
demanded more from the system than it could support by default. The rest of this
post goes into detail about those modifications. OpenStack is open source, let's
take advantage of that fact!

## A brief guide to Keystone federation

[Keystone's own
documentation](https://docs.openstack.org/keystone/latest/admin/federation/introduction.html#what-is-keystone-federation)
will do a far better job than I of explaining what federated identity is in general, and
how Keystone supports it. The main thing to know is that Keystone supports registering a
_mapping_, expressed as a JSON file following a defined schema, which describes how
[OpenID Connect (OIDC)](https://openid.net/connect/) or
[SAML](https://www.oasis-open.org/committees/tc_home.php?wg_abbrev=security) **claims**
should map to Keystone entities. A claim is some metadata that is attached to the
authentication token generated by the identity provider, and typically has some basic
information about the user, such as their username, email address, and possibly other
contact details. The specifics are ultimately up to the identity provider. This means
that if you control the identity provider implementation, you have a lot of options open
to you. Claims for OIDC are encoded as [JSON Web Tokens (JWTs)](https://jwt.io/), so
they can look something like this:

<!-- prettier-ignore -->
{% highlight json %}
{
  "FirstName": "James",
  "LastName": "Kirk",
  "Email": "jameskirk@example.com",
  "Groups": ["Staff", "Bridge"]
}
{% endhighlight %}

Here is a simple Keystone federation mapping, just so you have an idea. With this
mapping, when a user logs in, Keystone will automatically provision a federated user
named "{FirstName} {LastName}" with the email "{Email}", where those bracketed parts
would be resolved from the OIDC or SAML claims. The bracketed tokens in the mapping
refer to "slots" in the "remotes" section; the 0th slot contains the value of the
"FirstName" claim.

> **Note**: the best guide for the mapping syntax is the [Mapping
> Combinations](https://docs.openstack.org/keystone/latest/admin/federation/mapping_combinations.html)
> documentation, which goes over all the pieces of the syntax and gives some examples.
> It is, however, not incredibly extensive. It takes a while to grok the mapping system,
> as it may not work in the way you immediately expect. But, it is ultimately very
> powerful and gets the job done.

<!-- prettier-ignore -->
{% highlight json %}
{
  "rules": [
    {
      "local": [
        {
          "user": {
            "name": "{0} {1}",
            "email": "{2}"
          },
        }
      ],
      "remote": [
        {
          "type": "FirstName"
        },
        {
          "type": "LastName"
        },
        {
          "type": "Email"
        }
      ]
    }
  ]
}
{% endhighlight %}

Automatically creating users is useful, but really what we want is to associate that
user with a Keystone _project_. Projects are central to Keystone and the other OpenStack
services as they're the main way the system tracks usage and ownership. Therefore we
ultimately want to be able to sort users into projects via this mapping. Fortunately, in
addition to the "user" mapping target, the engine also supports a "projects" target.
When a user is mapped to a project, Keystone will automatically provision the project if
it doesn't already exist, which means the cloud operator has to do very little work
ahead of time, and indeed, doesn't need to do additional work for any additional future
projects. This can however cause difficulties if projects which were never intended to
wind up in Keystone get auto-provisioned, so some care must be taken to filter these
out. Here's what a mapping with projects looks like. It looks at a "Department" claim
containing the name of the user's department within the organization and puts them into
a project for that department.

<!-- prettier-ignore -->
{% highlight json %}
{
  "rules": [
    {
      "local": [
        {
          "user": {
            "name": "{0} {1}",
            "email": "{2}"
          },
        },
        {
          "projects": {
            "name": "{3}",
            "roles": [
              {
                "name": "member"
              }
            ]
          }
        }
      ],
      "remote": [
        {
          "type": "FirstName"
        },
        {
          "type": "LastName"
        },
        {
          "type": "Email"
        },
        {
          "type": "Department"
        }
      ]
    }
  ]
}
{% endhighlight %}

The mapping engine does have a few filtering mechanisms available, allowing operators to
filter out some values of a claim containing multiple entries (such as the "groups"
claim). The filter mechanism can also be used to disallow users with some claims to log
in at all; this can be useful if you only want to allow a subset of users in the
identity provider access to the cloud.

As mentioned eariler, rather than directly integrate Keystone with a third-party
identity provider, such as GitHub, or Google, or Globus, we decided to deploy and
configure our own intermediate identity provider using Keycloak. This ended up being a
very good decision because it allowed us to reap the benefits of upstream identity
providers such as Globus while being able to control how claims were delivered
downstream to our Keycloak clients. For example, we could write a [custom OIDC claim
provider](https://github.com/ChameleonCloud/keycloak-chameleon/blob/1502bee80e27c9821247926c7e3fd37c3e4a695d/src/main/java/org/chameleoncloud/ChameleonProjectMapper.java)
that returned the precise list of projects that the authenticating user was a member of,
and filter that list to only include enabled projects, based on Keycloak group
attributes we were managing via a separate accounting system. The ability to create
custom claims came in very handy, as we'll see below.

## The missing pieces

After evaluating Keystone's federation offering, it became clear that we would have some
troubles. Fortunately, and it's a testament to Keystone's design that I was able to do
this, all blockers were resolved with relatively minimal changes or modifications to
Keystone, and in all cases we were adding new functionality to Keystone rather than
making breaking changes to existing functionality. These kind of changes are easier to
carry forward into future OpenStack releases even if they are not accepted by core
contributors.

In all cases, I tried to structure the solution to our problem such that it addressed as
wide a set of use cases as possible, rather than doing one-off hacks just for our
deployment. While more difficult, the hope is this improves the chances of us releasing
the patches upstream.

### Multiple projects per user

The first thing I noticed was that auto-provisioning of projects didn't work quite like
I expected. In the following simple mapping, consider a test user that has OIDC claims
like this:

<!-- prettier-ignore -->
{% highlight json %}
{
  "preferred_username": "jason@example.com",
  "projects": ["MyProject", "MyOtherProject"]
}
{% endhighlight %}

With the following mapping, I would expect this user is added to two projects, one
called MyProject and one called MyOtherProject, and each project would be lazily created
if it did not already exist.

<!-- prettier-ignore -->
{% highlight json %}
{
  "rules": [
    {
      "local": [
        {
          "user": {
            "name": "{0}"
          }
        },
        {
          "projects": [
            {
              "name": "{1}",
              "roles": {
                "name": "member"
              }
            }
          ]
        }
      ],
      "remote": [
        {
          "type": "OIDC-preferred_username"
        },
        {
          "type": "OIDC-projects"
        }
      ]
    }
  ]
}
{% endhighlight %}

This however was not the case! Instead, a single project was created, with
the entire list of project names encoded as the name field:

<!-- prettier-ignore -->
{% highlight shell %}
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description |                                  |
| domain_id   | b5bb9d8014a0f9b1d61e21e796d78dcd |
| enabled     | True                             |
| id          | 1352f23cd32812f4850b878ae494af78 |
| is_domain   | False                            |
| name        | ["MyProject","MyOtherProject"]   |
| options     | {}                               |
| parent_id   | b5bb9d8014a0f9b1d61e21e796d78dcd |
| tags        | []                               |
+-------------+----------------------------------+
{% endhighlight %}

This turned out to be because not all mapping "targets" in Keystone's
federation mapping could support the input being a list. When the input claim
is a list, the desired behavior is to expand the list, mapping to N targets
instead of 1.

The patch for this,
[keystone/727891](https://review.opendev.org/c/openstack/keystone/+/727891),
ended up a bit more complicated, because it also added the missing support for
mapping multiple role names. We did not need support for mapping multiple roles,
as all users just get the default "member" role on their projects, but it was
simple enough to make it worthwhile to have the consistency.

### Auto-remove users

It turns out that, while users can be added to projects lazily on first login,
they are never removed from these projects if their claims change later! This
was important to fix, because it meant that users would retain access to any
of their past projects forever.

[keystone/741785](https://review.opendev.org/c/openstack/keystone/+/741785) adds
a new Keystone configuration setting `remove_dangling_assignments`, which is
turned off by default to maintain old behavior. If turned on, however, users
will be removed from any projects not matching their claims. This only applies
to projects within the identity provider domain (so, any projects in other
domains or the default domain will be untouched).

### Rich claim objects

Keystone reasonably assumes that claims are going to either be strings, or
lists of strings. We however had a very specific need, and while it's a bit of
a silly need relative to the technical complexity required to fulfill it, it
ultimately drove a few improvements that make the Keystone mapping engine
significantly more powerful.

#### Motivation

When users are logged in to the OpenStack GUI, in the top nav bar they have a
project selector dropdown, which displays the name of the project. In Chameleon,
all of our projects have immutable names--this is important because the names
act as foreign keys, allowing projects to be matched up across cloud
deployments. These names are however not very user-friendly: they look like a
prefix followed by a set of 6 numbers. Users who are members of multiple
projects very often get them confused. So, at some point we added support for
displaying the project's "nickname" in this field; we stored the nickname as an
additional extra field on the project entity (Keystone already supported this.)
We then patched the GUI to show that field value if it was present. Users were
glad to have it.

With federated projects being auto-provisioned, we had to somehow sneak that
nickname field in there. We could have opted to periodically sync the nickname
directly to the project via some out-of-band process, but we had come this far
without having to fall back on syncing, and one of the design goals of the
architecture was to avoid this. And, the sync solution would have to be
maintained for every Keystone deployment we had, now and in the future. So, what
can we do?

The first step was to update our Keycloak IdP to return a more complex
representation for the projects a user belonged to:

<!-- prettier-ignore -->
{% highlight json %}
{
  "preferred_username": "jason@example.com",
  "projects": [
    {"name": "P-123456", "nickname": "MyProject"},
    {"name": "P-234567", "nickname": "OtherProject"}
  ]
}
{% endhighlight %}

So now instead of having the "projects" claim be a list of IDs/names, we have
a richer representation containing both. Now we have to get Keystone to accept
this new reality.

#### Parsing entire assertion as JSON

Keystone delegates the authentication and authorization to some service sitting
directly in front of Keystone. That service is responsible for doing all the
handshakes and claim verification, before passing the claims to the Keystone
wsgi handler. Keystone then sees those claims as environment variables or HTTP
headers. For OpenID, the `mod_auth_openidc` Apache module is the recommended
solution for this. Now, when using a richer claim structure, the first thing I
noticed was that the claim wasn't being properly passed down to Keystone,
because the Apache module couldn't understand how to parse and then re-serialize
the claim; it was not expecting a nested JSON structure.

The solution to this was to configure the module to just pass all the claims
directly through to Keystone in a big JSON blob. This is possible by changing
the
"[OIDCPassIDTokenAs](https://github.com/zmartzone/mod_auth_openidc/blob/276bdafdb241bd88cb1069035df79e23ef4a0ada/auth_openidc.conf#L748)"
`mod_auth_openidc` setting from "claims" to "claims payload", meaning that both
the individual claims are passed as environment/headers, but also one
environment variable will contain the entire payload encoded as JSON.

I then wrote a little patch (not yet submitted) to add a new `assertion_payload`
configuration setting, which can be set to the name of the environment variable
that will hold the entire set of claims encoded as JSON. Keystone will then
parse the value of that variable as JSON and update its internal representation
of the assertion claims accordingly. This allowed the rich claims to make it
into the mapping engine.

> **Note**: you'll see in the mapping examples that the "remote" section
> references claims without the "OIDC-" prefix; the way I wrote the patch, the
> claims that come from parsing the entire JSON payload just get added w/o a
> prefix.

#### Mapping "extra" properties

Next, the "projects" mapper needed support for actually specifying this "extra"
metadata to set on the project when it was created. Another patch adds support
for this in the mapping engine, allowing you to specify an "extra" field in a
project mapper to set additional fields:

<!-- prettier-ignore -->
{% highlight json %}
{
  "rules": [
    {
      "local": [
        {
          "user": {
            "name": "{0}"
          }
        },
        {
          "projects": [
            {
              "name": "{1}",
              "extra": {
                "extra-key": "extra-value",
                "extra_key2": "extra-value2"
              },
              "roles": {
                "name": "member"
              }
            }
          ]
        }
      ],
      "remote": [
        {
          "type": "preferred_username"
        },
        {
          "type": "projects"
        }
      ]
    }
  ]
}
{% endhighlight %}

These extra fields can also contain tokens like "{0}", so they can contain
values mapped from claims.

#### Map fields over claim list items

We're still missing the final piece: how to wire in our list of projects such
that, for each item in the list, the "name" attribute of the project in the
claim is mapped to the project name, while the "nickname" is mapped to an extra
field?

To solve this, I updated the mapping engine to support more types of token
placeholders than just "{0}", "{1}", etc. The engine now can support tokens
like "{0[name]}", which tells it:

> Look at the claim referenced in the first slot of my declared 'remotes'.
>
> If the claim is an object, return the 'name' field.
>
> If the claim is a list, return a list of all the 'name' fields for each item
> in the list.
>
> If the claim is neither an object nor a list, or is otherwise malformed,
> return nothing.

If you're into functional programming, this effectively provides a way to
express a map operation, albeit with very limited inputs.

This now (finally) allows us to express our mapping using Keystone's mapping
definition:

<!-- prettier-ignore -->
{% highlight json %}
[
  {
    "local": [
      {
        "user": {
          "name": "{0}"
        }
      },
      {
        "projects": [
          {
            "name": "{2[name]}",
            "extra": {
              "nickname": "{2[nickname]}"
            },
            "roles": [
              {
                "name": "member"
              }
            ]
          }
        ]
      }
    ],
    "remote": [
      {
        "type": "preferred_username"
      },
      {
        "type": "projects"
      }
    ]
  }
]
{% endhighlight %}

> **Note**: these lookups don't go any further than one level, so it's not
> possible to do like "{0[child][name]}" or something like that. At some point
> one has to draw the line!

## Additional traps

Once the whole integration was more or less working, it was time to polish up
the user experience and deal with a few less critical issues I encountered.

### Regex whitelist/blacklist

We experimented with using nested Keycloak groups (and [fine grained admin
permissions](https://www.keycloak.org/docs/latest/server_admin/index.html#_fine_grain_permissions))
to model the idea of roles within a project: some users should be able to add
and remove users, while others cannot. This meant that our Keycloak groups might
look like this:

<!-- prettier-ignore -->
{% highlight shell %}
/ProjectA
  /ProjectA-managers
/ProjectB
  /ProjectB-managers
{% endhighlight %}

The "\*-managers" groups are used to apply custom Keycloak policies, allowing
any user in that group to manage the parent group's memberships. For this to
work, a user will have to be in both groups, e.g., in both ProjectA and
ProjectA-managers. Yet, we can see that there shouldn't really be a Keystone
project called "ProjectA-managers", as it's not really a "real" project.

The solution for this normally is to add the projects that should be ignored
to a "blacklist" in the Keystone mapping:

<!-- prettier-ignore -->
{% highlight json %}
"remote": [
  {
    "type": "projects",
    "blacklist": ["ProjectA-managers", "ProjectB-managers"]
  }
]
{% endhighlight %}

However, this doesn't scale. Keystone's `any_one_of` and `not_any_of` mapping
filters support regexes, but this was never added to the `blacklist` or
`whitelist` filters for some reason.
[keystone/730423](https://review.opendev.org/c/openstack/keystone/+/730423) adds
support for regexes to these filters, so we could now do this:

<!-- prettier-ignore -->
{% highlight json %}
"remote": [
  {
    "type": "projects",
    "blacklist": ".*-managers$",
    "regex": true
  }
]
{% endhighlight %}

This doesn't work yet though, because we added in those fancy rich claims, which
have nested fields. I really wanted to tell the mapping, filter out any items in
the "projects" claim, _if the "name" attribute on that item has a certain
value_. So, I had to write another patch on top of this patch to be able to
apply filters to nested fields. This part of the mapping now finally becomes:

<!-- prettier-ignore -->
{% highlight json %}
"remote": [
  {
    "type": "projects",
    "blacklist": {
      "name": [
        ".*-managers$"
      ]
    },
    "regex": true
  }
]
{% endhighlight %}

### Loose constraints

Another interesting thing that came up was how to deal with users who were not a
member of any projects. Normally, this would cause the entire mapping (and thus
the login) to fail, because it is assumed that there is at least one item in a
list claim for the mapping to succeed. From our perspective though, it's totally
fine to allow the user through, they just shouldn't be a member of any projects.
OpenStack will disallow these users from doing anything without a project, but
it at least gives us a chance to show a nicer error message to them, indicating
they need to be added to a project or request to be added to one.

The simplest fix was to add the idea of "optional" claims. If a claim is marked
optional, then the mapping can still pass even if the claim is undefined or
empty. We can then allow the "projects" list to be empty like so:

<!-- prettier-ignore -->
{% highlight json %}
"remote": [
  {
    "type": "projects",
    "optional": true,
    "blacklist": {
      "name": [
        ".*-managers$"
      ]
    },
    "regex": true
  }
]
{% endhighlight %}

### OpenID provider discovery

[kolla-ansible/695432](https://review.opendev.org/c/openstack/kolla-ansible/+/695432)
added support for configuring all the relevant bits and bobs for OpenID
federation if you're using Kolla Ansible to manage your OpenStack deployment!
In doing so, it configures `mod_auth_openidc` for _multiple_ OpenID providers.
The reason for this is that it's feasible that a cloud deployer would configure
multiple identity providers in Keystone. When `mod_auth_openidc` is set up this
way, though, it will take all login requests through an additional interstitial
page, which asks the user to confirm which configured OP they want to use.

This is redundant and unnecessary, as Keystone already allows the user to select
which IdP they want to use. We can bypass this by implementing [OpenID Connect
Discovery](https://openid.net/specs/openid-connect-discovery-1_0.html) and then
setting the
[`OIDCDiscoverURL`](https://github.com/zmartzone/mod_auth_openidc/blob/276bdafdb241bd88cb1069035df79e23ef4a0ada/auth_openidc.conf#L653-L665)
configuration option:

<!-- prettier-ignore-start -->
{% highlight conf %}
# Defines an external OP Discovery page. That page will be called with:
#    <discovery-url>?oidc_callback=<callback-url>
# additional parameters may be added, a.o. `target_link_uri`, `x_csrf` and `method`.
#
# An Issuer selection can be passed back to the callback URL as in:
#    <callback-url>?iss=[${issuer}|${domain}|${e-mail-style-account-name}][parameters][&login_hint=<login-hint>][&scopes=<scopes>][&auth_request_params=<params>]
# where the <iss> parameter contains the URL-encoded issuer value of
# the selected Provider, or a URL-encoded account name for OpenID
# Connect Discovery purposes (aka. e-mail style identifier), or a domain name.
# [parameters] contains the additional parameters that were passed in on the discovery request (e.g. target_link_uri=<url>&x_csrf=<x_csrf>&method=<method>&scopes=<scopes>)
#
# When not defined the bare-bones internal OP Discovery page is used.
OIDCDiscoverURL <discovery-url>
{% endhighlight %}
<!-- prettier-ignore-end -->

I wrote a patch to add a new Keystone endpoint hanging off of the same prefix
as the rest of the federation endpoints. It is responsible for redirecting
to the callback URL and setting the pre-selected identity provider parameters
such as "iss". This is possible because the discover endpoint will receive
the `target_link_uri` parameter, which will be a Keystone OpenID URI, and
will therefore contain the name of the Keystone identity provider in the path.
So we can be a bit tricky and use this to look up the value for "iss". With
this in-place in Keystone, `mod_auth_openidc` can use OP discovery and the user
no longer sees that awkward extra page in the flow.

### Limited OIDC support for rich claims

One last wrinkle I encountered was that not all client libraries had good
support for rich OIDC claims; similar to Keystone, they assumed claims would
either be strings or a list of strings. The main offender here was JupyterHub's
[OAuthenticator](https://github.com/jupyterhub/oauthenticator), but I imagine
there are others.

To support such applications, I configured the Keycloak IdP to return a simpler
set of claims to the clients I knew to have issues, such as JupyterHub. Instead
of "projects", we now have "project_names":

<!-- prettier-ignore -->
{% highlight json %}
{
  "preferred_username": "jason@example.com",
  "project_names": ["P-123456", "P-234567"]
}
{% endhighlight %}

But wait, there's more...

This change had larger implications because of some capabilities our JupyterHub
system has. When we built out JupyterHub, we wanted Hub users to be able to
transparently interact with the remote OpenStack sites without having to do any
wrangling of OpenRC files or logging in again to each site. Fortunately with
federated authentication we can piggy-back on the user's initial login token:
the keystoneauth library supports an authentication method called
`v3oidcaccesstoken`, which allows passing an already-generated OIDC access token
straight to Keystone, rather than Keystone attempting to obtain this itself.

However, this means whatever claims the client received _when it performed the
login_ will be passed to Keystone (they are encoded in the token). Since
OAuthenticator could only accept simple claims, it would be sending those simple
claims back to Keystone, which would reject them, because the mapping was
expecting the rich "projects" claim!

Rather than try to fork yet another project and patch it up the root problem
here, I opted to give Keystone _two_ mappings: a preferred one, which uses the
rich claims, and a "dumb" one that it can fall back to. Keystone's mapping
engine will apply the first mapping that successfully passes, so we just put the
new simpler mapping after it. You can see the final mapping(s) below.

## The final picture

With the patches in place, we were able to get everything we needed to work
within Keystone's existing federation mapping engine. The final mapping we
configured looks something like this:

<!-- prettier-ignore -->
{% highlight json %}
[
  {
    "local": [
      {
        "user": {
          "name": "{0}",
          "email": "{1}"
        }
      },
      {
        "projects": [
          {
            "name": "{2[name]}",
            "extra": {
              "nickname": "{2[nickname]}"
            },
            "roles": [
              {
                "name": "member"
              }
            ]
          }
        ]
      }
    ],
    "remote": [
      {
        "type": "preferred_username"
      },
      {
        "type": "email"
      },
      {
        "type": "projects",
        "optional": true,
        "blacklist": {
          "name": [
            ".*-managers$"
          ]
        },
        "regex": true
      }
    ]
  },
  {
    "local": [
      {
        "user": {
          "name": "{0}",
          "email": "{1}"
        }
      },
      {
        "projects": [
          {
            "name": "{2}",
            "roles": [
              {
                "name": "member"
              }
            ]
          }
        ]
      }
    ],
    "remote": [
      {
        "type": "OIDC-preferred_username"
      },
      {
        "type": "OIDC-email"
      },
      {
        "type": "OIDC-project_names",
        "optional": true,
        "blacklist": [
          ".*-managers$"
        ],
        "regex": true
      }
    ]
  }
]
{% endhighlight %}

We now had a login system for all of our OpenStack deployments, and it was
generic: every Keystone system could be configured exactly the same (just
changing the Keycloak client ID and secret). This is particularly powerful
because we have open-sourced Chameleon's provisioning code so that other host
institutions or labs can deploy our specific infrastructure. Login with
federated identity is now included by default, so any deployer of Chameleon
doesn't need to worry about it.

When a user logs in to any site, their project memberships are synced
immediately. They will lose access to any projects they were removed from and
will gain access to projects they were added to since the last login. They can
still use CLI: the simplest thing we found was to override the default OpenRC
template in Horizon to properly configure it to use the `v3oidcpassword`
authentication type; the user sets a password in Keycloak and that serves as
their CLI password. Users can also opt to create Keystone application
credentials if that works better for them.

We encouraged all users to migrate over to the new system over a period of about
six months, which went pretty smoothly all things considered. To assist in the
migration, we wrote some self-service tooling that users could invoke to copy
information from their legacy Keystone user and projects (which were under the
"default" Keystone domain) to their "new" user and projects in the federated
domain.

## Full list of patches

If you're interested in applying any of these patches to your Keystone
deployment, here they are. I don't think the order in which you apply them
matters very much, as there are very few, if any, dependencies between each
changest.

#### Submitted

- [keystone/727891](https://review.opendev.org/c/openstack/keystone/+/727891) (not merged):
  create multiple projects if a claim has multiple values
- [keystone/741785](https://review.opendev.org/c/openstack/keystone/+/741785) (not merged):
  automatically prune user memberships from projects
- [keystone/730423](https://review.opendev.org/c/openstack/keystone/+/730423) (**merged**):
  regex support in whitelist/blacklist filters

#### Not yet submitted

- [add OpenID Discovery endpoint](https://github.com/ChameleonCloud/keystone/commit/990470db4)
- [parse claim payload as JSON](https://github.com/ChameleonCloud/keystone/commit/021f7f999)
- [support mapping extra project fields](https://github.com/ChameleonCloud/keystone/commit/413db3f07)
- [allow referencing nested fields in claim tokens](https://github.com/ChameleonCloud/keystone/commit/49cadcbca)
- [allow filtering based on nested fields in claim tokens](https://github.com/ChameleonCloud/keystone/commit/f6bd00d0d)
- [add "optional" flag to allow missing claims](https://github.com/ChameleonCloud/keystone/commit/278900739)
