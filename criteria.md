Basic Best Practices Criteria for Open Source Software (OSS) (version 0.0.2)
========================================================================

Introduction
============

This *early* *draft* identifies proposed basic best practices criteria
for open source software (OSS).
The intent is to create a "badging" program where OSS projects
that follow these best practices can voluntarily self-certify and show a badge.
A tool will automatically evaluate some criteria in some cases.

No practice or set of practices guarantees that software will have absolutely
no defects or no vulnerabilities;
even formal methods can fail if the specification is wrong.
However, following best practices can help.
For example, some practices enable multi-person review before release
that can help find otherwise hard-to-find vulnerabilities.
These best practices were created to encourage OSS projects to
follow best practices, and to help users know which projects
are following best practices.

We are currently focused on identifying *basic* best practices
that well-run OSS projects typically already follow.
We are capturing other practices so we can create more advanced badges later.
The basic best practices, and the more detailed criteria
specifically defining them, are inspired by a variety of sources;
see the separate "background" page for more information.

We expect that these practices and their detailed criteria will be updated,
even after badges are released.
Thus, criteria (and badges) will probably have a year identifier
and age out after a year or two. 
We expect well-run OSS projects to trivially update,
so this short badge life should not be a barrier.

This version of the criteria is *NOT* endorsed by anyone;
we are releasing this very early version so we can get feedback.
Feedback is welcome via the
[GitHub site as issues or pull requests](https://github.com/linuxfoundation/cii-best-practices-badge).
There is also a
[mailing list for general discussion](https://lists.coreinfrastructure.org/mailman/listinfo/cii-badges).

Below are the current (draft) criteria, potential criteria,
non-criteria, future plans, and where to get more information.
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
[RFC 2119](https://tools.ietf.org/html/rfc2119).

Current criteria: Basic Best Practices for OSS
==============================================

Here is the current (draft) criteria; it is certain to change.
The ones with (AUTO) are intended to be automatically testable
if the project is hosted on GitHub and follows standard conventions.


*   **OSS project basics**
    -   *Project website* (AUTO).  The project MUST have a public website with a stable URL. It is RECOMMENDED that projects use https, not http; future versions of these criteria may make https a requirement.
    -   *Project website has basic content*.  The project website MUST succinctly describe what the software does (what problem does it solve), in language that potential users could understand (e.g., it uses a minimum of jargon). It MUST also provides information on how to get the software, send feedback (as bug reports or feature requests), and contribute.
    -   *OSS license* (AUTO).  The license MUST posted in a standard place, e.g., as a top-level file named LICENSE or COPYING optionally followed by .txt or .md.  The required license(s) MUST be approved by at least one of OSI, FSF, Debian, or Fedora.  The required license(s) SHOULD be OSI-approved.  The software *may* also be licensed other ways (e.g., "GPLv2 or proprietary" is okay).  We intend for the automated tool to focus on standard, common licenses such as MIT, 2-clause BSD, 3-clause revised BSD, MIT, Apache 2.0, LGPL, or GPL; unusual licenses cause long-term problems for OSS projects.  We expect that that "higher-level" criteria would set a higher bar, e.g., that it *must* be an OSI-approved license.
    -   *Basic Documentation*.  The project MUST include or refer to basic documentation on how to install it, start it, and use it (possibly with a tutorial using examples).  It MUST also include reference documentation that describes its interface.  The documentation discusses how to use the software securely where appropriate (e.g., what to do and what not to do).  The security discussion (if any) need not be long, since the software SHOULD be designed to be secure by default.  Hypertext links to non-project material is fine, as long as it is available.
*   **Change control**
    -   *Public version-controlled source repository* (AUTO). The project MUST have a version-controlled source repository that is publicly readable.  This repository MUST track who made what changes when, and it MUST include intermediate results for review (not just final releases).  This enables easy tracking and public review. The project doesn't need to use git, though that is a common implementation, and it is RECOMMENDED that projects use common distributed version control software such as git.  Some OSS projects do not use a version control system, or do not provide public access to it, but the lack of a public version control repository makes it unnecessarily difficult to contribute to a project and to track its progress (e.g., to see who is contributing what and what has changed over time).  Projects MAY use private (non-public) branches while the change is not publicly released, e.g., for fixing vulnerabilities before the vulnerability is revealed to the public.
    -   *Issue/bug tracking and reporting process* (AUTO).  There MUST be a process (e.g., using an issue tracker or mailing list) where users can directly submit issues/bugs and developers will respond. It MUST be archived for later searching.  There MUST be responses to bug reports, connected to them in some way; it's okay if enhancements aren't responded to.  It is RECOMMENDED that an issue tracker be used for tracking individual issues.
    -   *Unique version numbering* (AUTO).  The project MUST have a unique version number for each release intended to be used by users.  The [Semantic Versioning (SemVer) format](http://semver.org) is RECOMMENDED for releases.  It is RECOMMENDED that git users apply tags to releases.  Commit id's (or similar) MAY be used as as version numbers, since they are unique, but note that these can cause problems for users (since users cannot determine if they're up-to-date as easily).
    -   *ChangeLog* (AUTO). The project MUST provide a "ChangeLog" with a summary of major changes for each release.  ChangeLogs are important because they help users decide whether or not they will want to update (and what the impact would be).  This MAY be a separate ChangeLog file (typically "ChangeLog" or "changelog" optionally appended by ".txt", ".md", or ".html") or it MAY use the [GitHub "Releases" workflow](https://github.com/blog/1547-release-your-software).  Note that a ChangeLog MUST NOT be simply the output of the version control log (e.g., "git log"); it MUST be a human-readable *summary*.
*   **Quality**
    -   *Working build system* (AUTO).  Either the project MUST never need to be built, or the project MUST provide working build system that can automatically rebuild the software.  A build system determines what actions MUST occur to rebuild the software (and in what order), and then perform those steps.  It is strongly *recommended* that common tools be used for this purpose (e.g., Maven, Ant, cmake, the autotools, make, rake).  The project SHOULD be buildable using only OSS tools.   If a project needs to be built, but there is no working build system, then potential co-developers will not be able to easily contribute and many security analysis tools will be ineffective.
    -   *Automated test suite* (AUTO).  There MUST be at least a small automated test suite.  The test suite SHOULD be invocable in a standard way for that language (e.g., "make check", "mvn test", and so on).  The test suite SHOULD cover most (or ideally all) the code branches, input fields, and functionality, but even a small test suite can detect problems, and a small test suite provides a framework to build on.
    -   *Warning flags*.  The project MUST enable some compiler warnings, a "safe" language mode (e.g., "use strict"), and/or use a separate "linter" tool to look for code quality errors or common simple mistakes, and then address those issues.  Ideally there would be no warnings, but a project MAY accept less than 1 warning per 1000 lines or less than 10 warnings.  It is RECOMMENDED that projects be maximally strict, but this is not always practical.  This criteria is not required if there is no OSS tool that can implement this criteria in the selected language.
*   **Security**
    -   *Secured delivery against man-in-the-middle (MITM) attacks* (AUTO).   The project MUST use a delivery mechanism that counters MITM attacks. Using https or ssh+scp is acceptable.  An even stronger mechanism is releasing the software with digitally signed packages, since that mitigates attacks on the distribution system, but this only works if the users can be confident that the public keys for signature are correct *and* if the users will actually check the signature.  A sha1sum that is only retrieved over http (and not separately signed) is *not* acceptable, since these can be modified in transit.
    -   *Vulnerability report process*.   The project MUST have some process for reporting vulnerabilities (e.g., a clearly designated mailing address on the project site, often security@SOMEWHERE).  If private vulnerability reports are supported, the project MUST include how to send the information in a way that is kept private (e.g., a private defect report submitted on the web using TLS, or an email encrypted using PGP).
    -   *Initial vulnerability report responsiveness*.  The project MUST provide an initial reply to a security vulnerability report sent to the project, on average, less than 7 days within the last 6 months.  (If a project is being spammed on its vulnerability report channel, it's okay to only count non-spam messages.)
    -   *Patches up-to-date*.  There MUST be no unpatched vulnerabilities of medium or high severity that have been publicly known for more than 60 days.  The vulnerability must be patched and released by the project itself (patches may be developed elsewhere). The length of time here is somewhat arbitrary and is considered extremely long; it means that users will be left vulnerable to attackers worldwide for up to 60 days.  A vulnerability becomes publicly known (for this purpose) once it has a CVE with publicly-released information (reported in, for example, the National Vulnerability Database) or when the project has been informed *and* the information has been released to the public (possibly by the project).  Note that projects SHOULD fix all critical vulnerabilities rapidly after they are reported; Google suggests that the upper bound should be 60 days from report until repair *even* when the report is private per  http://googleonlinesecurity.blogspot.com/2010/07/rebooting-responsible-disclosure-focus.html .  Note that this criteria only measures the time known to the public, not from the time that the project is informed, and thus in many cases this criteria is much easier to meet than Google's criteria.  We intentionally chose to start measurement from the time of public knowneldge, and not from the time reported to the project, because this is much easier to measure and verify by those *outside* the project.  For "medium to high severity" use https://nvd.nist.gov/cvss.cfm ; a CVSS 2.0 score of 4 or higher is medium to high severity (you can use just the CVSS base score for this purpose).
*   **Security analysis**
    -   *Static analysis*.  At least one static analysis tool MUST be applied to the source code to look for defects, including vulnerabilities, & any discovered exploitable vulnerabilites MUST be fixed (e.g., Coverity, Fortify, clang static analyzer, etc.).  A static analysis tool examines the software without executing it with specific inputs.  The analysis tool(s) MAY be focused on looking for security vulnerabilities, but this is not required.
    -   *Dynamic analysis*.  At least one dynamic analysis tool MUST be applied & any discovered exploitable vulnerabilities fixed (e.g., fuzzing, web application scanner).  A dynamic analysis tool examines the software by executing it with specific inputs.  For purposes of this criteria the dynamic analysis tool MUST vary the inputs in some way to look for various kinds of problems *or* be an automated test suite with at least 80% branch coverage.  If programmed using an memory-unsafe language such as C or C++, at least one tool to detect memory safety problems SHOULD be used during at least one dynamic tool use (e.g., ASAN/Address Sanitizer).  We *recommend* including a number of rigorous "can't happen" assertions in the code that are checked during dynamic analysis.  The analysis tool(s) MAY be focused on looking for security vulnerabilities, but this is not required.


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
    -   License statement in each file (aka "per-file licensing")
    -   (Ideal) Copyright notice in each file, e.g., "Copyright [year project started] - [current year], [project founder] and the [project name] contributors."
*   Issue tracking (TODO: This must be different for big projects like the Linux kernel; it's not clear how to capture that.)
    -   Issue tracking for defects
    -   Issue tracking for requirements/enhancement requests
    -   Bug/vulnerability report responsiveness, e.g., commitment to respond to any vulnerability report within (say) 14 days.
*   Quality
    -   Continuous integration: Automated test suite applied on each check-in, preferably across many platforms
    -   Automated test suite covers >=X% branches of source code (80% considered good)
    -   Automated test suite covers 100% of branches in source code.  We will *not* add 100% branch coverage to the *basic* set of criteria.  Some projects (like SQLite) do achieve this, but for some projects (such as the Linux kernel) this would exceptionally difficult to achieve.  Some higher/different related badge *might* add 100% branch coverage.
    -   When a bug is fixed, a regression test is normally added to the automated test suite to prevent its reoccurrence (ideally all)
    -   Reproduceable build.  On rebuilding, the result should be bit-for-bit identical.
    -   Documented test plan
    -   Coding standards (typically by pointing to something)
    -   Program can use the local version of system library/applications (so vulnerable ones easily replaced).  Many OSS programs are distributed with "convenience libraries" that are local copies of standard libraries (possibly forked).  However, if the program *must* use these local (forked) copies, then updating the "standard" libraries as a security update will leaved these additional copies still vulnerable. This is especially an issue for cloud-based systems (e.g., Heroku); if the cloud provider updates their "standard" libaries, but the program won't use them, then the updates don't actually help.  In some cases it's important to use the "other" version; the goal here is to make it *possible* to easily use the standard version. See, e.g., http://spot.livejournal.com/312320.html
*   Security
    -   "Announcement" mailing list for new versions (at least for security updates)
    -   All inputs checked against whitelist (not a blacklist)
    -   Privileges limited/minimized
    -   Attack surface documented & minimized
    -   Automated regression test suite includes at least one check for rejection of invalid data for each input field.  Rationale: Many regression test suites only check for perfect data; attackers will instead provide invalid data, and programs need to protect themselves against it.
    -   If passwords are stored to allow users to log into the software, the passwords must be stored as interated per-user salted cryptographic hashes (at least).
    -   Developers contributing a majority of the software (over 50%) have learned how to develop secure software.
    -   Standard security advisory template and a pre-notification process (useful for big projects; see Xen project as an example).
    -   All inputs from potentially-untrusted sources are checked to ensure they are valid (a "whitelist").  Invalid inputs are rejected.  Note that comparing against a list of "bad formats" (a "blacklist") is not enough.  In particular, numbers are converted and checked if they are between their minimum and maximum (inclusive), and text strings are checked to ensure that they are valid text patterns.
    -   SANS' Securing Web Application Technologies (SWAT) criteria
*   Security analysis
    -   Current/past security review of code.
    -   Dependencies (including embedded dependencies) are periodically checked for known vulnerabilities (using an origin analyzer, e.g., Sonatype, Black Duck, Codenomicon AppScan, OWASP Dependency-Check), and if they have known vulnerabilities, they are updated or verified as unexploitable.  It is acceptable if the components' vulnerability cannot be exploited, but this analysis is difficult and it is sometimes easier to simply update or fix the part.  Developers must periodically re-scan to look for newly-found publicly-known vulnerabilities in the components they use, since new vulnerabilities are continuously being discovered.

In the future we might add some criteria where a project has to meet
some subset of them (e.g., meet at least 3 of 5 criteria).

Continuous integration, in particular, might move up.


Non-criteria
============

We plan to *not* require any specific products or services.
In particular, we plan to *not* require
proprietary tools or services,
since many Free software developers would reject such criteria.
Therefore, we will intentionally *not* require git or GitHub.
This also means that as new tools and capabilities become available,
projects can quickly switch to them without failing to meet any criteria.
However, the criteria will sometimes identify
common methods or ways of doing something
(especially if they are OSS) since that information
an help help people understand and meet the criteria.
We do plan to create an "easy on-ramp" for projects using git on GitHub,
since that is a common case.

We do not plan to require active user discussion; some highly mature
projects rarely change and thus may have little activity.


Future plans
============

We currently plan to launch with a single badge level.
There may be multiple levels (bronze, silver, gold, platinum) or
other badges (with a prerequisite) later.

For more information
====================

See the "[background](./background.md)" file
for more information about these criteria and the supporting tool.

