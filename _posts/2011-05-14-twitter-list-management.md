---
layout: post
title: "UI Corner: Twitter List Management"
---

When Twitter launched their new web interface (NewTwitter), I finally started using their web client pretty regularly. The new interface is sleek, and really streamlines the timeline in to a much better discovery tool. I can find conversation 'threads,' can browse media content in-stream, jump along tangental lines of connections via suggested users and related tweets, yada yada yada. In my opinion, it's much better.

However, one seemingly integral part of Twitter's new UI - Twitter Lists - has been swept up in to the corner a bit, and I'm not sure why. As I start to use Twitter more for news, inspiration, and a window to what's going on in the world, I find that keeping lists of clusters of content a very solid feature. I can have one list for design articles, one for news, one for development blogs... you get the idea. However, the simple act of creating and updating a list is something that will probably frustrate users. Let me first illustrate the problems, and then I'll propose what I think would be a simple-ish solution that wouldn't move the essential UI around much.

## The Scenario
OK. I'm a user, and I've decided I want to make a List just for my co-workers. I already have a list defined in my mind of all my co-workers, I kind of remember which ones have Twitter accounts and which ones don't, and I have no idea what their usernames are specifically. But I figure I'll handle that later. First, I just need to find out how to add a list.

To highlight where what seems like the List options are, I searched for the term "List," which found a few options:

![Twitter.com - finding 'List' options](http://slashhashbang.com/wp-content/uploads/2011/05/list_ui_finding1.jpg "Quick scanning: mentions of "List" in main navigation and sidebar")

That's great, and about what I would expect. Clicking the disclosure triangle in the main nav gives me a nice drop-down menu, with a few options.

![Adding new List through Lists submenu](http://slashhashbang.com/wp-content/uploads/2011/05/list_ui_adding1.jpg "List UI entry-points")

Keeping in mind that I'm just trying to "add a new list with co-workers," the option "Create new List" seems applicable. Great! I'll click it.

![Adding new List: Detail modal](http://slashhashbang.com/wp-content/uploads/2011/05/list_ui_adding_detail1.jpg "Modal dialog for new List, with basic content fields (no way to add users yet)")

Now, Twitter makes the (correct) assumption that I'm wanting to complete a special task regarding making this List, so it focuses my attention on a modal dialog. It's laid out nicely and the options are very clear to me. I can't really add people to the List right off the bat, but I'm assuming that will follow shortly -- this is just some prep-work...

![After adding new List, blank slate.](http://slashhashbang.com/wp-content/uploads/2011/05/list_ui_blankslate1.jpg "Empty List - no users added yet (only time search box is visible)")

After I click "Save," I arrive at what looks like my new List's "profile" or detail page. At this point, all I want to do is start on the "meat" of this task: adding my co-workers. I see there's a search box inside where statuses or user account listings would be. I'll start there, and add my first co-worker. I start typing in the name, and even wait a bit, expecting it to populate with some auto-suggestions based on who I'm currently following, but no dice! That's kind of a bummer; I was hoping to get everything done from here in one fell-swoop. Whatever, I'll search for the first guy (Gabe) anyways. I'll even use his proper (full) name to help the search out...

![Searching for users to add to List - not weighted based on currently following](http://slashhashbang.com/wp-content/uploads/2011/05/list_ui_searchfail1.jpg "First search attempt yields unexpected/irrelevant results")

Well, that's interesting. Not only was I taken somewhere else entirely (Who to Follow? Shouldn't it be "Search Results" or something?), but Gabe isn't even on there! There are quite a few Gabriel Hernandez's (what is the plural of that?) in the world... it could take ages to go through this list. The good thing is, I actually know Gabe's username, so I'll just enter that.

![Searching by specific username and built-in List UI](http://slashhashbang.com/wp-content/uploads/2011/05/list_ui_addedgabe1.jpg "User profile List UI hooks (can quickly add/remove users to/from existing List)")

This time, <abbr title="Who To Follow">WTF</abbr> comes through. I see Gabe's profile, and notice a button on the right of the "Follow" indicator, and it kind of looks like a list, or options, or something, so I'll check it out. It doesn't really scream "This is how you add me to a list" but it's close enough for me to investigate. And I get a nice drop-down again with what looks like a breakdown of my Lists. I see there is a checkbox next to the co-workers list I just made, so I'll check it. The checkbox is activated, so I'm assuming that Gabe was added to the list. I feel a little unsure just because there was no confirmation. But, it's easy to check: my co-workers List should have been updated. I'll go over and look at it again to see if that's the case.

![After adding first user, can&#039;t find &#039;Find&#039; form anymore](http://slashhashbang.com/wp-content/uploads/2011/05/list_ui_cantfindform1.jpg "After at least one user added to List, search box becomes absent")

Cool, well it looks like Gabe is there now! ...But where did the search form go? Granted, I didn't really like it, but it was kind of useful to have it in-place in the List view. I'm on my own to find the rest of the people I want to add.

However I find the target, I have to go through this for each and ever user that I want to add to the list. For the small company I work at, that's not too bad - only 6 or 7 of my co-workers have Twitter accounts that they like to update. If I were making a large list from scratch it would be a heavier undertaking. Overall, I'm left with the impression that this is just taking too long.

## What went wrong?
There were a few things that contributed to what I felt was, at times, a bit of a clunky and time-intensive experience for what I was hoping would be a breeze.

1.   **Search assistance was a missed opportunity.** Conventions like auto-complete and search-as-you-type are being used, to great effect in most high-traffic web services. Mobile apps are also pushing this trend forward (appropriately so; It's much harder to type on small keypads). I think that implementing a profile-lookup search that brings up user accounts as you type would single-handedly turn this around, and I present some ideas for that during the last part of this analysis.
2.   **Search pages were not relevant.** Search results were not weighted in any way that seemed useful. I expected Twitter users I was following to appear at the top of the list for easy access.
3.   **Adding additional users was not an obvious process.** After at least one user is added to the List, the List page displays a subset of the List's total tweets, instead of the search form. The result is that it's not obvious how to add a user to a List from the List UI.

## Solutions
### Introduce auto-complete to user search
The List view's search box has one primary purpose: to find other users that I want to add to my List. Moreover, if I already _know_ which users I'm going to add, it doesn't make sense to make me find each one of them through a search result page and then add from there. As I was typing Gabe's name, for example, I should have seen something like the following:

![Search results appear underneath the search box with standard profile mini-view UI. Users you follow (and perhaps users are following you) appear weighted at the top of the page. The List button has also been added with more contextual hints as to what it does, and clicking the button will just automatically add you to the current List.](http://slashhashbang.com/wp-content/uploads/2011/05/new_ui_autocomplete.jpg "Search results appear underneath the search box with standard profile mini-view UI. Users you follow (and perhaps users are following you) appear weighted at the top of the page. The List button has also been added with more contextual hints as to what it does, and clicking the button will just automatically add you to the current List.")

![An alternate approach: show the results inline underneath. On hover, the 'Add' button appears so users can quickly add users straight from the search box.](http://slashhashbang.com/wp-content/uploads/2011/05/new_ui_autocomplete2.jpg "An alternate approach: show the results inline underneath. On hover, the 'Add' button appears so users can quickly add users straight from the search box.")

### Improve search results with relevant content
Even if autocompleted search results are on, it's a good idea to have a fall-back search that functions similarly in case the autocomplete is broken, the user's internet connection is slow, etc. Just having users you follow (and maybe users who follow you) at the top would help. Users that you have dm'd in the past is also a candidate here (since you can DM people as long as they follow you, but this is a better metric of interaction that just the fact that a user follows you). By putting those results at the top for this type of search, in which I contend the intent is to search amongst your Twitter contacts, the process becomes more stream-lined.

### Keep the improved search at the top of the List view
To distance this new search that assumes an intent of wanting to surface 'close' Twitter contacts from the global search, it would help to keep this List-optimized search field in the List UI. This way the search field is tied contextually to the List, and it will be the go-to for this kind of operation. Currently a search box is only visible in the List UI if there are no users added to the List. I think the search feature is valuable enough to warrant placement whenever you're viewing the List UI page (after all, the edit/delete operations are there anyways... it's kind of already a content management view).

![Possible locations are: in between the List name tag and the tweets, or above the tab navigation, near the buttons that aid in managing the List.](http://slashhashbang.com/wp-content/uploads/2011/05/new_ui_searchloc.jpg "Possible locations are: in between the List name tag and the tweets, or above the tab navigation, near the buttons that aid in managing the List.")

### Why not do this all in one step?
There was a really good opportunity for a rewarding experience in this scenario: the modal dialog that served as the List content primer. Instead of just being able to name the List and provide a description, doesn't it make sense to also offer a way to pump the list full of people straight away? Generalizing the autocomplete idea, Twitter can have a way to quickly add users from within the modal dialog. Users can quickly add people to the List, remove them if they change their mind, and accomplish everything in one shot. This will also avoid the somewhat awkward 'blank' List view that you get when no users have been added yet.

![A new 'Start List Following' field communicates that the user can add user accounts to the List straight away. The field contains helpful placeholder text to acquaint new users with the functionality. Users already added are displayed below, and can be removed by clicking the 'X.'](http://slashhashbang.com/wp-content/uploads/2011/05/new_ui_modal_init.jpg "A new 'Start List Following' field communicates that the user can add user accounts to the List straight away. The field contains helpful placeholder text to acquaint new users with the functionality. Users already added are displayed below, and can be removed by clicking the 'X.'")

![Searching by username or full name yields results weighted as described previously. Selecting an item from the list adds it to the list of users displayed below the form and updates the count ("X users selected".)](http://slashhashbang.com/wp-content/uploads/2011/05/new_ui_modal_search.jpg "Searching by username or full name yields results weighted as described previously. Selecting an item from the list adds it to the list of users displayed below the form and updates the count ("X users selected".)")

## Closing Thoughts
As I've worked on this write-up, I've found a few different flows and hook-points for accomplishing this task. However, none of the flows address the particular case that I outline in the beginning of this post. Rather, Twitter makes an assumption that the primary user need for Lists is the ability to easily update / maintain them on a user-by-user basis. This is great when somebody you're following starts to become less interesting to you, and you want to take them off all Lists straight from wherever you're viewing the content. All you need to do is click through to the profile. This is also good when you find somebody new to follow. You can follow them _and_ add them to a List without having to go to some special corner of the system. I'm not convinced, however, that this use-case is the most common one.

I should also note that the task I'm addressing can be accomplished without too much hassle by going to your Following section and then adding whatever users you want to a new List. This breaks down somewhat if you're following a _lot_ of people because you have to wade through a lot of noise, and therefore I maintain this use case is hindered by the current offering. 

Fortunately, it's not a giant leap to improve this scenario, because Twitter has done a very excellent job with anticipating user needs and streamlining both content discovery _and_ curation (no small feat). This is just one corner of the UI that could use a spruce-up.

