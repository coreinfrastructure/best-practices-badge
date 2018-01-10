# Application Programming Interface (API)

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

BadgeApp is a relatively simple web application, so its
external interface is simple too.
The BadgeApp API is a simple REST API that follows
Ruby on Rails conventions.

## Quickstart

Like any REST API, use an HTTP verb (like GET) on a resource.

For example, you can get the JSON data for project #1 from the
real production site (<https://bestpractices.coreinfrastructure.org>)
by retrieving (a GET) data from this URL:

    https://bestpractices.coreinfrastructure.org/projects/1.json

Note that you can ask for a particular result data format (where
supported) by adding a period and its format (e.g., ".json", ".csv",
and ".svg") to the URL before the parameters (if any).

A GET just retrieves information, and since most information is public,
in most cases you don't need to log in for a GET.
Other operations, like POST or DELETE, require logging in first
(as is typical, cookiers are used to track logged-in sessions).

From here on we'll omit the scheme (https) and hostname, and
we'll indicate variables by beginning their name with ":" (colon).
So the URL above is an example of this pattern, which retrieves
information about project :id in a given :format (HTML by default):

    GET /projects/:id(.:format)

## Most common requests

Here are the most common requests that an external system
might request.

*   <tt>GET /projects/:id(/:level)(.:format)</tt>

    Request data for project :id in :format (default html).
    External interfaces should normally request format "json".
    If "level" is given (0, 1, or 2), that level is shown
    (level is ignored if json format is requested, because we just
    provide *all* the data when JSON is requested).

*   <tt>GET /projects/:id/badge(.:format)</tt>

    Request the badge display for project :id in :format (default SVG).

*   <tt>GET /projects(.:format)(?:query)</tt>

    Perform a query on the projects to return a list
    of the matching projects, up to the maximum number allowed in a page.
    The format is html by default; json and csv are supported.
    See below for more about the query.

## Query (Search)

The "/projects" URL supports various searches.
For example, retrieving this:

    /projects.json?gteq=90&amp;lteq=99&amp;page=2

Will retrieve a list of project data in JSON format, but only for
projects with 90% or better passing *and* less than or equal to 99%
passing (that is, not completely passing), and will retrieve the second
page of this list (by default the first page is returned).

We reserve the right to change the details, but we do try
to provide a reasonable interface.
Most parameters can be combined (in which case all criteria must be met).
The following search parameters are supported:

*   status: "passing", "in_progress", "silver", or "gold"
*   gteq: Integer, % greater than or equal of passing criteria
*   lteq: Integer, % less than or equal of passing criteria.
    Can be combined with gteq
*   pq: Text, "prefix query" - matches against *prefix* of URL or name
*   q: Text, "normal query" - match against parsed name, description, URL
    This is implemented by PostgreSQL, so you can use "&amp;" (and),
    "|" (or), and "'text...*'" (prefix).
    This parses URLs into parts; you can't search on a whole URL (use pq).
*   page: Page to display (starting at 1)

See app/controllers/project_controllers.rb if you want to see the
implementation's source code.

## Downloading the database

We encourage analysis of OSS trends.
We do provide some search capabilities, but for most analysis
you will typically need to download the database.
We can't anticipate all possible uses, and we're trying to keep the
software relatively small & focused.

You can download the project data in JSON and CSV format using typical
Rails REST conventions.
Just add ".json" or ".csv" to the URL (or include an Accept statement,
like "Accept: application/json", in the HTTP header).
You can even do this on a search if we already support the search (e.g.,
by name).  Similarly, you can download user data in JSON format using
".json" at the end of the URL.

There is a current technical limitation in that you must
request project and user data page-by-page.
This isn't hard, just provide a page parameter (e.g., "page=2").
This is because Rails does not stream JSON or CSV data by default,
so if we allowed this the application would download
the entire database into memory to process it.
Rails applications *can* stream data (there are even web pages explaining
how to do it), but the call for it is rare and there are some
complications in its implementation, so we just haven't implemented it yet.

So you can download the projects by repeatedly requesting this
(changing "1" into 2, 3, etc. until all is loaded):

> https://bestpractices.coreinfrastructure.org/projects.json?page=1

You can similarly load the user data starting from here:

> https://bestpractices.coreinfrastructure.org/users.json?page=1

To directly download the user list you must be logged in, and we
intentionally restrict the information we share about users.
We only provide basic public information such as name, nickname, and such.
In particular, we only provide email addresses to
BadgeApp administrators, because we value the privacy of our users.

As we note about privacy and legal issues,
please see our <a href="https://www.linuxfoundation.org/privacy">privacy
policy</a> and <a href="https://www.linuxfoundation.org/terms">terms of
use</a>.
All publicly-available non-code content is released under at least the
<a href="https://creativecommons.org/licenses/by/3.0/">Creative Commons
Attribution License version 3.0 (CC-BY-3.0)</a>;
newer non-code content is released under
CC-BY version 3.0 or later (CC-BY-3.0+).
If referencing collectively or
not otherwise noted, please credit the
"CII Best Practices badge contributors" and note the license.
You should also note the website URL as the data source, which is
<https://bestpractices.coreinfrastructure.org>.

If you are doing research, we urge you do to it responsibly and reproducibly.
Please be sure to capture the date and time when you began and completed
capturing this dataset
(you need both, because the data could be changing
while you're downloading it).
Do what you can to ensure that your research can be
[replicated](https://en.wikipedia.org/wiki/Replication_crisis).
Consider the points in
[Good Enough Practices in Scientific Computing](https://arxiv.org/pdf/1609.00037v2.pdf), a "set of computing tools and techniques
that every researcher can and should adopt."
For example, "Where possible, save data as originally generated (i.e.
by an instrument or from a survey."
These aren't requirements for using this data, but they are well
worth considering.

## Full entry point list

The REST interface supports the following interfaces, which is enough
to programmatically create a new user, login and logout, create project
data, edit it, and delete it (subject to the authorization rules).
In particular, viewing with a web browser (which by default emits 'GET')
a URL with the absolute path "/projects/:id" (where :id is an id number)
will retrieve HTML that shows the status for project number id.
A URL with absolute path "/projects/:id.json"
will retrieve just the status data in JSON format (useful for further
programmatic processing).

The following shows the HTTP verb (e.g., GET), the URI pattern, and
the controller#action in the code (important if you need to examine
the source code itself which is in directory app/controllers/).

~~~~
Verb   URI Pattern                        Controller#Action
GET    /projects/:id(.:format)            projects#show # .json supported.
GET    /projects/:id/badge(.:format)      projects#badge {:format=>"svg"}

GET    /projects(.:format)                projects#index
POST   /projects(.:format)                projects#create
GET    /projects/new(.:format)            projects#new
GET    /projects/:id/edit(.:format)       projects#edit
PATCH  /projects/:id(.:format)            projects#update
PUT    /projects/:id(.:format)            projects#update
DELETE /projects/:id(.:format)            projects#destroy

GET    /users/new(.:format)               users#new
GET    /signup(.:format)                  users#new
GET    /users/:id/edit(.:format)          users#edit
GET    /users/:id(.:format)               users#show

GET    /sessions/new(.:format)            sessions#new
GET    /login(.:format)                   sessions#new
POST   /login(.:format)                   sessions#create
DELETE /logout(.:format)                  sessions#destroy
GET    /signout(.:format)                 sessions#destroy
~~~~

If you install the application you can have it report the routes
by running "rake routes".

## Locale

Users indicate the locale via the URL.
The recommended form is at the beginning of that path, e.g.,
<https://bestpractices.coreinfrastructure.org/fr/projects/>
selects the locale "fr" (French) when displaying "/projects".
This even works at the top page, e.g.,
<https://bestpractices.coreinfrastructure.org/fr/>.
The application also supports the locale as a query parameter, e.g.,
<https://bestpractices.coreinfrastructure.org/projects?locale=fr>

If a locale is not provided, English (en) is assumed.
In most cases the locale is irrelevant if the format is not HTML
(in these cases the data is provided in a machine-readable format
that does not depend on the locale).

Locales are always exactly 2 lowercase letters, or 2 lowercase letters
followed by an dash and then more alphanumerics.
For example, "fr" is French, while "zh-cn" is Chinese (Simplified).
This convention lets you syntactically distinguish between
locales and other possible meanings of a URL's prefix.
