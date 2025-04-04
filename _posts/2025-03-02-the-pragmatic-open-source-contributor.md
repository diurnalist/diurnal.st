---
title: "The Pragmatic Open Source Contributor"
layout: post
toc: true
---

I sometimes have the feeling that salaried programmers shy away from fixing or extending open source code due to some combination of the following:
* They don’t think it’s part of their job.
* Their *employer* doesn’t think it’s part of their job, and/or does not have the necessary legal infrastructure and will.
* They’ve been frustrated in the past with rejected or ignored patch requests.
* They are worried about the time committment for the entire process.

These are understandable barriers that I would like to break down. More broadly speaking, I have two aims for this guide.

First, **I hope to encourage fostering the shared knowledge that open source software represents.** Especially if you work in larger-scale environments or are early adopters of promising new technologies, you have a great opportunity to spot issues and areas of improvement that can benefit everyone.

Second, **I aim to provide a playbook for how to successfully do this kind of work** and set expectations for what you can expect and what will be expected of you. [I have made contributions to many projects over the years](https://github.com/pulls?page=1&q=is%3Apr+author%3Adiurnalist+archived%3Afalse+is%3Aclosed+is%3Apublic+-org%3Achameleoncloud+-org%3Adiurnalist+-org%3Akpireporter), generally following a pattern of identifying some code that solves 95% of my problem and contributing the 5% delta back. I’ve also worked more extensively in a single open source community, [OpenStack](https://review.opendev.org/q/status:close+owner:jasonanderson@uchicago.edu), where public contributions and distributed coordination are the status quo.

## The Pragmatic Contributor
[The community guide to open source](https://opensource.guide/how-to-contribute/#why-contribute-to-open-source) succinctly summarizes the benefits of contributing back to open source projects. Still, I find that these guides frame the process as motivated by **individual incentives**, e.g., personal development or a sense of fulfillment. For the pragmatic contributor, one motivation trumps all: the drive to **improve software the business relies on**. You want to fix a tool that isn’t enabling you to do the best job you can.

This mindset influences all aspects of the contribution process. If you're mostly interested in learning something new or making connections, you can pick and choose what projects you want to contribute to, and what problems you'd like to pick off the bug tracker. A pragmatic contributor never tries to find problems; **they find you.** Maybe it’s a newer project and hasn’t fleshed out all the little details, e.g., support for multiple authentication methods. Or, perhaps you simply found what seems like a bug in the behavior, or an inefficiency when used with high throughput.

A pragmatic contributor also **pressure-tests the solution**. It's likely you ran in to some problem nobody else has seen. Do you *really* need to implement a fix in the open source layer, or is it fair to say your application is just behaving weirdly? What is the wider benefit, really, of contributing this feature back to the community? Software naturally wants to expand in surface area and complexity over time. Some maintainers rule with an iron fist to keep the scope of their code low and steady, others are more willing to give you the benefit of the doubt that expanding scope is going to make things better. Over time I’ve come to appreciate the wisdom of the first approach, though it introduces challenges for you as an outsider. In either case, I have found that a respect for the maintainer’s view (it *is* their code you’ve been happily using, after all) and a willingness to find the most elegant solution goes a long way.

## The Pragmatic Patch Playbook
Once you've identified a potential contribution, here are some general steps I like to follow.

### Step 0: Talk to legal
**Before you do anything else, get approval from your legal department.** Even if you’re contributing to a project that does not have a Contributor License Agreement (CLA), you have a duty to ensure you are not adding risk to your company or yourself. Ideally, this conversation results in approval to sign any reviewed CLAs; Company CLAs (CCLA), if supported by the project, can enable self-servicing of licenses to new members of your team, and are much more future-proof than individual CLAs tied to one employee.

This can be a bit of an uphill battle, but in my experience it is mostly a battle of time. You might need some patience to walk all the stakeholders through the business case for contributing back to open source, and any possible risks. I usually lean on the following argument:
* We currently use open source system X, and it provides business value through capabilities and cost-efficiency, i.e., it’s usually free—[“as in beer.”](https://www.gnu.org/philosophy/free-sw.html)
* Yet, it can’t handle some new business use-case without modification.
* Modification effort is small relative to working around the constraint.
* We do not need to and will not expose proprietary code.
* Privately adapting the code (forking) introduces long-term maintenance burden and adds risk. It’s likely X will be changed in the future in a way that requires significant rework of our adaptations and thus blocks us from performing security upgrades.
* Publicly adapting the code reduces this risk and (especially if X is well-known in the industry) can even serve to attract new talent by increasing the company’s visibility.
* Contributing to X is thus in the business's best interest.

I have never seen this argument fail given enough motivation, but I’m sure there are exceptions. One thing to remember is you’re not arguing for **actually** doing the work or estimating the time commitment or return on investment; you’re making a case for the **option**. You should however be prepared to give concrete examples of the type of contributions you might make.

### Step 1: Get the lay of the land
I see developers often skip this step and go straight to submitting a patch. This can lead to frustration for both you and the maintainers. Doing a quick check of any defined contribution process and putting yourself in the maintainers’ shoes often prevents these issues.

**What is the contribution process?** Do you need to sign a CLA first? Are pull requests welcome on the repo? Can you find examples of contributions from the outside? How did the maintainers respond to the contribution request? Anything you can learn from this?
* See also [How to Contribute to Open Source: Orienting Yourself to a New Project](https://opensource.guide/how-to-contribute/#orienting-yourself-to-a-new-project)

**How active are the maintainers?** Are they reviewing patches on a daily basis, or does it seem more sporadic? Can you notice any patterns in how and when they respond to queries? Is there a shared maintainer model or is there a single owner? If shared, who seems to be the most active recently?

**How long will this realistically take?** What is the latency between the time a pull request is open and it is merged? How much of that is waiting for the patch author versus feedback from maintainers? How many patches do you think you’ll need to do, and do they need to be done serially? From this, you can usually get a ballpark estimate, but I also have a heuristic: expect two weeks to one month for a bugfix to land, and three months to a year for major feature work. Much of that depends on how much of *your* attention you give to tending to the process.

### Step 2: Get maintainer buy-in
For small changes, you can usually skip this step, but if you’re thinking of making any significant changes to the codebase, investing time here will make the entire process much smoother. Your objective is to identify at least one maintainer who will help champion your change.

**Meet the maintainers where they are.** Do they have a Slack channel they use to coordinate changes and share info? A bi-weekly special interest group (SIG) meeting? A mailing list? Figure out what their preferred communication method is and then introduce yourself. Give a bit of background on who you are and why you’re interested in contributing to the project, and what problem you’re trying to solve.

**Follow the formal proposal process.** If the project uses a proposal system (e.g., the Kubernetes Enhancement Proposal [KEP]), learn about how to submit a proposal. You can either talk to maintainers before making a proposal, or notify them after you have submitted the proposal. I still think a “warm handoff” is important here, to actually reach out in person to the maintainers to let them know that you’re open to discussion and are serious about embarking on the process of making a significant contribution.

**Agree on scope and keep a paper trail.** If in your conversations with the maintainers you arrive at agreement on what the scope of your contribution will be, and, importantly, what can be considered out of scope, make sure that you write that down somewhere publicly. This can be helpful to give context to other maintainers who might be reviewing the work down the line. Generally, this information should also be in a proposal document, if that process exists, but it’s still useful to have other records.

For this reason, I also like to have conversations about proposals in, e.g., public Slack channels as opposed to private messages. You can hash out details in private, but then post a summary of the conversation in Slack to preserve a record.

### Step 3: Do the work
You may have noticed that we haven’t written any code yet. Guess what? This is the only step where we’re going to talk about code! The lion’s share of open source work is communication. That said, there are some general rules that in my experience improve the outcome of patch requests.

**Don’t be afraid to fork.** Some people recoil at the word “fork.” Personally, when I’m working on open source contributions, I always fork the project, make the patches there, and use the fork internally for a while. You’re making a trade-off between speed of delivery (leveraging your patch immediately) and maintenance burden (carrying your fork through upgrades); in my workplaces the former usually trumps the latter, depending on how often you expect to pull in upstream changes. **Forking internally also lets you battle-test your changes** in a real environment before you submit the patches upstream. I often find bugs this way, or can correct mistaken assumptions about how something works in practice.

**Work backwards from your specific desired outcome to a generic mechanism** that helps achieve that outcome (and perhaps others.) For example, in [this old webpack patch](https://github.com/webpack/webpack/pull/427), what I wanted was a way to put a Git commit SHA in the name of files built by `webpack`. Rather than code this case explicitly, I proposed a way to enable plugins to provide support for new filename pattern placeholders. This enabled me to handle my needs in a separate plugin, and [appears to have been useful to others](https://github.com/search?q=hooks.assetPath&type=code) over the years.

**Add tests!** If you’ve found a bug in some code, it probably means there wasn’t a good-enough test for that behavior. Add a test that fails without your patch and succeeds with your patch. If you’re adding new functionality, make sure you have good coverage. The maintainers will ultimately be on the hook for bugs in *your code*, and your job is to reduce that burden as much as you can. It sometimes happens that there is not appropriate test infrastructure to express the tests you need. In that case, reach out to the maintainers to ask their opinion on how to proceed; often, they will be okay with less test coverage as they are working on figuring out a generic solution for testing that aspect of the code.

**Keep every patch to one atomic change.** The definition of “change” here is open to interpretation. If you are working extensively in an open source project and have a large feature you’re implementing that touches many areas of the code, you should probably break up each piece of the implementation into a single patch that targets a subset of the codebase. This works best if the broader context of your work is known and formally tracked; not all projects have this infrastructure. I like to keep my patches scoped to minimize context overhead for the reviewer. For example, when working on a larger feature, I first identified one (rather large) refactor I could do that would make implementing the feature easier. I submitted [one patch](https://github.com/grafana/grafana-operator/pull/1845)
for that change, and then [one patch](https://github.com/grafana/grafana-operator/pull/1858) for the minimal feature implementation. 

**If your atomic change is still large, break it into iterative commits.** In the latter example patch, I broke it into several commits to make it easier to review and see the thought process. I could have broken those commits into separate pull requests, but it seemed to me to reduce cognitive overhead (for the reviewers) when everything was in a single pull request that could be referred to and iterated upon. You can always break it into separate requests later if you have the commits structured this way.

**Keep refactoring to a minimum.** You may be tempted to “clean up” other areas of the code not specifically related to your code. It may be difficult, but you should try not to give in to these impulses. Any unnecessary refactoring, especially when it concerns readability or styling of code, adds to the work the reviewer must do and disrupts the message of what you’re actually trying to achieve with your patch. Reduce refactoring to only what is necessary to make your change possible. Later, you can come back and do the refactor if you want. Patch requests are also a good opportunity to ask the maintainers how they would feel about such a refactor in the future, enabling you to get some early buy-in.

**Preserve backwards-compatibility.** Open source projects are widely consumed and you cannot know all of the ways in which it’s being used today. You have probably been burned at some point by a library changing default behavior or its API surface without a major version bump. Major versions are big steps for an open source codebase and if you are tying your change to a breaking-change release, it will increase the latency of your change being available drastically. As such, work to ensure that whatever you do does not break existing behavior.
### Step 4: Do the other work
This is probably the part of the process that developers like the least, but you should plan to spend some time here to have a high-quality contribution.

**Write good documentation.** You should write docs for any new capabilities you are adding to the project. Sometimes you need to add an entirely new section of documentation! I don’t think I need to argue for the benefits of documentation, and how frustrating it can be when documentation is sorely lacking. If this is a task that is particularly difficult for you, I’m guessing that LLMs are probably pretty good at writing docs these days, and could be a good tool for summarizing how a feature works in a more consumable format. I haven’t tried this myself yet and still write all documentation by hand.
* See also [these useful resources](https://www.writethedocs.org/topics/#helping-engineers-to-write) from WriteTheDocs.

**Examples are also documentation.** Usually, technical documentation for open source code is of the “technical reference” variety. However, [that is only one type of documentation](https://www.writethedocs.org/videos/eu/2017/the-four-kinds-of-documentation-and-why-you-need-to-understand-what-they-are-daniele-procida/). Examples add more of a “how to” flavor, and sometimes showing really is better than telling. If you’re adding another feature to the code, you should provide some examples of how to use it.

### Step 5: Finish line
Once you have all the code and non-code pieces assembled, and have checked all the other required boxes in the process, you’re ready to submit your patch! This can feel a bit like “hurry up and wait,” especially if you’re been working on a patch to deliver something else as part of your job. In my experience, patience is important here. Just because it’s a good time for you to iterate on the patch (because you’ve built up all the context) doesn’t mean it’s the same story for the maintainers. Here are some tips for how to navigate this time.

**Proactively reach out to the maintainers.** Use those channels and connections you established in Step 2 if it’s a bigger change. Maintainers may want to discuss your change formally as part of their own processes, and giving them a heads-up that your patch is ready for review can help them figure out how to prioritize it. For smaller changes, I don’t usually do this, as I think it’s a bit annoying to just ping maintainers for something they essentially were already notified about via the patch request itself.

**Politely check in periodically to raise visibility.** If I’m having trouble getting any eyeballs on a patch request, I usually wait a week or two and then nicely ping some maintainers and request they please have a look-see at the patch, or if there is anything else that I should do. If that doesn’t work the first time, I’ll do it again in another week or so. If a month or so goes by, I will start to get more creative and see if I can reach them on another appropriate public social channel. Always be polite, and definitely *never* be pushy; even though you think you’re helping the project, you’re also taking the time and attention of maintainers.

**As soon as you get attention from the maintainers on your patch, leap into action.** Especially for larger requests, if you get a first-pass review of your code, try to respond to feedback within a day or so. This keeps the patch conversation pretty fresh for everybody. The maintainer just spent time building up context on your work by reviewing your code and it’s my experience that they appreciate quick follow-through on comments. This can be difficult to balance depending on your own job commitments. I try to set expectations that when a patch is in the final stages, I should have some work time set aside as a buffer.

### Step 6: Tie it off
If you made it here, your patch was accepted upstream! There’s always a great feeling (of relief?) when you see that merge complete successfully. This doesn’t always happen—I have some pull requests that have been [sitting for years](https://github.com/mozilla/mozilla-django-oidc/pull/377) collecting a trickle of sad “+1” comments. As a pragmatic contributor, this isn’t such a big deal, as it usually indicates the code has a low rate of evolution and therefore it’s not too much work to maintain your own fork.

Anyways, there are a few final things I usually do once crossing the finish line.

**Thank the maintainers who reviewed your code.** Being a maintainer is often a thankless task, so I find a sincere thank-you goes a long way. I often learn a lot from code reviews with open source maintainers, and view that as a gift. You can just leave a thank-you on your patch conversation, or reach out directly, whichever seems more appropriate given your past communication with them.

**Reduce your bus factor.** Did you start work on a longer set of related features? If so, make sure you clearly document what the next steps are for the work somewhere. Lots of things could happen. You could get involved in other work commitments that take up all your attention, you could be laid off, your company could stop using the software you patched altogether. Still, somebody might want to come along later to finish what you started. It should be possible to do that without your involvement.

**Bring your patches back internally.** If you’ve been working on a private fork of the code, work to bring your changes back in to your fork. Maybe you’ve even made it possible to stop using your fork entirely!

## Conclusion
Let’s revisit some of the reasons I suggested prevent folks from contributing to open source:

**They don’t think it’s part of their job.** Hopefully I’ve made a brief but decent case for *why* this is important, both for the wider community, and for your own growth. Familiarity and confidence in this process empowers you to blast through technical barriers, as you might no longer be “blocked” from achieving your goals due to some underlying third-party code not supporting XYZ.

**Their *employer* think it’s part of their job, and/or does not have the necessary legal infrastructure and will.** Step 0 describes ways you can try to make the case for contributions. Ultimately this may still be a barrier in practice, but I think it’s worth poking at assumptions here. Sometimes you can be surprised by how open-minded your employer is about work like this.

**They’ve been frustrated in the past with rejected or ignored patch requests.** Steps 1 and 2 should put you in a better position to set your own expectations and improve the timelines by having better relationships with folks you’re dependent on.

**They are worried about the time committment for the entire process.** This is the wisest objection to the whole endeavor, in my opinion. It’s hopefully clear that writing the code is a very small part of this entire process. Still, I do find that this gets easier the more experience you have doing it, because you know more about how to keep the ball rolling, and if you’re working within the same ecosystem, over time you should gain more trust from the maintainers, which helps greatly with future contributions.

> Write the change you want to see in the world!
