# Implementation

We have implemented a simple web application called "BadgeApp"
that quickly captures self-assertion data, evaluates criteria automatically
when it can, and provides badge information.

The web application is itself OSS, and
we intend for the web application to meet its own criteria.
We are implementing it using Ruby on Rails
(since Rails is good for very simple web applications like this one).
We are currently using Rails version 4.2,
and storing the data in Postgres.
We deploy a test implementation to Heroku so that people can try it out
for limited testing.
The production version may also be deployed to Heroku.

Our emphasis will be on keeping the program *simple*.

## Automation

We want to automate what we can, but since automation is imperfect,
users need to be able to override the estimate.

Here's how we expect the form flow to go:

*   User clicks on "Get your badge!", request shows up at server.
*   If user isn't logged in, redirected to login (which may redirect to
    "make account").  Once logged in (including by making an account),
    continue on to...
*   "Short new project form" - show list of their github projects
    (if we can get that) that they can select, OR ask for
    project name, project URL, and repo URL.
    Once they identify the project and provide that back to us,
    we run AUTO-FILL, then use "edit project form".
*   "Edit project form" - note that flash entry will show anything
    added by auto-fill.  On "submit", it'll go to...
*   "Show project form" (a variant of the edit project, but all editable
    items cannot be selected).  Here it'll show if you got the badge,
    as well as all the details.  From "Show Project" you can:
    *   "Edit" - goes directly to edit project form
    *   "Auto" - re-run AUTO-FILL, apply the answers to anything currently
                 marked as "?", and go to edit project form.
    *   "JSON" - provide project info in JSON format.
    *   "Audit"- (Maybe) - run AUTO-FILL *without* editing the results,
                 and then show the project form with any differences
                 between auto answers and project answers as a flash.

AUTO-FILL:
This function tries to read from the project URL and repo URLs
and determine project answers.  A few rules:

1.  Auto-fill will *ONLY* change values currently marked as "?".
2.  Anything automatically filled will be noted on the next "flash"
    on the edit form, so that people can check what was done (and why)
    if they want to.  Perhaps those details should be toggleable.

This does create the risk that someone can claim they earned a badge
even if they didn't.  This is the fundamental risk of self-assertion.
We could identify *differences* between automation results and the
project results - perhaps create an "audit" button on
"show project form" that provided information on differences
as a flash on another
display of the "show project form" (that way, nothing would CHANGE).



## Authentication

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
1.  A way for GitHub users to authenticate themselves and show that they control specific projects on GitHub.
2.  An override system so that users can report on other projects as well (this is important for debugging and error repair).
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

## Who can edit project P?

(This is a summary of the previous section.)

A user can edit project P if one of the following is true:

1.  If the user has "superuser" permission then the user can edit the badge information about any project.  This will let the Linux Foundation fix problems.
2.  If project P is on GitHub AND the user is authorized via GitHub to edit project P, then that user can edit the badge information about project P.  In the future we might add repos other than GitHub, with the same kind of rule.
3.  If the user's cryptographically randomly assigned "project edit validation code" is on the project's main web site (typically in an HTML comment), then the user can edit the badge information about project P.  Note that if the user is a local account (not GitHub), then the user also has to have their email address validated first.

## Filling in the form

Previously we hoped to auto-generate the form, but it's difficult to create a good UI experience that way.  So for the moment, we're not doing that.

Every bullet with a MUST, MUST NOT, SHOULD / RECOMMENDED, or SUGGESTED will have a matching [criteria-name] entry (note that [criteria-name] may have a dagger and/or asterisk after it).  Change a criteria-name into a "fieldname" by converting all "-" to "_"; this generates the database field name.  (The SQL specifications do not include "-" in simple field names).

If the fieldname ends in "_url", it records a URL, and there are no other fields.  To get credit for such a URL, it needs to begin with "https?://", NOT include a "?" (that will counter some attempts to use BadgeApp to attack other systems), and that URL needs to be readable.  Empty URLs for MUST requirements should be highlighted somehow.

Otherwise, the fieldname records Met/Not met/blank that users must directly assert, and there is at least one other field that users can enter text into: fieldname + "_justification".  *If* we have automated that field, then there is a field named fieldname + "_auto" that records an automated result justifying that it meets the criteria.  Any criteria with a MUST, MUST NOT, SHOULD, or RECOMMENDED gets credit if the fieldname is "Met" (if SHOULD/RECOMMENDED, then "Not Met" is also allowed) and (1) fieldname_auto justifies it, OR (2) filename_justification is nonblank and includes at least one URL (which is supposed to be a pointer to supporting information).

We previously proposed a "Considered" value (separate from "blank"), but that makes the user interface excessively complex for little gain.  If it's marked "not met" and has a justification, then clearly it's been considered.

We should try to occasionally save the form (perhaps every time they leave a field), so that people won't lose data partway through.


## GitHub-related badges

Pages related to GitHub-related badges include:

*   http://shields.io/ - serves files that display a badge (as good-looking scalable SVG files)
*   https://github.com/badges/shields -  Shields badge specification, website and default API server (connected to shields.io)
*   http://nicbell.net/blog/github-flair - a blog post that identifies and discusses popular GitHub flair (badges)

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

Some information on how to detect licenses can be found in
[&#8220;Open Source Licensing by the Numbers&#8221; by Ben Balter](https://speakerdeck.com/benbalter/open-source-licensing-by-the-numbers).

## Analysis

We intend to use Brakeman,
a static analysis security scanner for Ruby on Rails.
This lets us fulfill the "static source code analysis" criterion.

We are using the OWASP ZAP web application scanner to find potential
vulnerabilities before full release.
This lets us fulfill the "dynamic analysis" criterion.


## Other things

We are considering the use of RSpec, Cucumber, and FactoryGirl.

# See also

See the separate "[background](./background.md)" and
"[criteria](./criteria.md)" pages for more information.

