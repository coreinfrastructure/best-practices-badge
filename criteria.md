Open Source Software Best Practices Criteria (version 0.0.1)
============================================================

Introduction
============

This *early* *draft* document identifies proposed best practices
for open source software (OSS), including those that are likely to lead
to secure software.
The goal is to eventually create a "badging" program where OSS projects
that meet the criteria can voluntarily self-certify that they meet the
criteria and then be able to show a badge.
A tool will be used to automatically evaluate some criteria where that
is relatively easy to evaluate (e.g., to determine if the project uses an
OSS license and identifies it in a standard way).

This is a very early version of this document;
we expect a number of changes.
This version of the criteria is *NOT* endorsed by anyone;
we are releasing this early version so we can get feedback.
Feedback is welcome via the GitHub site as issues or pull requests:
https://github.com/linuxfoundation/cii-best-practices-badge

Many people today depend on OSS projects; that means that security
vulnerabilities in some OSS projects can cause trouble for many.
No single measure guarantees that software will have absolutely
no vulnerabilities
(even formal methods will fail if the specification is wrong).
However, there are some "best practices" that can help.
For example, many practices can encourage the multi-person review
that can help find otherwise hard-to-find vulnerabilities.
These criteria were created to help encourage OSS projects to
take positive steps, and to help users know which projects are taking
these positive steps.
By creating a "badge" we create a simple way to know whether or not
these criteria have been met.

Currently the criteria includes general best practices combined
with best practices specific to security.
These could be separated if desired.
The criteria are inspired by a variety of sources;
see the separate "background" page for more.

We expect that the criteria will be updated, even after badges are released.
Thus, criteria will probably have a year identifier and age out after
a year or two. 
We expect it to be trivial for a well-run OSS project to update, though,
so that should not be a barrier.

Below are the current (draft) criteria, potential criteria,
non-criteria, future plans, and where to get more information.

Current criteria
================

Here is the current (draft) criteria; it is certain to change.
The ones with (AUTO) are intended to be automatically testable
if the project happens to be hosted on GitHub.


*   OSS project basics
    -   Project website (AUTO).  The project has a public website.
    -   Project website content.  The project website has information on what the project is trying to do, as well as how to get the software, send feedback (as bug reports or feature requests), and contribute.
    -   OSS license (AUTO).  An OSS license is posted in a standard place, e.g., LICENSE or COPYING optionally followed by .txt or .md.  It should be OSI-approved; it must be approved by at least one of OSI, FSF, Debian, or Fedora.  We intend for the automated tool to focus on standard, common licenses such as MIT, 2-clause BSD, 3-clause revised BSD, MIT, Apache 2.0, LGPL, or GPL; unusual licenses cause long-term problems for OSS projects.  We expect that that "higher-level" criteria would set a higher bar, e.g., that it *must* be an OSI-approved license.
    -   Public version-controlled source repository (AUTO).  It doesn't need to be git, though that is a common implementation.  We are aware that some projects do not do this, but the lack of a public repository makes it unnecessarily difficult to contribute and track progress (e.g., to see who is contributing what and what has changed over time).
    -   Issue (bug) reporting process (e.g., issue tracker or mailing list) where developers respond (AUTO); must be archived for later searching.  Can be automated by looking at response rate for (bug) issues.  It's okay if enhancements aren't responded to the same degree.
    -   Unique version number for releases (AUTO).  We recommend Semantic Versioning (SemVer) for releases.
    -   Documentation.  This should include how to install, get started, and some reference documentation.
    -   ChangeLog (could be separate ChangeLog file, or the GitHub ChangeLog comments) - provides summary of major changes between released versions (a ChangeLog is *not* just "git log" output).  It's okay to use GitHub releases, per https://github.com/blog/1547-release-your-software
*   Quality
    -   Working build system (Maven, Ant, cmake, autoconf, etc.) *or* it never needs to be built (AUTO in many cases) 
    -   Includes automated test suite.
    -   Compiler warning flags enabled (or a linter used) and few warnings reported (ideally none, want < 1/1000 lines).
*   Security
    -   Secured delivery against man-in-the-middle attacks (AUTO).   Using https or ssh+scp is acceptable. Ideally the software is released with digitally signed packages, since that mitigates attacks on the distribution system.  A sha1sum that is only retrieved over http (and not separately signed) is *not* acceptable, since these can be modified in transit.
    -   Vulnerability report process (e.g., mailing address).  If private reports are supported, include how to send encrypted messages & keep change private.
*   Security analysis
    -   At least one static analysis tool applied to source code to look for vulnerabilities & fixed (e.g., Coverity, Fortify, clang static analyzer, etc.).
    -   At least one dynamic tool applied & vulnerabilities fixed (e.g., fuzzing, web application scanner).


These are not the final criteria, but hopefully these give a flavor of
what we are considering.  Suggestions welcome.

We expect to routinely check these (e.g., with a webhook) to
ensure the badge stays current.


Potential criteria
==================

Here are some other potential criteria.
As the criteria become more mature we expect some criteria to move between
the "current" and "potential" list (in both directions).
In some cases these won't be in the "basic" criteria, but could instead
be part of some future "higher-level" badge.

*   General criteria:
    -   Commits reviewed.  There should be evidence that at least one other person (other than the committer) are normally reviewing commits.
    -   Roadmap exists.  There should be some information on where the project is going or not going, e.g., 
    -   Posted list of small tasks for new users
    -   Multiple contributors from more than one organization
    -   License statement in each file
    -   (Ideal) Copyright notice in each file, e.g., "Copyright [year project started] - [current year], [project founder] and the [project name] contributors."
*   Issue tracking (TODO: This must be different for big projects like the Linux kernel; it's not clear how to capture that.)
    -   Issue tracking for defects
    -   Issue tracking for requirements/enhancement requests
    -   "Bug/vulnerability report responsiveness, e.g., commitment to respond to any vulnerability report within (say) 14 days.  "
*   Quality
    -   Continuous integration: Automated test suite applied on each check-in, preferably across many platforms
    -   Automated test suite covers >=X% of source code (80% considered good, 100% ideal)
    -   When a bug is fixed, a regression test is normally added to the automated test suite to prevent its reoccurrence (ideally all)
    -   Documented test plan
    -   Coding standards (typically by pointing to something)
    -   Program can use the local version of system library/applications (so vulnerable ones easily replaced).  Many OSS programs are distributed with "convenience libraries" that are local copies of standard libraries (possibly forked).  However, if the program *must* use these local (forked) copies, then updating the "standard" libraries as a security update will leaved these additional copies still vulnerable. This is especially an issue for cloud-based systems (e.g., Heroku); if the cloud provider updates their "standard" libaries, but the program won't use them, then the updates don't actually help.  In some cases it's important to use the "other" version; the goal here is to make it *possible* to easily use the standard version. See, e.g., http://spot.livejournal.com/312320.html
*   Security
    -   "Announcement" mailing list for new versions (at least for security updates)
    -   All inputs checked against whitelist
    -   Privileges limited/minimized
    -   Attack surface documented & minimized
    -   "Automated regression test suite includes at least one check for rejection of invalid data for each input field"
    -   Developers contributing a majority of the software (over 50%) have learned how to develop secure software.
    -   Standard security advisory template and a pre-notification process (useful for big projects; see Xen project as an example).
*   Security analysis
    -   Current/past security review of code.
    -   Dependencies checked for known vulnerabilities (using an origin analyzer, e.g., Sonatype, Black Duck, Codenomicon AppScan, OWASP Dependency-Check)

In the future we might add some criteria where a project has to meet
some subset of them (e.g., meet at least 3 of 5 criteria).

Continuous integration, in particular, might move up.


Non-criteria
============

We will intentionally *not* require git or GitHub.
We do plan to create an "easy on-ramp" for projects using git on GitHub.

We will *not* add 100% branch coverage to the *basic* set of criteria.
Some projects (like SQLite) do achieve this, but for some projects
(such as the Linux kernel) this would exceptionally difficult to achieve.
Some higher/different related badge *might* add 100% branch coverage.

We do not plan to require an active user discussion; some highly mature
projects may have little activity.


Future plans
============

We currently plan to launch with a single badge level.
There may be multiple levels (bronze, silver, gold, platinum) or
other badges (with a prerequisite) later).

For more information
====================

See the "background" file which provides much more detail relating
to these criteria, including possible sources of criteria
and plans for how to implement the tool to implement these.

