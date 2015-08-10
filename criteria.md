Basic Best Practices Criteria for Open Source Software (OSS) (version 0.0.2)
========================================================================

Introduction
============

This *early* *draft* identifies proposed basic best practices criteria
for open source software (OSS).
The intent is to create a "badging" program in which OSS projects
that follow these best practices can voluntarily self-certify and show a badge.
A tool will automatically evaluate criteria in some cases.

There is no set of practices that can guarantee that software
will never have defects or vulnerabilities;
even formal methods can fail if the specifications or assumptions are wrong.
However, following best practices can help improve the results
of OSS projects.
For example, some practices enable multi-person review before release
that can help find otherwise hard-to-find vulnerabilities.
These best practices were created to (1) encourage OSS projects to
follow best practices and (2) help users know which projects
are following best practices.

We are currently focused on identifying *basic* best practices
that well-run OSS projects typically already follow.
We are capturing other practices so that we can create
more advanced badges later.
The basic best practices, and the more detailed criteria
specifically defining them, are inspired by a variety of sources.
See the separate "[background](./background.md)" page for more information.

We expect that these practices and their detailed criteria will be updated,
even after badges are released.
Thus, criteria (and badges) probably will have a year identifier
and will age out after a year or two. 
We expect well-run OSS projects to trivially update,
so this short badge life should not be a barrier.

This version of the criteria is *NOT* endorsed by anyone;
we are releasing this very early version so that we can get feedback.
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
We assume that you are already familiar with
software development and running an OSS project;
if not, see introductory materials like
[*Producing Open Source Software* by Karl Fogel](http://producingoss.com/).


Current criteria: Basic Best Practices for OSS
==============================================

Here is the current (draft) criteria; it is certain to change.
The ones with (AUTO) are intended to be automatically testable
if the project is hosted on GitHub and follows standard conventions.


*   **OSS project basics:**
    -   *Project website* (AUTO).  The project MUST have a public website with a stable URL. It is RECOMMENDED that projects use https, not http; future versions of these criteria may make https a requirement.
    -   *Project website has basic content*.  The project website MUST succinctly describe what the software does (what problem does it solve?), in language that potential users can understand (e.g., it uses a minimum of jargon). It MUST also provides information on how to get the software, how to send feedback (as bug reports or feature requests), and how to contribute.  The information on how to contribute MUST explain the contribution process (e.g., are pull requests used?) and SHOULD include the basic criteria for acceptable contributions (e.g., a reference to any required coding standard).
    -   *OSS license* (AUTO).  The license(s) MUST be posted in a standard place, e.g., as a top-level file named LICENSE or COPYING optionally followed by an extension such as ".txt" or ".md".  The software MUST be released as OSS; this means that the required licenses MUST be at least one of the following: [an approved license by the Open Source Initiative (OSI)](http://opensource.org/licenses), a [free license as approved by the Free Software Foundation (FSF)](http://www.gnu.org/licenses/license-list.html), [a free license acceptable to Debian main](https://www.debian.org/legal/licenses/), or [a "good" license according to Fedora](https://fedoraproject.org/wiki/Licensing:Main?rd=Licensing).  The required license(s) SHOULD be OSI-approved.  The software *may* also be licensed other ways (e.g., "GPLv2 or proprietary" is acceptable).  We intend for the automated tool to focus on identifying common OSS licenses such as the following: [CC0](http://creativecommons.org/publicdomain/zero/1.0/), [MIT](http://opensource.org/licenses/MIT), [BSD 2-clause](http://opensource.org/licenses/BSD-2-Clause), [BSD 3-clause revised](http://opensource.org/licenses/BSD-3-Clause), [Apache 2.0](http://opensource.org/licenses/Apache-2.0), [Lesser GNU General Public License (LGPL)](http://opensource.org/licenses/lgpl-license), and the [GNU General Public License (GPL)](http://opensource.org/licenses/gpl-license). Unusual licenses can cause long-term problems for OSS projects and are more difficult for tools to handle.  We expect that that "higher-level" criteria would set a higher bar, e.g., that it *must* be an OSI-approved license.
    -   *Basic Documentation*.  The project MUST include or refer to basic documentation on how to install it, start it, and use it (possibly with a tutorial using examples).  It MUST also include reference documentation that describes its interface.  The documentation MUST discuss how to use the software securely (e.g., what to do and what not to do) if that is an appropriate topic for the software.  The security discussion (if any) need not be long, since the software SHOULD be designed to be secure by default.  Hypertext links to non-project material is fine, as long as it is available.
*   **Change control:**
    -   *Public version-controlled source repository* (AUTO). The project MUST have a version-controlled source repository that is publicly readable.  This repository MUST track what changes were made, who made the changes, and when the changes were made.  The public repository MUST NOT include only final releases; it MUST release interim versions for review before release.  This enables easy tracking and public review. The project doesn't need to use git, although that is a common implementation, and it is RECOMMENDED that projects use common distributed version control software such as git.  Some OSS projects do not use a version control system or do not provide public access to it, but the lack of a public version control repository makes it unnecessarily difficult to contribute to a project and to track its progress in detail.  Projects MAY use private (non-public) branches in specific cases while the change is not publicly released, e.g., for fixing vulnerabilities before the vulnerability is revealed to the public.
    -   *Issue/bug tracking and reporting process* (AUTO).  There MUST be a process (e.g., using an issue tracker or a mailing list) by which users can directly submit issues/bugs and developers will respond. It MUST be archived for later searching.  There MUST be responses to bug reports, connected to them in some way; it is okay if enhancements aren't responded to.  It is RECOMMENDED that an issue tracker be used for tracking individual issues.
    -   *Unique version numbering* (AUTO).  The project MUST have a unique version number for each release intended to be used by users.  The [Semantic Versioning (SemVer) format](http://semver.org) is RECOMMENDED for releases.  It is RECOMMENDED that git users apply tags to releases.  Commit id's (or similar) MAY be used as as version numbers, since they are unique, but note that these can cause problems for users (since users cannot determine as easily whether or not they're up-to-date).
    -   *ChangeLog* (AUTO). The project MUST provide a "ChangeLog" with a summary of major changes for each release.  ChangeLogs are important because they help users decide whether or not they will want to update (and what the impact would be).  This MAY be a separate ChangeLog file (typically "ChangeLog" or "changelog" optionally appended by ".txt", ".md", or ".html" extensions), or it MAY use the [GitHub Releases workflow](https://github.com/blog/1547-release-your-software).  Note that a ChangeLog MUST NOT be simply the output of the version control log (e.g., a "git log" command); it MUST be a human-readable summary.
*   **Quality:**
    -   *Working build system* (AUTO).  Either the project MUST never need to be built or the project MUST provide a working build system that can automatically rebuild the software.  A build system determines what actions MUST occur to rebuild the software (and in what order), and then perform those steps.  It is RECOMMENDED that common tools be used for this purpose (e.g., Maven, Ant, cmake, the autotools, make, rake), in which case only the instructions to the build system are required.  The project SHOULD be buildable using only OSS tools.   If a project needs to be built but there is no working build system, then potential co-developers will not be able to easily contribute and many security analysis tools will be ineffective.
    -   *Automated test suite* (AUTO).  There MUST be an automated test suite.  The test suite SHOULD be invocable in a standard way for that language (e.g., "make check", "mvn test", and so on).  Only a small test suite is required.  The test suite SHOULD cover most (or ideally all) the code branches, input fields, and functionality, but even a small test suite can detect problems and provide a framework to build on.
    -   *Warning flags*.  The project MUST enable some compiler warnings, a "safe" language mode (e.g., "use strict" or similar), and/or use a separate "linter" tool to look for code quality errors or common simple mistakes.  The project MUST address the issues that are found (by fixing them or marking them in the source code as false positives).  Ideally there would be no warnings, but a project MAY accept less than 1 warning per 1000 lines or less than 10 warnings.  It is RECOMMENDED that projects be maximally strict, but this is not always practical.  This criterion is not required if there is no OSS tool that can implement this criterion in the selected language.
*   **Security:**
    -   *Secured delivery against man-in-the-middle (MITM) attacks* (AUTO).   The project MUST use a delivery mechanism that counters MITM attacks. Using https or ssh+scp is acceptable.  An even stronger mechanism is releasing the software with digitally signed packages, since that mitigates attacks on the distribution system, but this only works if the users can be confident that the public keys for signatures are correct *and* if the users will actually check the signature.  A cryptographic hash (e.g., a sha1sum) that is only retrieved over http and not separately signed is *not* acceptable, since this can be modified in transit.
    -   *Vulnerability report process*.   The project MUST have some process for reporting vulnerabilities (e.g., a clearly designated mailing address on the project site, often security@SOMEWHERE).  If private vulnerability reports are supported, the project MUST include how to send the information in a way that is kept private (e.g., a private defect report submitted on the web using TLS or an email encrypted using PGP).
    -   *Initial vulnerability report responsiveness*.  The project MUST provide an initial reply to a security vulnerability report sent to the project, on average, less than 7 days within the last 6 months.  (If a project is being spammed on its vulnerability report channel, it is okay to only count non-spam messages.)
    -   *Patches up-to-date*.  There MUST be no unpatched vulnerabilities of medium or high severity that have been publicly known for more than 60 days.  The vulnerability must be patched and released by the project itself (patches may be developed elsewhere). The length of time here is somewhat arbitrary and is considered extremely long; it means that users will be left vulnerable to attackers worldwide for up to 60 days.  A vulnerability becomes publicly known (for this purpose) once it has a CVE with publicly released information (reported in, for example, the National Vulnerability Database) or when the project has been informed *and* the information has been released to the public (possibly by the project).  Note that projects SHOULD fix all critical vulnerabilities rapidly after they are reported; Google suggests that the upper bound should be 60 days from report until repair *even* when the report is private per  http://googleonlinesecurity.blogspot.com/2010/07/rebooting-responsible-disclosure-focus.html .  Note that this criterion only measures the time known to the public, not from the time that the project is informed, and thus in many cases this criterion is much easier to meet than Google's criterion.  We intentionally chose to start measurement from the time of public knowledge, and not from the time reported to the project, because this is much easier to measure and verify by those *outside* the project.  To determine if a vulnerability is medium to high severity, use https://nvd.nist.gov/cvss.cfm ; a CVSS 2.0 score of 4 or higher is considered medium to high severity (you can just use the CVSS base score for this purpose).
*   **Security analysis:**
    -   *Static analysis*.  At least one static analysis tool MUST be applied to the source code to look for defects, including vulnerabilities, and any discovered exploitable vulnerabilites MUST be fixed.  A static analysis tool examines the software without executing it with specific inputs.  For purposes of this criterion compiler warnings and "safe" language modes do not count as a static analysis tool (compilers are typically designed to avoid deep vulnerability analysis during compilation so that they can be focused on rapidly generating code).  Examples of such tools include [Coverity Quality Analyzer](https://scan.coverity.com/), HP Fortify Static Code Analyzer, the clang static analyzer, FindBugs, and PMD.  The analysis tool(s) MAY be focused on looking for security vulnerabilities, but this is not required.
    -   *Dynamic analysis*.  At least one dynamic analysis tool MUST be applied
 and any discovered exploitable vulnerabilities fixed.  A dynamic analysis tool examines the software by executing it with specific inputs.   Examples include fuzzing tools (e.g., American Fuzzy Lop) and web application scanner (e.g., [OWASP ZAP](https://www.owasp.org/index.php/OWASP_Zed_Attack_Proxy_Project) and [w3af](http://w3af.org/)). For purposes of this criterion the dynamic analysis tool MUST vary the inputs in some way to look for various kinds of problems *or* be an automated test suite with at least 80% branch coverage.  If the software is written using an memory-unsafe language such as C or C++, at least one tool to detect memory safety problems SHOULD be used during at least one dynamic tool use (e.g., ASAN/Address Sanitizer).  It is RECOMMENDED that the software include many run-time assertions that are checked during dynamic analysis.  The analysis tool(s) MAY be focused on looking for security vulnerabilities, but this is not required.


These are not the final criteria, but hopefully these give a flavor of
what we are considering.  Suggestions are welcome.

We expect to routinely check these (e.g., with a webhook) to
ensure the badge stays current.


Potential criteria
==================

Here are some other potential criteria.
As the criteria become more mature, we expect some criteria to move between
the "current" and "potential" list (in both directions).
In some cases, these won't be in the "basic" criteria but could instead
be part of some future "higher-level" badge.

*   General criteria:
    -   Commits reviewed.  There should be evidence that at least one other person (other than the committer) are normally reviewing commits.
    -   Roadmap exists.  There should be some information on where the project is going or not going.
    -   Posted list of small tasks for new users.
    -   Multiple contributors from more than one organization.
    -   License statement in each file (aka per-file licensing).
    -   (Ideal) Copyright notice in each file, e.g., "Copyright [year project started] - [current year], [project founder] and the [project name] contributors."
*   Issue tracking (This must be different for big projects like the Linux kernel; it is not clear how to capture that.):
    -   Issue tracking for defects.
    -   Issue tracking for requirements/enhancement requests.
    -   Bug/vulnerability report responsiveness, e.g., commitment to respond to any vulnerability report within (say) 14 days.
*   Quality:
    -   Continuous integration: Automated test suite applied on each check-in, preferably across many platforms.
    -   Automated test suite covers >=X% branches of source code (80% considered good).
    -   Automated test suite covers 100% of branches in source code.  We will *not* add 100% branch coverage to the *basic* set of criteria.  Some projects (like SQLite) do achieve this, but for some projects (such as the Linux kernel) this would be exceptionally difficult to achieve.  Some higher/different related badge *might* add 100% branch coverage.
    -   When a bug is fixed, a regression test is normally added to the automated test suite to prevent its reoccurrence (ideally all).
    -   Reproduceable build.  On rebuilding, the result should be bit-for-bit identical.
    -   Documented test plan.
    -   Coding standards (typically by pointing to something).
    -   Program can use the local version of system library/applications (so vulnerable ones easily replaced).  Many OSS programs are distributed with "convenience libraries" that are local copies of standard libraries (possibly forked).  However, if the program *must* use these local (forked) copies, then updating the "standard" libraries as a security update will leaved these additional copies still vulnerable. This is especially an issue for cloud-based systems (e.g., Heroku); if the cloud provider updates their "standard" libaries but the program won't use them, then the updates don't actually help.  In some cases it's important to use the "other" version; the goal here is to make it *possible* to easily use the standard version. See, e.g., http://spot.livejournal.com/312320.html .
*   Security:
    -   "Announcement" mailing list for new versions (at least for security updates).
    -   All inputs checked against whitelist (not a blacklist).
    -   Privileges limited/minimized.
    -   Attack surface documented and minimized.
    -   Automated regression test suite includes at least one check for rejection of invalid data for each input field.  Rationale: Many regression test suites check only for perfect data; attackers will instead provide invalid data, and programs need to protect themselves against it.
    -   If passwords are stored to allow users to log into the software, the passwords must be stored as iterated per-user salted cryptographic hashes (at least) and *not* in the clear or as simple hashes.
    -   Developers contributing a majority of the software (over 50%) have learned how to develop secure software.
    -   Standard security advisory template and a pre-notification process (useful for big projects; see Xen project as an example).
    -   All inputs from potentially untrusted sources are checked to ensure they are valid (a *whitelist*).  Invalid inputs are rejected.  Note that comparing against a list of "bad formats" (a *blacklist*) is not enough.  In particular, numbers are converted and checked if they are between their minimum and maximum (inclusive), and text strings are checked to ensure that they are valid text patterns.
    -   OWASP Application Security Verification Standard (ASVS).
    -   SANS' Securing Web Application Technologies (SWAT) criteria.
*   Security analysis:
    -   Current/past security review of the code.
    -   Dependencies (including embedded dependencies) are periodically checked for known vulnerabilities (using an origin analyzer, e.g., Sonatype, Black Duck, Codenomicon AppScan, OWASP Dependency-Check), and if they have known vulnerabilities, they are updated or verified as unexploitable.  It is acceptable if the components' vulnerability cannot be exploited, but this analysis is difficult and it is sometimes easier to simply update or fix the part.  Developers must periodically re-scan to look for newly found publicly known vulnerabilities in the components they use, since new vulnerabilities are continuously being discovered.

We are considering moving the criteria continuous integration
and reproduceable builds into the basic best practices criteria.

In the future we might add some criteria that a project has to meet
some subset of (e.g., it must meet at least 3 of 5 criteria).



Non-criteria
============

We plan to *not* require any specific products or services.
In particular, we plan to *not* require
proprietary tools or services,
since many [free software](http://www.gnu.org/philosophy/free-sw.en.html)
developers would reject such criteria.
Therefore, we will intentionally *not* require git or GitHub.
This also means that as new tools and capabilities become available,
projects can quickly switch to them without failing to meet any criteria.
However, the criteria will sometimes identify
common methods or ways of doing something
(especially if they are OSS) since that information
can help people understand and meet the criteria.
We do plan to create an "easy on-ramp" for projects using git on GitHub,
since that is a common case.

We do not plan to require active user discussion within a project.
Some highly mature projects rarely change and thus may have little activity.
We *do*, however, require that the project be responsive
if vulnerabilities are reported to the project (see above).


Future plans
============

We currently plan to launch with a single badge level.
There may be multiple levels (bronze, silver, gold, platinum) or
other badges (with a prerequisite) later.

For more information
====================

See the "[background](./background.md)" file
for more information about these criteria and the supporting tool.

