# Design

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

This document describes the design of the BadgeApp.
No single tehnology does everything well.
Instead, design is all about making good choices between
options that have different trade-offs to meet requirements.
This document describes our key choices.

## High-level architecture

The web application is itself OSS, and we intend for the
web application to meet its own criteria.
We have implemented it with Ruby on Rails; Rails is good for
simple web applications like this one.
The system stores the data in PostgreSQL (aka Postgres).

### High-level design figure

The following figure shows a high-level design of the implementation:

![Design](./design.png)

### Traditional web app, not a single-page app (SPA)

There are at least two ways to develop a web application:

* a "traditional web application" where most user interactions (such
  as form submission) involve loading an entirely new web page.
* a [single-page application (SPA)](https://en.wikipedia.org/wiki/Single-page_application)
  interacts with the user by dynamically rewriting the current page
  (instead of loading new pages from a server).
  SPAs typically provide a more fluid user experience, but also
  incur a higher development and maintenance cost.

We intentionally developed this application as a traditional web application,
not as an SPA, because development and maintenance cost was very important
when the project started.
Indeed, the article
[SPAs Are Just Harder, and Always Will Be](http://wgross.net/essays/spas-are-harder)
argues that SPAs will *always* be harder to develop, even with
frameworks to help.
In addition, some security-conscious people disable JavaScript, and
one of our requirements is that the application work in those cases
(with some graceful degradation).

When the project started, our primary concerns were to determine the
criteria, and try to get broad buy-in that those criteria were sensible.

This approach can easily be revisited in the future, if it is decided
that the costs are worthwhile.

### Key components

The key components we use are:

- Ruby on Rails.
  This is our the primary programming language and web application framework.
  Ruby on Rails is specifically designed to be easy to use and thus
  is a good choice for simple web applications like this one.
  Its ease-of-use enables us to avoid needing a large amount
  of effort to develop or maintain the software.
  Ruby is not a fast language, but standard Rails performance techniques
  (such as fragment caching) make it fast enough.
  Ruby doesn't have static typing, so it cannot detect errors a
  statically-typed language can automatically detect; we use static tools
  and strong test coverage to detect errors instead.
  We also have some custom software written in client-side JavaScript.
- PostgreSQL (aka Postgres).
  This is a widely-used relational database system (RDBMS).
  Our experience (and those of others) is that it is extremely
  reliable, a key requirement for a DBMS.
  It also doesn't require a lot of maintenance and tuning to be useful.
- Bootstrap.  This is an extremely popular front-end component library.
  One major advantage of using Bootstrap is that our site looks like many
  other websites; as a result, our website is familiar and easy to use.
  We want users to focus on getting their tasks done, instead
  of trying to figure out how to use the site.
- jQuery (jquery-rails).
  This is a widely-used small JavaScript library to ease certain tasks
  such as HTML document traversal in a portable way.
- jQuery UI (jquery-ui-rails).
  jQuery UI is a curated set of user interface interactions, effects,
  widgets, and themes built on top of the jQuery JavaScript Library.
  We use jQuery UI solely to use "jquery-ui/autocomplete"
  as a polyfill for Safari.
  [Most browsers support datalist](https://caniuse.com/#feat=datalist),
  when entering data in a field, but Safari fails to support it.
  We use a datalist in the projects form to help fill in the
  implementation language and license.
- Imagesloaded.
  This is from <https://github.com/desandro/imagesloaded> - it's a JavaScript
  library to ensure images are loaded before displaying them.
- Puma.
  This is our webserver.
  We don't use webrick, because Puma can handle multiple
  processes and multiple threads.  See:
  <https://devcenter.heroku.com/articles/ruby-default-web-server>

We use a number of supporting Ruby gems.
See the file "Gemfile" to see all the gem direct dependencies;
see the file "Gemfile.lock" to see all the gem dependencies (direct and not).

### Key classes

The software is designed as a traditional model/view/controller (MVC)
architecture.  As is standard for Rails, under directory "app"
(application) are directories for "models", "views", and "controllers".

Central custom classes include:

* "Project" (defined in file "app/models/project.rb")
  defines the model that captures data about a project.
* "User" (defined in file "app/models/user.rb")
  defines the model that captures data about a user.
* "AdditionalRight" (defined in file "app/models/additional_right.rb")
  defines the model that captures the set of additional rights of users.

## Performance

The BadgeApp doesn't need to be the fastest in the world,
just fast enough for users to be happy.

### How we get good performance

Here is our approach to getting good performance:

* Badge images are cached and served primarily by our CDN, not our server.
* The Rails application uses fragment caching (including "Russian dolls")
  to cache previous requests.  This is key to making any Rails application
  work quickly.
* Static assets are precomputed by the usual Rails asset pipeline
  into /assets and served directly
  by the web server (not the underlying slower Rails application).
* Static assets are aggressively compressed.
* Images are resized to their display size, and we provide width and height.
* The web application HTML includes preloading commands to help
  web browsers request what they need relatively early.
* The RDBMS has indexes for all built-in searches
  (as is standard good practice).
* We use the "bullet" gem to detect N+1 queries (a common yet subtle
  performance killer in web applications)
* We use various tools, such as [webpagetest](https://www.webpagetest.org/),
  to detect performance problems.

### Not used: Turbolinks

At the moment we do not use
[turbolinks](https://github.com/turbolinks/turbolinks).
Turbolinks is a performance enhancer designed to make
"navigating your web application faster".
Turbolinks often used in Rails applications, because it's intended to provide
"the performance benefits of a single-page application without the added
complexity of a client-side JavaScript framework."

However, you need to modify your application to work properly with turbolinks.
[Turbolinks breaks $(document).ready](http://guides.rubyonrails.org/working_with_javascript_in_rails.html#page-change-events)
(an extremely common construct)
and by default requires you to use a nonstandard on..."page:change"
construct.
We used to use turbolinks, along with a gem called jquery-turbolinks
that tried to work around the need for modifying software for turbolinks.
In practice this setup was unreliable, especially with /project_stats.

To use turbolinks properly we've determined that
you really need to read its documentation
carefully, and then modify your JavaScript to work with it.

We might restore turbolinks in the future,
but we would need to do it properly (and probably add a marking
for /project_stats to disable turbolinks on that page).
The current web application is so
fast that we don't really need turbolinks.

## Handling concurrency

The application is multi-user and multi-threaded.

### Multi-user

We use optimistic locking to prevent unexpected data loss from
multiple people editing the same project at the same time.

We use RDBMS transactions,
[invoked via ActiveRecord](http://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html),
to counter problems that could happen without transactions.

### Multi-threaded

This is a multi-threaded application once it starts accepting web requests.
Different requests may be started in different threads.
Ruby supports multiple threads, but its default collection
data structures are *not* thread-safe
(this is true for many programming languages).
The usual C implementation of Ruby does have a GIL, but that does
not make code automatically thread-safe.

Rails handles multi-threading by using
a "shared-nothing architecture", that is, different threads
get different starting instances, which create their instances
of everything else.
For more information, see,
["How Do I Know Whether My Rails App Is Thread-safe or Not?" by Jakko](https://bearmetal.eu/theden/how-do-i-know-whether-my-rails-app-is-thread-safe-or-not/).

For the most part this is invisible, but be extremely careful if you
create situations where a possibly-modifiable
resource is *shared* between threads.
For example, don't memoize unless you do thread-safe memoization.
An alternative is to pre-create all the instances you need during
system initialization and then freeze them (sharing read-only data is fine).

This is one reason we enable frozen string literals.
Since frozen string literals cannot be mutated, a thread cannot
accidentally mutate one and affect a different thread.

The main mutable construct shared in Rails during execution is the
Rails ActiveSupport::Cache that we rely on for server-side caching.
We use MemoryStore as the cache back-end, and
[Rails ActiveSupport::Cache MemoryStore has been memory-safe since Rails 3.1](http://api.rubyonrails.org/v3.1.0/files/activesupport/CHANGELOG.html)
as implemented by this
[commit](https://github.com/rails/rails/commit/ee51b51b60f9e6cce9babed2c8a65a14d87790c8).
This is explained as follows:
"Make thread safe so that the default cache implementation used by Rails
is thread safe."

## Deployment

We have three publicly accessible tiers:

* master - an instance of the master branch
* staging
* production

These are currently executed on Heroku.
If you have write authorization to the GitHub repository,
the commands "rake deploy_staging" and "rake deploy_production"
will update the staging and production branches (respectively).
Those updates will trigger tests by CircleCI (via webhooks).
If those tests pass, that updated branch is then deployed to
its respective tier.

Most administrative actions require logging into the relevant Heroku tier
using the "heroku" command (this requires authorization).
The one exception: the BadgeApp web application does support an 'admin'
role for logged in users; admin users
are allowed to edit and delete any project entry.

## Terminology

This section describes key application-specific terminology.

The web application tracks data about many FLOSS *projects*,
as identified and entered by *users*.

We hope that projects will (eventually) *achieve* a *badge*.
A project must *satisfy* (or "pass") all *criteria*
(singular: criterion) *enough* to achieve a badge.

The *status* of each criterion, for a given project, can be one of:
'Met', 'Unmet', 'N/A' (not applicable, a status that only some
criteria can have), and '?' (unknown, the initial state of all
criteria for a project).
Every criterion can also have a *justification*.
For each project the system tracks the criteria status,
criteria justification, and a few other data fields such as
project name, project description, project home page URL, and
project repository (repo) URL.

Each criterion is in one of four *categories*:
'MUST', 'SHOULD', 'SUGGESTED', and 'FUTURE'.
In some cases, a criterion may require some justification
or a URL in the justification to be enough to satisfy the criterion for
a badge.  See the [criteria](./criteria.md) or
application form for the current exact rules.
A synonym for 'satifying' a criterion is 'passing' a criterion.

We have an 'autofill' system that fills in some data automatically.

In some cases the autofill data will *override* human-entered data
(this happens where we're either confident in the data, and/or
the data is not available using a common convention
that are enforcing for purposes of the badge).
The autofill system uses the metaphor of *Detectives* that need
some inputs, analyze them,
and produce outputs (including confidence levels).
Detectives are managed by a *Chief* of detectives.

## User interface design

Our visual design is based on Bootstrap.
We try to make it obvious what things do,
and avoid nonstandard visual elements if we can.

## Security

See the separate
[security](security.md) document for more about security.

## Application Programming Interface (API)

See [api](api.md) for the application programming interface (API),
including how to download data for analysis.

Its interface supports the following interfaces, which is enough
to programmatically create a new user, login and logout, create project
data, edit it, and delete it (subject to the authorization rules).
In particular, viewing with a web browser (which by default emits 'GET')
a URL with the absolute path "/projects/:id" (where :id is an id number)
will retrieve HTML that shows the status for project number id.
A URL with absolute path "/projects/:id.json"
will retrieve just the status data in JSON format (useful for further
programmatic processing).

## PostgreSQL Dependencies

As a policy, we minimize the number of dependencies on any particular
database implementation where we can.  Where possible, please
prefer portable constructs (such as ActiveRecord).

However, our current implementation requires PostgreSQL,
and we allow that (as discussed here).  Our internal
project search engine uses PostgreSQL specific commands.  Additionally,
we are using the PostgreSQL specific citext character string type to
store email addresses.  This allows us, within PostgreSQL, to store
case sensitive emails but have a case insensitive index on them.

We do this as we can foresee a case where a user's email requires case
sensitivity to be received (Microsoft Exchange allows this).  We do not,
however, want to allow for emails that are not case insensitive unique
since this could possibly allow for a number of duplicate users to be
created and the possibility of two users from the same domain having
emails which differ only in case is exceedingly rare.

Using these PostgreSQL-specific capabilities makes the software much
smaller.  Limiting these dependencies, and otherwise strongly preferring
portable constructs, makes it easier to port to a different RDBMS
in the future if necessary.
Since PostgreSQL is itself OSS, this isn't as dangerous as becoming
dependent on a single supplier whose product cannot be forked.

## See also

See:

* [requirements](./requirements.md)
* [implementation](./implementation.md)
* [background](./background.md)
* [criteria](./criteria.md)
