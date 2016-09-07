# Implementation

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

We have implemented a simple web application called "BadgeApp" that
quickly captures self-assertion data, evaluates criteria automatically
when it can, and provides badge information.
Our emphasis is on keeping the program relatively *simple*.

This file provides information on how it's implemented, in the hopes that
it will help people make improvements.
See [CONTRIBUTING.md](../CONTRIBUTING.md) for information on how to
contribute ot this project, and [INSTALL.md](INSTALL.md) for information
on how to install this software (e.g., for development).

In this document we'll use the term "open source software" (OSS),
and treat Free/Libre and Open Source Software (FLOSS) as a synonym.

## Requirements

The BadgeApp web application MUST:

1. Meet its own criteria.  This implies that it must be open source software
   (OSS).
2. Be capable of being developed and run using *only* OSS.
   It may *run* on proprietary software; portability improvements welcome.
   It's also fine if it can use proprietary services, as long as it can
   *run* without them.
3. Support users of modern widely used web browsers, including
   Chrome, Firefox, Safari, and Internet Explorer version 10 and up.
   We expect Internet Explorer pre-10 users will use a different browser.
4. NOT require Javascript to be enabled on the web browser (some
   security-conscious people disable it) - instead, support graceful
   degradation (many features will work much better if Javascript is enabled).
   Requiring CSS is fine.
5. Support users of various laptops/desktops
   (running Linux (Ubuntu, Debian, Fedora, Red Hat Enterprise Linus),
   Microsoft Windows, or Apple MacOS) and mobile devices
   (including at least Android and iOS).
6. NOT require OSS projects to use GitHub or git.
   We do use GitHub and git to *develop* BadgeApp (that's different).
7. Automatically fill in some criteria where it can, at least if a
   project is on GitHub.  Automating filling in data is a never-ending
   process of refinement. Thus, we intend to fill a few to start, and then
   add more automation over time.

See the separate
[security](security.md) document for more about security, including
its requirements.

There are many specific requirements; instead of a huge requirements document,
most specific requirements are proposed and processed via its
[GitHub issue tracker](https://github.com/linuxfoundation/cii-best-practices-badge/issues).
See [CONTRIBUTING](../CONTRIBUTING.md) for more.

## Overall

The web application is itself OSS, and we intend for the
web application to meet its own criteria.
We have implemented it with Ruby on Rails; Rails is good for
simple web applications like this one.
We are currently using Rails version 4.
The production system stores the data in Postgres.

Some other key components we use are:

- Bootstrap
- Jquery
- Jquery UI
- Imagesloaded <https://github.com/desandro/imagesloaded>
  (to ensure images are loaded before displaying them)
- Puma as the webserver - not webrick, because Puma can handle multiple
  processes and multiple threads.  We don't use multiple threads right
  now, but that's desirable in the future. See:
  <https://devcenter.heroku.com/articles/ruby-default-web-server>
- A number of supporting Ruby gems (see the Gemfile)

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

## Environment variables

The application is configured by various environment variables:

* PUBLIC_HOSTNAME (default 'localhost')
* BADGEAPP_MAX_REMINDERS (default 2): Number of email reminders to send
  to inactive projects when running "rake reminders".
  This rate limit is best set low to start,
  and relatively low afterwards, to limit impact if there's an error.
* RAILS_ENV (default 'development'): Rails environment.
  The master, staging, and production systems set this to 'production'.

## Terminology

This section describes key application-specific terminology.

The web application tracks data about many OSS *projects*,
as identified and entered by *users*.

We hope that projects will (eventually) *achieve* a *badge*.
A project must *satisfy* (or "pass") all *criteria*
(singular: criterion) enough to achieve a badge.

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

See below for more detail.

## Running locally

Once your development environment is ready, you can run the application with:

~~~~
rails s
~~~~

This will automatically set up what it needs to, and then run the
web application.
You can press control-C at any time to stop it.

Then point your web browser at "localhost:3000".

## Security

See the separate
[security](security.md) document for more about security.


## Interface

This is a relatively simple web application, so its
external interface is simple too.

It has a few common use cases:

- Users who want to get a new badge.
  They will log in (possibly creating an account first
  if they don't use GitHub), select "add a project".
  They will see a long HTML form, which they can edit and submit.
  They can always go back, re-edit, and re-submit.
- Others who want to see the project data.  They can just go to
  the project page (they don't need to log in) to see the data.
- Those who want to see the badge for a given project
  (typically because this is transcluded).
  They would 'get' the /projects/:id/badge(.:format);
  by default, they would get an SVG file showing the status
  (i.e., 'passing' or 'failing').

Its interface supports the following interfaces, which is enough
to programmatically create a new user, login and logout, create project
data, edit it, and delete it (subject to the authorization rules).
In particular, viewing with a web browser (which by default emits 'GET')
a URL with the absolute path "/projects/:id" (where :id is an id number)
will retrieve HTML that shows the status for project number id.
A URL with absolute path "/projects/:id.json"
will retrieve just the status data in JSON format (useful for further
programmatic processing).

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

This uses Rails' convention where
a 'get' of /projects/:id/edit(.:format)' is considered an edit;
this would normally create a CSRF vulnerability, but Rails automatiacally
inserts and checks for a CSRF token, countering this potential vulnerability.

## Search

The "/projects" URL supports various searches.
We reserve the right to change the details, but we do try
to provide a reasonable interface.
The following search parameters are supported:

* status: "passing" or "in_progress"
* gteq: Integer, % greater than or equal
* lteq: Integer, % less than or equal.  Can be combined with gteq.
* pq: Text, "prefix query" - matches against *prefix* of URL or name
* q: Text, "normal query" - match against parsed name, description, URL.
  This is implemented by PostgreSQL, so you can use "&amp;" (and),
  "|" (or), and "'text...*'" (prefix).
  This parses URLs into parts; you can't search on a whole URL (use pq).
* page: Page to display

See app/controllers/project_controllers.rb for how these
are implemented.


## Changing criteria

To modify the text of the criteria, edit these files:

- doc/criteria.md - Document
- ./criteria.yml - YAML file used by BadgeApp for criteria information.

If you're adding/removing fields (including criteria), be sure to also edit
app/views/projects/\_form.html.erb
(to determine where to display it).
You may also want to edit the README.md file, which includes a summary
of the criteria.

When adding or removing fields, or when renaming
a criterion name, you may need to edit the test creator db/seeds.rb file,
and you will certainly need to create a database migration.
The "status" (met/unmet) is the criterion name + "\_status" stored as a string;
each criterion also has a name + "\_justification" stored as text.
So every add, remove, or rename of a criterion involves changing
*two* fields in the database schema.
Here are the commands, assuming your current directory is at the top level,
EDIT is the name of your favorite text editor, and MIGRATION_NAME is the
logical name you're giving to the migration (e.g., "add_discussion").
By convention, begin a migration name with 'add' to add a column and
'rename' to rename a column:

~~~~
  rails generate migration MIGRATION_NAME
  git add db/migrate/*MIGRATION_NAME.rb
  $EDITOR db/migrate/*MIGRATION_NAME.rb
~~~~

Your migration file should look something like this if it adds columns
(where add_column takes the name of the table, the name of the column,
the type of the column, and then various options):

~~~~
class MIGRATION_NAME < ActiveRecord::Migration
  def change
    add_column :projects, :crypto_alternatives_status, :string, default: '?'
    add_column :projects, :crypto_alternatives_justification, :text
  end
end
~~~~

Similarly, your migration file should look something like this
if it renames columns:

~~~~
class Rename < ActiveRecord::Migration
  def change
    rename_column :projects,
                  :description_sufficient_status,
                  :description_good_status
    rename_column :projects,
                  :description_sufficient_justification,
                  :description_good_justification
  end
end
~~~~

In some cases it may be useful to insert SQL commands or do
other special operations in a migration.
See the migrations in the db/migrate/ directory for examples.

Once you've created the migration file, check it first by running
"rake rubocop".  This will warn you of some potential issues, and
it's much better to fix them early.
(You can't run just "rake", because that invokes "rake test", and
the dynamic tests in "rake test" won't work until you execute
the migration).

You can migrate by running:

~~~~
  $ rake db:migrate
~~~~

If it fails, you *may* need to use "rake db:rollback" to roll it back.

You may also need to modify tests in the tests/ subdirectory, or
modify the autofill code in the app/lib/ directory.

Be sure to "git add" all new files, including any migration files,
and then use "git commit" and "git push".


## App authentication via GitHub

The BadgeApp needs to authenticate itself through OAuth2 on
GitHub if users are logging in with their GitHub accounts.
It also needs to authenticate itself to get repo details from GitHub if a
project is being hosted there.
The app needs to be registered with GitHub[1] and its OAuth2 credentials
stored as environment variables.
The variable names of Oauth2 credentials are "GITHUB_KEY" and "GITHUB_SECRET".
If running on heroku, set config variables by following instructions on [2].

If running locally, these variables need to be set up.
We have set up a file '.env' at the top level which has stub values,
formatted like this, so that it automatically starts up
(note that these keys are *not* what we used for the deployed systems,
for obvious reasons):

~~~~sh
export GITHUB_KEY = '..VALUE..'
export GITHUB_SECRET = '..VALUE..'
~~~~

You can instead provide the information this way if you want to
temporarily override these:

~~~~sh
GITHUB_KEY='client id' GITHUB_SECRET='client secret' rails s
~~~~

where *client id* and *client secret* are registered OAuth2 credentials
of the app.

The authorization callback URL in GitHub is: http://localhost:3000/auth/github

[1] <https://github.com/settings/applications/new>
[2] <https://devcenter.heroku.com/articles/config-vars>

## Database content manipulation

In some cases you may need to view or edit the database contents directly.
For example, we don't currently have code to set a user to have the
'admin' role, or to change the ownership of a project,
to backup the database, or restore the database.
Instead, we simply interact with the database software, which
already has the functions to do this.

In development mode, simply view 'localhost:3000/rails/db'
in your web browser.
You can select any table (on the left-hand side) so you can view
or edit the database contents with a UI.

You can directly connect to the database engine and run commands.
On the local development system, run "rails db" as always.
To change the database contents of a production system,
log into that system and use the SQL language to make changes.
E.G., on Heroku, presuming that you have installed the heroku command,
and configured it for the system you are controlling
(including the necessary keys),
you can pipe SQL commands to 'heroku pg:psql'.
This only works if you've been given keys to control this.
On Heroku we use PostgreSQL.
Here are a few examples (replace the "heroku pg:psql..." with "rails db"
to do it locally):

~~~~sh
echo "SELECT * FROM users WHERE users.id = 1" | \
  heroku pg:psql --app master-bestpractices
echo "SELECT * FROM users WHERE name = 'David A. Wheeler'" | \
  heroku pg:psql --app master-bestpractices
echo "UPDATE users SET role = 'admin' where id = 25" | \
  heroku pg:psql --app master-bestpractices
echo "UPDATE projects SET user_id = 25 WHERE id = 1" | \
  heroku pg:psql --app master-bestpractices
~~~~

You can force-create new users and make them admins
(again, if you have the rights to do so).
To create new github user, first get their github uid from their
github username (nickname) by looking at
https://api.github.com/users/USERNAME
and getting the "id" value.
Then run this, replacing all-caps stubs with the values in single quotes
(this will create a local id automatically):

~~~~sh
echo "INSERT INTO users (provider,uid,name,nickname,email,role,activated,
  created_at,updated_at)
  VALUES ('github',GITHUB_UID,FULL_USER_NAME,
  GITHUB_USERNAME,EMAIL,'admin',t,now(),now());" | \
  heroku pg:psql --app master-bestpractices
~~~~

You can
[import or export databases on Heroku](https://devcenter.heroku.com/articles/heroku-postgres-import-export)
For example, here's how to quickly back up the database
(presuming that it's set up for the Heroku site and that you have
the authorization keys to do this):

~~~~sh
heroku pg:backups capture
curl -o latest.dump $(heroku pg:backups public-url)
~~~~

## Purging Fastly CDN cache

If a change in the application causes any badge level(s) to change,
you need to purge the Fastly CDN cache after pushing.
Otherwise, the Fastly CDN cache will continue to serve the old badge
images (until they time out).

You can purge the Fastly CDN cache this way (assuming you're
allowed to log in to the relevant Heroku app):

~~~~sh
heroku run --app HEROKU_APP_HERE rake fastly:purge
~~~~

This command will use the value of the FASTLY_API_KEY
configured for that Heroku application (Fastly requires authorization
for purging the entire cache)... so you don't have to provide it yourself.

It's safe to purge the cache if you're not sure if you need to do it.
After a cache purge, the next request for each badge will go
to the website, so for a brief time the site will
be busy serving badge files.

## Resetting Heroku plug-ins

Here's how to reset the heroku-local plugin:

~~~~sh
heroku plugins:uninstall heroku-local --app master-bestpractices
heroku plugins --app master-bestpractices
~~~~

The latter automatically reinstalls heroku-local.
This information is from: <https://github.com/heroku/heroku/issues/1690>.

Normally you should just push changes to "master" first, so that
CircleCI will test it.  If you want to push directly to Heroku
(and have the necessary rights):

git remote add heroku https://git.heroku.com/master-bestpractices.git

Now you can directly deploy to Heroku:

~~~~
git checkout master
git push heroku master
~~~~


## Auditing

The intent is to eventually have an "audit" function that
runs auto-fill without actually editing the results, and then
show the differences between the automatic results and the form values.
This will let external users compare things.

## Autofill

The process of automatically filling in the form is called
"autofill".

Earlier discussions presumed that the human would always be right, and
that the automation would only fill in unknowns ("?").
However, we've since abandoned this; instead, in some cases we want
to override (either because we're confident or because we want to require
projects to provide data in a way that we can be confident in it).

Autofill must use some sort of pluggable interface, so that people
can add them.  We will focus on getting data from GitHub, e.g.,
api.gihub.com/repos has a lot of information.
The pluggable interface could be implemented using Service Objects;
it's not clear that's the best way.
We do want to create directories where people can just add new files to
add new plug-ins.

We name each separate module that detects something a "Detective".
A Detective needs to be called, be able to get data, and eventually
return a set of findings.
The findings are a hash with
attributes and findings about them:
(proposed new) value, confidence, and justification (string).

The "Chief" module calls the Detectives in the right order and
merges the results.
Confidence values range from 0..5; confidence values of 4 or higher
override the user input.

## Authentication

Currently we allow people to log in using their GitHub account
or a local account (so people who don't want to use GitHub don't need to).

## Ideas about Authentication

An important issue is how to handle authentication.
Here is our current plan, which may change (suggestions welcome).

In general, we want to ensure that only trusted developer(s) of a project
can create or modify information about that project.
That means we will need to authenticate individual *users* who enter data,
and we also need to authenticate that a specific user is a trusted developer
of a particular project.

For our purposes the project's identifier is the project's main URL.
This gracefully handles project forks and
multiple projects with the same human-readable name.
We intend to prevent users from editing the project URL once
a project record has been created.
Users can always create another table entry for a different project URL,
and we can later loosen this restriction (e.g., if a user controls both the
original and new project main URL).

We plan to implement authentication in these three stages:
1.  A way for GitHub users to authenticate themselves and
show that they control specific projects on GitHub.
2.  An override system so that users can report on other projects
as well (this is important for debugging and error repair).
3.  A system to support users and projects not on GitHub.

For GitHub users reporting about specific projects on GitHub,
we plan to hook into GitHub itself.
We believe we can use GitHub's OAuth for user authentication.
If someone can administer a GitHub project,
then we will presume that they can report on that project.
We will probably use the &#8220;divise&#8221; module
for authentication in Rails (since it works with GitHub).

We will next implement an override system so that users can report on
other projects as well.
We will add a simple table of users and the URLs of the projects
whose data they can *also* edit (with "*" meaning "any project").
A user who can edit information for
any project would presumably also be able to modify
entries of this override table (e.g., to add other users or project values).
This will enable the Linux Foundation to easily
override data if there is a problem.
At the beginnning the users would still be GitHub users, but the project URL
they are reporting on need not be on GitHub.

Finally, we will implement a user account system.
This enables users without a GitHub user account to still use the system.
We would store passwords for each user (as iterated cryptographic hashes
with per-user salt; currently we expect to use bcrypt for iteration),
along with a user email address to eventually allow for password resets.

All users (both GitHub and non-GitHub) would have a cryptographically
random token assigned to them; a project URL page may include the
token (typically in an HTML comment) to prove that a given user is
allowed to represent that particular project.
That would enable projects to identify users who can represent them
without requiring a GitHub account.

Future versions might support sites other than GitHub; the design should
make it easy to add other sites in the future.

We intend to make public the *username* of who last
entered data for each project (generally that would be the GitHub username),
along with the edit time.
The data about the project itself will also be public, as well
as its badge status.

In the longer term we may need to support transition of a project
from one URL to another, but since we expect problems
to be relatively uncommon, there is no need for that capability initially.

## Plans: Who can edit project P?

(This is a summary of the previous section.)

A user can edit project P if one of the following is true:

1.  If the user has "superuser" permission then the user can edit the
badge information about any project.
This will let the Linux Foundation fix problems.
2.  If project P is on GitHub AND the user is authorized via GitHub
to edit project P, then that user can edit the badge information about project P.
In the future we might add repos other than GitHub, with the same kind of rule.
3.  If the user's cryptographically randomly assigned
"project edit validation code" is on the project's main web site
(typically in an HTML comment), then the user can edit the badge
information about project P.
Note that if the user is a local account (not GitHub),
then the user also has to have their email address validated first.

## GitHub-related badges

Pages related to GitHub-related badges include:

*   <http://shields.io/> - serves files that display a badge
(as good-looking scalable SVG files)
*   <https://github.com/badges/shields> -  Shields badge specification,
website and default API server (connected to shields.io)
*   <http://nicbell.net/blog/github-flair> - a blog post that identifies
and discusses popular GitHub flair (badges)

We want GitHub users to think of this
as &#8220;just another badge to get.&#8221;

We intend to sign up for a few badges so we can
evalute their onboarding process,
e.g., Travis (CI automation), Code Climate (code quality checker including
BrakeMan), Coveralls (code coverage), Hound (code style),
Gymnasium (checks dependencies), HCI (looks at your documentation).
For example, they provide the markdown necessary to embed the badge.
See ActiveAdmin for an example, take a few screenshots.
Many of these badges try to represent real-time status.
We might not include these badges in our system, but they
provide useful examples.

## Other badging systems

Mozilla's Open Badges project at <http://openbadges.org/>
is interesting, however, it is focused on giving badges to
individuals not projects.

## License detection

Some information on how to detect licenses in projects
(so we can perhaps autofill them) can be found in
[&#8220;Open Source Licensing by the Numbers&#8221; by Ben Balter](https://speakerdeck.com/benbalter/open-source-licensing-by-the-numbers).

For the moment, we just use GitHub's mechanism.
It's easy to invoke and resolves it in a number of cases.

## Implementation of Detectives.

The detective classes are located in the directory often located in the directory ./workspace/cii-best-practices-badge/app/lib.  This directory contains all of the detectives and has a very specific naming convention.  All new detectives must be named name1_detective.rb.  This name is important as it will be called by the primary code chief.rb which calls and collects the results of all of the detective classes.  

To integrate a new class chief.rb must be edited in the following line.

ALL_DETECTIVES =
  [
    NameFromUrlDetective, ProjectSitesHttpsDetective,
    GithubBasicDetective, HowAccessRepoFilesDetective,
    RepoFilesExamineDetective, FlossLicenseDetective,
    HardenedSitesDetective (Name1Detective)
  ].freeze

  where Name1Detective corrosponds to the new class created in name1_detective.  Without following the naming convention chief will not run the new detective.

  A template detective called blank_detective.rb is supplied with the project with internal documentation as to how to use it.  

  Remember, in addition to the detective you must right a test in order for it
  to be accepted into the repository.  The tests are located at ./test/unit/lib/
  with an example test of blank_detective included.

## Analysis

We use the OWASP ZAP web application scanner to find potential
vulnerabilities.
This lets us fulfill the "dynamic analysis" criterion.

## Setup for deployment

If you want to deploy this yourself, you need to set some things up.
Here we'll presume Heroku.

You need to have email set up.
See the Action mailer basics guide at
<http://guides.rubyonrails.org/action_mailer_basics.html>
and Hartl's Rails tutorial, e.g.:
<https://www.railstutorial.org/book/account_activation_password_reset#sec-email_in_production>

To install sendgrid on Heroku to make this work, use:

~~~~sh
heroku addons:create sendgrid:starter
~~~~

If you plan to handle a lot of queries, you probably want to use a CDN.
It's currently set up for Fastly.

## Badge SVG

The SVG files for badges are:

- <https://img.shields.io/badge/cii_best_practices-passing-green.svg>
- <https://img.shields.io/badge/cii_best_practices-in_progress-yellow.svg>
- <https://img.shields.io/badge/cii_best_practices-failing-red.svg>

## Licenses of the software used by BadgeApp

See CONTRIBUTING.md for the license rules;
fundamentally we require software to be released as OSS
before we can depend on it.

The following components don't declare a license in their Gemfile,
and were researched separately:

* gitlab: URL <https://github.com/NARKOZ/gitlab/blob/master/LICENSE.txt> reveals this to be license BSD-2-Clause.
* colored: URL <https://github.com/defunkt/colored/blob/master/LICENSE> reveals this to be license MIT.

For more on license decisions see doc/dependency_decisions.yml.
You can also run 'rake' and see the generated report
license_finder_report.html.

## HTML link checking

GitHub has relatively recently changed its robots.txt file so
that only certain agents are allowed to retrieve files.
This means that typical link-checking services don't work, since common
services like the W3C's link checker are rejected.

This can be worked around by downloading the W3C link checker,
disabling robots.txt, and running it directly.  You need to be very
careful when doing this.  We'll install the "Linkchecker" package from CPAN
(command name is 'checklink') to do this.  Here's how.

~~~~
cpan /W3C-LinkChecker-4.81/
cpan LWP::Protocol::https # Needed for HTTPS
su
cd /usr/local/bin
cp checklink checklink-norobots

patch -p0 <<END
--- checklink   2016-02-24 10:37:05.000000000 -0500
+++ checklink-norobots  2016-02-24 10:48:24.856983414 -0500
@@ -48,7 +48,7 @@
 use Net::HTTP::Methods 5.833 qw();    # >= 5.833 for 4kB cookies (#6678)

 # if 0, ignore robots exclusion (useful for testing)
-use constant USE_ROBOT_UA => 1;
+use constant USE_ROBOT_UA => 0;

 if (USE_ROBOT_UA) {
     @W3C::UserAgent::ISA = qw(LWP::RobotUA);
END
~~~~

You can then run, e.g.:

~~~~
checklink-norobots -b -e \
  https://github.com/linuxfoundation/cii-best-practices-badge | tee results
~~~~


# See also

See the separate "[background](./background.md)" and
"[criteria](./criteria.md)" pages for more information.
