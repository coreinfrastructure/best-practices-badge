Background on the criteria
==========================


Potential sources of criteria
=============================

Tom Callaway's "FAIL" points identify a number of
avoidable mistakes in OSS projects.
http://opensource.com/life/15/7/why-your-open-source-project-failing

Civic Commons' wiki page:
http://wiki.civiccommons.org/Open_Source_Development_Guidelines/

Karl Fogel's book "Producing Open Source Software".

"Starting an Open Source project"
http://www.smashingmagazine.com/2013/01/starting-an-open-source-project/

There are many more potential sources.


Existing project processes
==========================

Many OSS projects *do* a number of things well.

Indeed, we intend for there to be many "0-day badge recipients" -
that is, OSS projects that are already meet the criteria.
Of course, projects that follow best practices can still
have vulnerabilities, other bugs, and other kinds of problems...
but they should be a better position to prevent, detect, and fix them.

Here are some pages describing the processes used by some OSS projects
to produce high-quality and/or high-security software.

LibreOffice
-----------

LibreOffice 5.0 uses variety of tools to detect defects to fix.
These include
cppcheck,
building without any compile warnings using various warning
flags (e.g., -Werror -Wall -Wextra),
Coverity (working to zero Coverity bugs),
PVS-Studio messages,
paranoid assertions, fuzzing,
clang plugins/checkers,
increasing unit testing (their ideal is that every bug fixed gets a
unit test to stop it from recurring),
Jenkins / CI integration with gerrit to test across 3 platforms,
and coding guidelines.
https://people.gnome.org/~michael/blog/2015-08-05-under-the-hood-5-0.html


SQLite
------

For more information on how SQLite is tested, see:
https://www.sqlite.org/testing.html


Implementation
==============

We intend to implement a simple web application
to quickly capture self-assertion data, evaluate what it can automatically,
and provide badge information.
That application will itself be OSS, of course.
We'll probably implement it using Ruby on Rails
(since Rails is good for very simple web applications like this one).
We're currently thinking of using Rails version 4.2,
storing the data in Postgres or MySQL/MariaDB, and using
RSpec, Cucumber, and FactoryGirl.
Our emphasis will be on keeping the program *simple*.

How handle authentication?
For GitHub projects, can hook into GitHub OAuth... if they can administer
a project, then they can report on that project.
Probably use "divise" module for authentication in Rails, that
works with GitHub.

We intend to make the *username* public of who entered data for each project
(generally that would be the GitHub username).
Also have our own login system, and support that, for those who don't
want to use GitHub.


GitHub-related badges
---------------------

Pages related to GitHub-related badges include:
http://shields.io/
https://github.com/badges/shields
http://nicbell.net/blog/github-flair

We want GitHub users to think of this as "just another badge to get".

We should sign up for a few badges to try out their onboarding process,
e.g., Travis (CI automation), Code Climate (code quality checker including
BrakeMan), Coveralls (code coverage), Hound (code style),
Gymnasium (checks dependencies), HCI (looks at your documentation).
For example, they provide the markdown necessary to embed the badge.
See ActiveAdmin for an example, take a few screenshots.
Many of these badges try to represent real-time status.
We might not include these badges in our system, but they
provide useful examples.

License detection
-----------------

Some information on how to detect licenses can be found in
"Open Source Licensing by the Numbers" (Ben Balter)
https://speakerdeck.com/benbalter/open-source-licensing-by-the-numbers


