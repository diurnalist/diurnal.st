---
layout: post
title: Lightweight Relation Modeling with Backbone
syntaxHighlighting: true
---

I've been using Backbone.js more and more in my day-to-day development for a myriad of reasons. It's a wonderful balance of a light footprint and a set of powerful, flexible tools. One of the most frustrating things for me is when a framework prevents me from doing something... I don't know that I've had a case of that with Backbone so far. However, because Backbone is so trim and so new, developers have to solve a lot of novel challenges before being able to fully leverage the framework.

## Problems with Complex (Relational) Models

Once you start working more with Backbone models as client-side mirrors of your persistence layer (if only structurally), you run in to the problem of what to do with relationships between model types.

Take, for example, this JSON object representing an album.

{% highlight js %}
var album_json = {
  name: "My Album",
  releaseYear: "2010",
  trackList: [
    {
      name: "My First Track",
      order: 0,
      duration: 3600,
      streamUrl: "http://example.com/stream.mp3"
    }
  ]
};
{% endhighlight %}

The album has some metadata (name, releaseYear), but also a list of tracks. The tracks themselves look like models. The trackList looks like a collection.

How would we model this with Backbone? Well, we'd probably start with something obvious, like this:

{% highlight js %}
var Track = Backbone.Model.extend(),
  TrackList = Backbone.Collection.extend({
    model: Track
  }),
  Album = Backbone.Model.extend();
{% endhighlight %}

Then things get a little tricky. So the Album looks like it needs to have some internal attributes for `name` and `releaseYear`, but then it needs a reference to a TrackList for the `trackList` property. How do we set that up? More importantly, how do we ensure that any future operations on the model (syncing from the backend, manually setting properties on the model, etc) get delegated correctly to the TrackList, instead of overriding it with dumb JSON values? If you don't see what I mean, think about what happens here:

{% highlight js %}
var model = new Album(album_json);
model.set({
  trackList: [{
    name: "A different track",
    order: 0,
    duration: 1800,
    streamUrl: "http://example.com/stream2.mp3"
  }]
});
{% endhighlight %}

Not only is it messy, but unless we're doing some magic, our nice TrackList is going to get completely wiped out by this call, and we're left with this plain ol' JSON array.

## Existing solutions

I've been aware of [Backbone-relational][1] for some time now, and in doing some research for this post I came across another called [Ligament][2]. Both of these implementations claim to support pretty much any relational whim you would have. Ligament seems way less mature than Backbone-relational; I'm contemplating leaving it off this list because it really only supports reads, and relies on everything being set up in a precise manner before any operations can start happening.

Backbone-relational is very powerful, but also very esoteric and has a few design decisions that I disagree with.

### Bi-directional support

Both implementations work to bring full bi-directional support to models, so that if I loaded, say, a track from the server, and it had a reference to its parent through some special id key:

{% highlight js %}
{
  "album_id": "1",
  "name": "My Track",
  "duration": 3600,
  "streamUrl": "http://example.com/stream.mp3"
}
{% endhighlight %}

The library is 'smart' enough to figure out how to fetch that album just off of the album_id. Which brings me to my next point.

### Too much magic

You only have to look at the GitHub [issues page][3] for Backbone-relational to understand the problem with this. Seems like the only person who really knows how this thing is working is the original developer. The problem is that you really have to understand Backbone's own internal control flow (when events are fired, what happens in the constructor, etc) and _then_ figure out how Backbone-relational is augmenting that with its own magic. The end result is you have weird cases where models are automagically fetched, and their events are being suppressed by stuffing everything into a blocking event queue where locks are acquired at the beginning of every major model operation, because otherwise your handlers would execute with the wrong data or your collection would scream because it was trying to add two of the same model (which makes Backbone throw a nasty error).

### All or nothing.

Wouldn't be so bad if the implementation wasn't so cryptic, but in order to use these libraries you have to make everything inherit from these new model prototypes. The idea of having to wade through this extra layer of code on debugging is not enticing.

## K.I.S.S.

Here's an alternate implementation for this relational problem that reduces the code you need to write, while keeping it dirt-simple to understand what's going on.

{% highlight js %}
function delegateModelEvents(from, to, eventKey) {
	from.bind('all', function(eventName) {
		var args = _.toArray(arguments);
		if (eventKey) {
			args[0] = eventKey + ':' + args[0];
		}
		to.trigger.apply(to, args);
	});
}

function getUpdateOp(model) {
	return (model instanceof Backbone.Collection) ? 'reset' : 'set';
}

Backbone.RelationalModel = Backbone.Model.extend({
	relations: {},
	set: function(attrs, options) {
		_.each(this.relations, function(constructor, key) {
			var relation = this[key];

			// set up relational model if it's not there yet
			if ( !relation) {
				relation = this[key] = new constructor();

				// makes it so relation events are triggered out
				// e.g. 'add' on a relation called 'collection' would
				// trigger event 'collection:add' on this model
				delegateModelEvents(relation, this, key);
			}

			// check to see if incoming set will affect relation
			if (attrs[key]) {
				// perform update on relation model
				relation[ getUpdateOp(relation) ](attrs[key], options);

				// remove from attr hash, prevents duplication of data + 
				// keeps models out of attributes, which should be only used for
				// dumb JSON attributes
				delete attrs[key];
			}
		}, this);

		return Backbone.Model.prototype.set.call(this, attrs, options);
	}
});
{% endhighlight %}

The reason this works is because `set` is used internally by Backbone for any operation that updates a model. That means the constructor, where the attributes are set up initially, any Backbone.sync responses that originate from a fetch/save call, and of course just calling `set` directly. So we have overridden one method to just be a little smarter, and immediately there are huge gains for this problem. Going back to my previous example, my models would now be this:

{% highlight js %}
var Track = Backbone.Model.extend(),
	TrackList = Backbone.Collection.extend({
		model: Track
	}),
	Album = Backbone.RelationalModel.extend({
		relations: {
			trackList: TrackList
		}
	});
{% endhighlight %}

I also added a quick event delegation routine so that, if you wanted to, you could bind on any relation's events from the top-level model. In my case, I could listen for when //any track in an album// changed its name:

{% highlight js %}
album.bind('trackList:change:name', function(track) { ... });
{% endhighlight %}

My little function is just a quick exercise. The best part about working in Backbone is that you can drastically augment its behaviors just by mixing in a little extra special sauce. It would be trivial to build a more complex event propagation system where all the callbacks for relational events had a reference to the top-level model passed in as one of the arguments, for example.

## Caveats
Yes, this solution only works for top-down HasOne/HasMany relations.

I deliberately ignored the problem of bi-directional support, because I don't see it as a worthwhile problem to solve within the bounds of a one-size-fits-all solution. The level of magic incurred is just too high, and leads to too much instability and confusion for something that should be an edge case. However, I recognize that the problem is still there for some uses - it just so happens that I haven't had any need for it in any of the work I've had to do with APIs. I will probably devote some more time to this problem to come up with a middle-ground solution. It won't be as 'powerful' as Backbone-relational... but that's the point.

[1]: https://github.com/PaulUithol/Backbone-relational "Backbone-relational"
[2]: https://github.com/dbrady/ligament.js "Ligament.js"
[3]: https://github.com/PaulUithol/Backbone-relational/issues?sort=created&direction=desc&state=open "Backbone-relational Github Issues"