---
title: "Scaling Javascript: Removing Module Inter-dependencies"
layout: post
---

Encapsulating functionality within independent modules is a must in any Javascript codebase. In an ideal world, all modules would be entirely self-contained, exposing ony a minimal amount of information to the outside world and containing no knowledge of how other modules operate. However, as all developers know, compromises often have to be made to satisfy product deadlines, details are missed, and architectures are never perfect. Since time is at a premium, developers must therefore rely on common solution patterns and learn to identify when to apply a known pattern to any given problem. Here, I propose one such pattern for the problem of inter-module dependencies.

## The Problem

Sometimes, especially when writing user interfaces, there are chunks of common functionality that make sense as one module, yet they may have synergy with other unrelated modules. A good example of this is a sidebar that contains controls.

Let's say that your app has many different features and these features are more or less isolated into disparate modules that are loaded on to the page. Each module has its own UI and perhaps its own sidebar component. It doesn't make much sense to put the sidebar components for all of these different modules under the umbrella of the sidebar module, as it directly couples the sidebar to every module that uses it. Yet, there still needs to be a way for these modules to let the sidebar know they have some custom UI it needs to display.

To illustrate this predicament a bit further, let's look at a simple example. I have three modules, `Sidebar`, `Painter`, and `Shape`. The `Painter` module, when loaded on my web application, enables the user to draw and erase on a virtual canvas. The `Shape` module lets the user draw a square or circle on the canvas. Each of these modules has a sidebar component: `Painter` has tool buttons that enable switching from the pencil to the eraser tool, and `Shape` has buttons for each shape tool it supports. We need a way to make some UI from `Painter` and `Shape` be operational from within `Sidebar`.

Let's get started with some basics. We know we need to be able to add sections of the sidebar at runtime, and we know sidebar-ready modules need to publish their sidebar components somehow.

{% highlight js %}
Sidebar.addSection(Painter.getSidebar());
Sidebar.addSection(Shape.getSidebar());
{% endhighlight %}

Not too bad - we can have `Sidebar` implement a general `addSection` method that can take in any arbitrary DOM element and attach it at the right place in the document for viewing. Similarly, we can have each module that wants to interface with the sidebar implement a `getSidebar` function that returns the DOM node to be attached.

The problem happens when you consider where this code is running. We would prefer this code was isolated to reduce coupling between the sidebar and the other modules. So let's try putting it in another place, maybe a supporting module called `DrawingSidebar`:

{% highlight js %}
DrawingSidebar.install = function() {
	Sidebar.addSection(Painter.getSidebar());
	Sidebar.addSection(Shape.getSidebar());
};
{% endhighlight %}

Now we at least have avoided the problem of the original modules depending on eachother... but we have this new module that depends on both of them! Furthermore, we have now grouped the `Painter` and `Shape` modules. Let's say a requirement comes in later that the `Shape` module is going to be offered as a tool only for a certain tier of users. Well, then we have a problem. We aren't going to have the `Shape` module loaded on the page for some users, so this code will break. We then would have to create one module for each grouping of some sidebar-enabled module and the sidebar so they can operate independently:

{% highlight js %}
PainterSidebar.install = function() {
	Sidebar.addSection(Painter.getSidebar());
};

ShapeSidebar.install = function() {
	Sidebar.addSection(Shape.getSidebar());
};
{% endhighlight %}

Now for each module that needs a sidebar, we effectively need to maintain _two_ modules. How annoying! Besides that, we still haven't really solved the problem of the sidebar dependency. If the `Sidebar` was removed from the page all of these supporting modules would break. And of course, as we're figuring this sidebar issue out, things continue to get more complicated elsewhere. The app has grown to be pretty large and there are now performance issues due to the large amount of code being served down to the client. To help speed up the perceived render time of the app, the client code will be split up and served in a series of parallel requests. It would be nice if our code didn't need to care about the order in which the modules loaded. However, clearly our `PainterSidebar` module needs to wait until both the `Sidebar` and `Painter` are loaded before it can run its `install`. A new approach is needed to solve this problem.

## Observable Factory Pattern

At a high level, the solution is just a combination of two well-known software design patterns: the Observer pattern and the Factory pattern. The requirements of the system go like this:

  - The factory must keep a record of all produced products
  - The factory must notify observers whenever a new product is produced

Let's make the factory. For the purposes of this exercise, let's assume we have a simple trigger/bind callback system on the factory to notify and register observers.

{% highlight js %}
var controls = [],
  callbacks = [];

SidebarControlFactory.makeSidebarControl = function(control) {
  controls.push(control);
  // notify callbacks about new control
  callbacks.forEach(function(callback) {
    callback(control);
  });
};

SidebarControlFactory.forAllControls = function(callback) {
  // immediately invoke for all existing controls
  controls.forEach(callback);
  // allow invocation for all future controls
  callbacks.push(callback);	
};
{% endhighlight %}

Pretty simple. But is it really that useful? What can we do with this? As it turns out, we can do quite a bit. Notice how our modules can utilize this factory as a sort of mediator object.

{% highlight js %}
Sidebar.install = function() {
  SidebarControlFactory.forAllControls(this.addSection);
};

Painter.install = function() {
  SidebarControlFactory.makeSidebarControl(this.getSidebar());
};

Shape.install = function() {
  SidebarControlFactory.makeSidebarControl(this.getSidebar());
};
{% endhighlight %}

Now each module depends on our new `SidebarControlFactory`, but that's where the knowledge of outside systems stop. We have eliminated module inter-dependencies between the sidebar and its related components. We also get a system that works _for any module load order_. How does that work? It's easiest to see in the sidebar code. When the sidebar boots up, it immediately registers any controls that have already been created (modules that have already loaded). Then, it sets up an asynchronous handler to respond whenever a new component is initialized (new module loads and wants to use the sidebar). The sidebar can boot up at any time and be OK.

## Going Further

There is nothing specific to a sidebar, really, in the SidebarControlFactory. If further generalized, this factory could make _anything_. The key benefit of this factory pattern is that it provides a mechanism for registering a callback that is guaranteed to run on all of the factory's past and future products. This approach can help solve many problems in any complex architecture and, as we've seen, is especially adept at solving the problem of generic UI containers.

### More Resources

[Scalable Javascript Application Architecture][1]: A great talk by Nicholas Zakas giving more examples of how to reduce module coupling in a large application

[1]: http://www.slideshare.net/nzakas/scalable-javascript-application-architecture "Scalable Javascript Application Architecture"

