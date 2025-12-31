# Optimizations of 2025-12

This document briefly explains optimizations done in December 2025
for the best practices badge project, to handle the changes on the web
as well as prepare for baseline criteria support.

## Background

When this application was originally developed, web
crawlers tended to be more gentle. Occasionally a crawler
would be unreasonably demanding, but it would only happen sporatically,
and most crawlers would respect robots.txt.
We implemented rate limiters to automatically limit the worst
offenders, primarily to automatically counter temporary DDoS attacks.
We assumed that crawlers would only show up occasionally, and
that they would go away once they were done.

However, that is not true any more.
Modern AI systems are built on machine learning (ML),
which in turn require lots of data, so many organizations are now
maximally and repeatedly downloading the internet to get training data:

* ["AI web crawlers are destroying websites in their never-ending hunger for any and all content: But the cure may ruin the web..." by Steven J. Vaughan-Nichols, Fri 29 Aug 2025, *The Register*](https://www.theregister.com/2025/08/29/ai_web_crawlers_are_destroying/), [discussed on Hacker News](https://news.ycombinator.com/item?id=45105230)
* ["The Internet Is Being Overrun by AI Bots — And Websites Are Paying the Price" by Sharon Fisher, October 31, 2025, VKTR](https://www.vktr.com/ai-technology/the-internet-is-being-overrun-by-ai-bots-and-websites-are-paying-the-price/)

As with many websites, this site gradually increases in the memory it uses
as requests are made.
The site was also written to be simple and easy-to-maintain, instead of
focusing on performance.
The only area we focused on was delivering badges at scale, which we
implement through a CDN.
Historically this approach wasn't a problem, but now it is.

The website is now being downloaded so often
that it occasionally automatically fails and restarts as it
exceeded its memory allocations.
The fail-over is a last-ditch effort to recover, and we want that to be
an exceedingly rare event.

The most popular pages, by far, are the `/(:locale/)projects/*` pages, as
almost all pages are in this hierarchy. The data for every project, in
every section, in every locale, is here. We also provide this data in HTML,
JSON, and markdown formats, as well as badges in SVG format.
Thus, for us, it's important to optimize these pages in particular,
because when a web scraper scrapes our site, most of the resources are here.

We also want to add more support for baseline criteria. However, adding
more baseline support without any *other* optimizations would
have increased the burden further, because we'd have more pages to serve.
So we really needed to solve this problem so we could support baseline.

## Underlying problem

The fundamental problem was that when this application was developed
efficiency was much less important than it is now. Originally,
on every request to the application:

* Many objects (particularly strings) were created,
  which later needed to be collected by the garbage collector.
* More computation was done than strictly necessary on each request.
  For example, sometimes objects were re-created on each request,
  which again had to be garbage collected,
  instead of creating them once on system startup and reusing them later.
  The Rails router often did a lot of extra work to determine how
  to route a request.

Some technical details are important here:

* Like many systems, we use an Object-Relational Mapping (ORM) library.
  The one we use is called ActiveRecord and is part of Rails.
  An ORM converts data from a relational database into an object that's
  easy to use in an OO language. In most languages (including Ruby, Python,
  and JavaScript), creating that ORM object will also create many
  more *other* objects to represent the
  various data fields that were loaded into it
  (e.g., it will create a string object for every string value loaded into
  the ORM object to represent some field's value).
  By default, ORMs usually copy all fields into
  an object, but if those fields aren't used, this can do a lot of unnecessary
  work and create a lot of useless objects.
* Every creation of a new empty string creates extra work, as it has to
  allocated and later garbage collected. In Ruby (and many other languages),
  it's far more efficient to use small integers or nil, because these
  don't trigger allocations that use up memory, and since they don't
  trigger allocations they also don't require garbage collection.

## Solutions

To handle this new world of massive number of requests, we did the following:

1. Optimize the Rails router. When this application receives
   a request, it must first be routed to where it can be processed.
   The router had become a complicated mess that did a lot of extra
   work and was getting hard to maintain. It was a lot of work to simplify it!
   It's now much simpler and does much less work to route the work to
   the correct method. This will also make later maintenance easier.
   See the [routes consolidation plan](routes-consolidation-plan.md).
   See also PR #2560 / commit 55fac098e109b34f0b158edad908691491840317,
   PR #2561 / commit 5efc979b9d0fd7af80c39f2f1f483e531933d469, and
   PR #2563 / commit 0c69b9934c7b64be1f0b7150bc34dd5822b13548
2. When loading project data, we *only* load the fields we intend to use.
   This greatly reduces the number of objects created when we create the
   corresponding ORM object for the project - we don't create objects for
   fields we *know* we won't use.
   See commit 90e62bfd124da1db0d8354d435eb3a093e194ab7.
3. Change the edit HTML pages to *only* show specific sections.
   In particular, our URLs now forbid the general case (if you try to edit
   without naming a section, it'll redirect to a default section).
   This makes our optimization to only load certain fields more effective.
4. Convert all `XYZ_status` internal values into
   integers 0..3 instead of strings like `Met`.
   This was called "status enum as small ints" approach.
   Small integers don't require separate allocation nor deallocation,
   and since they're stored in the database as a smallint (the smallest
   portable SQL value) they take less space in the database too.
   NULL is not allowed; 0 represents `?` (Unknown). A 3 represts `Met`.
   These are converted when they enter and leave the external application,
   so this change is invisible to clients.
   We want that; integers don't have any obvious meaning, while the strings
   have a clear meaning.
   Conceptually this change was easy, but it practice it had a lot of fiddly
   bits because criteria status information is *all* over the application.
   See the [enum optimization](enum-optimization.md) information, as well as
   enum plan PR #2564 / commit 77b3a0cf75f3b3abbdf6604dc8badde0a2c7efc7 and
   PR #2566 / commit 55d696cca63c8ef258b7f8e509f1cba2b39747a1.
5. Convert all `X_justification` values
   that are empty strings into the NULL database value (which is
   represented as `nil` in Ruby). These don't require separate allocations
   like empty strings do, and since there are many empty strings, this
   is a significant improvement. See the
   [empty justification string as null](empty-justification-string-as-null.md)
   document for more information.
6. In many places, pre-compute a constant *once*, then use it, instead
   of recomputing it each time. Sometimes the ORM prefers a string and will
   convert other constructs into strings, so we do that pre-conversion
   to a string ahead-of-time and store that as a constant, to avoid
   unnecessary repeated computations. Each of these changes typically only
   helps a tiny bit, but this work is cumulative. As we pre-compute more things,
   that means there's less growth in memory use, and the garbage collector
   has less work to do (because there are fewer objects for it to examine
   to determine if they're still in use). For examples, see commit
   4815499cfeec65463557c414b9ce5a74bf6e4085 or PR #2553 /
   commit 21af8d819205aa6dfc8f953c032a69335beede44 or
   commit e87826e9d51645be3f5c981cdebb33bdd7a2477f or
   commit bd43ca53e9987a3481ca56edaa5c56b8d6fcefcc.
7. Optimize common cases. E.g. we log when we do our first gc compacting,
   so most requests don't need to check it.
   Commit affb46cbe82af6b9ec7a033038da45f66a5b5f82
   makes it so that we can do a cheap check that doesn't involve
   thread safety for the common case, and then, if we're not sure,
   use more expensive thread-safe checks.
8. Don't call the markdown processor for trivial cases where it makes
   no difference. In many cases only trivial strings are provided, and this
   avoids unnecessary work to process them.
9. We changed the run-time configuration to do a garbage collection
   compaction every hour, instead of every two hours. This meant that there
   was less time for unused objects to accumulate in memory, leading to
   less maximum memory use. By *itself* we still had memory use exceeded,
   and we want to limit the number of collections, so we still needed to
   take other steps.

## Impact

These changes produced a massive cumulative improvement on the
best practices badge application.

We were hitting restarts a few times a day from massively exceeding
our memory limits ("memory quota vastly exceeded").
We think we won't be hitting them any more with our optimized system.
Because each request does less work, each request will complete more quickly.
We may even be able to increase the number of threads, which will
increase the number of simultaneous requests a single worker
processor can handle, improving overall performance even further.
