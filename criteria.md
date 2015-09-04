Basic Best Practices Criteria for Open Source Software (OSS) (version 0.1.0)
========================================================================

Introduction
============

This is an *early* *draft* of proposed basic best practices
for open source software (OSS) projects.
OSS projects that follow these best practices
will be able to voluntarily self-certify and show that they've
achieved a CII badge.
Projects can do this, at no cost,
by using a web application (BadgeApp)
to explain how they meet each best practice.

There is no set of practices that can guarantee that software
will never have defects or vulnerabilities;
even formal methods can fail if the specifications or assumptions are wrong.
However, following best practices can help improve the results
of OSS projects.
For example, some practices enable multi-person review before release
that can help find otherwise hard-to-find vulnerabilities.
These best practices were created to (1) encourage OSS projects to
follow best practices, (2) help new OSS projects discover what those
practices are, and (3) help users know which projects
are following best practices (so users can prefer such projects).

We are currently focused on identifying *basic* best practices
that well-run OSS projects typically already follow.
We are capturing other practices so that we can create
more advanced badges later.
The basic best practices, and the more detailed criteria
specifically defining them, are inspired by a variety of sources.
See the separate "[background](./background.md)" page for more information.

This version of the criteria is *NOT* endorsed by anyone;
we are releasing this very early version so that we can get feedback.
We expect that these practices and their detailed criteria will be updated,
even after badges are released.
Thus, criteria (and badges) probably will have a year identifier
and will age out after a year or two. 
We expect it will be easy to update the information,
so this relatively short badge life should not be a barrier.

Feedback is *very* welcome via the
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
The criteria marked with &#8224; are intended to be automatically testable
if the project is hosted on GitHub and follows standard conventions.
In a few cases rationale is also included.


*   **OSS project basics:**
    -   *Project website*.&#8224;  
        The project MUST have a public website with a stable URL. It is RECOMMENDED that projects use https, not http; future versions of these criteria may make https a requirement.
    -   *Project website has basic content*.  
        The project website MUST succinctly describe what the software does (what problem does it solve?), in language that potential users can understand (e.g., it uses a minimum of jargon). It MUST also provide information on (1) how to get the software, (2) how to send feedback (as bug reports or feature requests), and (3) how to contribute.  The information on how to contribute MUST explain the contribution process (e.g., are pull requests used?) and SHOULD include the basic criteria for acceptable contributions (e.g., a reference to any required coding standard).
    -   *OSS license*.&#8224;  
        The license(s) MUST be posted in a standard place, e.g., as a top-level file named LICENSE or COPYING optionally followed by an extension such as ".txt" or ".md".  The software MUST be released as OSS; this means that the required licenses MUST be at least one of the following: [an approved license by the Open Source Initiative (OSI)](http://opensource.org/licenses), a [free license as approved by the Free Software Foundation (FSF)](http://www.gnu.org/licenses/license-list.html), [a free license acceptable to Debian main](https://www.debian.org/legal/licenses/), or [a "good" license according to Fedora](https://fedoraproject.org/wiki/Licensing:Main?rd=Licensing).  It is RECOMMENDED that any required license(s) be OSI-approved.  The software MAY also be licensed other ways (e.g., "GPLv2 or proprietary" is acceptable).  We intend for the automated tool to focus on identifying common OSS licenses such as the following: [CC0](http://creativecommons.org/publicdomain/zero/1.0/), [MIT](http://opensource.org/licenses/MIT), [BSD 2-clause](http://opensource.org/licenses/BSD-2-Clause), [BSD 3-clause revised](http://opensource.org/licenses/BSD-3-Clause), [Apache 2.0](http://opensource.org/licenses/Apache-2.0), [Lesser GNU General Public License (LGPL)](http://opensource.org/licenses/lgpl-license), and the [GNU General Public License (GPL)](http://opensource.org/licenses/gpl-license). Unusual licenses can cause long-term problems for OSS projects and are more difficult for tools to handle.  We expect that that "higher-level" criteria would set a higher bar, e.g., that it *must* be an OSI-approved license.  Rationale: These criteria are designed for OSS projects, yet many projects are not actually released as OSS (e.g., they might not be released using an OSS license, or might use a non-OSS license).
    -   *Basic Documentation*.  
        The project MUST include or refer to basic documentation on how to install it, start it, and use it (possibly with a tutorial using examples).  It MUST also include reference documentation that describes its interface.  The documentation MUST discuss how to use the software securely (e.g., what to do and what not to do) if that is an appropriate topic for the software.  The security discussion (if any) need not be long, since the software SHOULD be designed to be secure by default.  Hypertext links to non-project material is fine, as long as it is available.
*   **Change control:**
    -   *Public version-controlled source repository*.&#8224;  
        The project MUST have a version-controlled source repository that is publicly readable.  This repository MUST track what changes were made, who made the changes, and when the changes were made.  The public repository MUST NOT include only final releases; it MUST release interim versions for review before release.  The project doesn't need to use git, although that is a common implementation, and it is RECOMMENDED that projects use common distributed version control software such as git.  Projects MAY use private (non-public) branches in specific cases while the change is not publicly released, e.g., for fixing vulnerabilities before the vulnerability is revealed to the public.  *Rationale*:  This enables easy tracking and public review.  Some OSS projects do not use a version control system or do not provide public access to it, but the lack of a public version control repository makes it unnecessarily difficult to contribute to a project and to track its progress in detail.
    -   *Bug reporting process*.&#8224;  
        There MUST be a process (e.g., using an issue tracker or a mailing list) for users to submit bug reports where developers will respond.  There MUST be responses to bug reports; it is okay if enhancements aren't responded to.  Reports and responses MUST be archived for later searching.  Ideally all bugs would get a response, but that is not required.  It is RECOMMENDED that an issue tracker be used for tracking individual issues.
    -   *Unique version numbering*.&#8224;  
        The project MUST have a unique version number for each release intended to be used by users.  The [Semantic Versioning (SemVer) format](http://semver.org) is RECOMMENDED for releases.  It is RECOMMENDED that git users apply tags to releases.  Commit id's (or similar) MAY be used as as version numbers, since they are unique, but note that these can cause problems for users (since users cannot determine as easily whether or not they're up-to-date).
    -   *ChangeLog*.&#8224;  
        The project MUST provide a "ChangeLog" with a human-readable summary of major changes for each release, including if the new release fixes any known vulnerabilities.  This MAY be a separate ChangeLog file (typically "ChangeLog" or "changelog" optionally appended by ".txt", ".md", or ".html" extensions), or it MAY use version control system mechanisms such as the [GitHub Releases workflow](https://github.com/blog/1547-release-your-software).  Note that a ChangeLog MUST NOT be simply the output of the version control log of every change (e.g., the "git log" command is not a ChangeLog); it MUST be a human-readable summary.  *Rationale*: ChangeLogs are important because they help users decide whether or not they will want to update (and what the impact would be), e.g., if the new release fixes vulnerabilities.
*   **Quality:**
    -   *Working build system*.&#8224;  
        Either the project MUST never need to be built or the project MUST provide a working build system that can automatically rebuild the software.  A build system determines what actions MUST occur to rebuild the software (and in what order), and then perform those steps.  It is RECOMMENDED that common tools be used for this purpose (e.g., Maven, Ant, cmake, the autotools, make, or rake), in which case only the instructions to the build system are required (there's no requirement to teach people how to use common tools).  The project SHOULD be buildable using only OSS tools.   *Rationale*: If a project needs to be built but there is no working build system, then potential co-developers will not be able to easily contribute and many security analysis tools will be ineffective.
    -   *Automated test suite*.&#8224;  
        There MUST be at least one automated test suite.  A test suite SHOULD be invocable in a standard way for that language (e.g., "make check", "mvn test", and so on).  Only a small test suite is required.  It is RECOMMENDED that the test suite cover most (or ideally all) the code branches, input fields, and functionality, but even a small test suite can detect problems and provide a framework to build on.  Some larger systems MAY have multiple automated test suites (e.g., one that runs quickly, vs. another that is more thorough but requires special equipment).
    -   *Tests are added for new functionality*.  
        There MUST be a general policy (formal or not) that when major new functionality is added, tests of that functionality SHOULD be added to an automated test suite.  There MUST be evidence that such tests are being added in the most recent major changes to the project.  It is RECOMMENDED that this be *documented* in the instructions for change proposals, but even an informal rule is acceptable as long as the tests are being added in practice.  Major functionality would typically be mentioned in the ChangeLog.  Perfection is not required, merely evidence that tests are typically being added in practice.
    -   *Warning flags*.  
        The project MUST enable some compiler warnings (e.g. "-Wall"), a "safe" language mode (e.g., "use strict", "use warnings", or similar), and/or use a separate "linter" tool to look for code quality errors or common simple mistakes.  The project MUST address the issues that are found (by fixing them or marking them in the source code as false positives).  Ideally there would be no warnings, but a project MAY accept some warnings (typically less than 1 warning per 100 lines or less than 10 warnings).  It is RECOMMENDED that projects be maximally strict, but this is not always practical.  This criterion is not required if there is no OSS tool that can implement this criterion in the selected language.
*   **Security:**
    -   *Uses basic good cryptographic practices*.  
        The cryptographic mechanisms used by the software, and its delivery mechanisms, implement the following basic good practices:  
            1.  Cryptographic protocols and algorithms used by default MUST be publicly published and reviewed by experts.  
            2.  Application software that is not itself a cryptographic system/library MUST NOT implement its own cryptographic functions, but MUST instead call on software specifically designed for the purpose.  
            3.  All functionality that depends on cryptography MUST be implementable using OSS because its specification meets the [*Open Standards Requirement for Software* by the Open Source Initiative](http://opensource.org/osr)  
            4.  The default keylengths MUST meet NIST requirements through the year 2030. For example, symmetric keys must be at least 112 bits, factoring modulus must be at least 2048 bits, and elliptic curve must be at least 224 bits.  See <http://www.keylength.com> for a comparison of keylength recommendations from various organizations.  The software MUST be configurable so that it will reject smaller keylengths.  The software MAY allow smaller keylengths in some configurations (ideally it would not, since this allows downgrade attacks, but shorter keylengths may be necessary for interoperability.)  
            5.  Any key agreement protocol MUST implement perfect forward secrecy where practical so a session key derived from a set of long-term keys cannot be compromised if one of the long-term keys is compromised in the future.  
            6.  Security mechanisms MUST NOT on depend cryptographic algorithms that are broken or have too-short key lengths (e.g., MD4, MD5, single DES, or RC4).  It is RECOMMENDED that SHA-1 not be used (we are well aware that git uses SHA-1).  Currently-recommended algorithms include AES and SHA-256/SHA-512.  Implementations SHOULD support multiple cryptographic algorithms, so users can quickly switch if one is broken.  
            7.  If passwords for later authentication are stored, they MUST be stored as iterated hashes with per-user salt.  
            8.  All keys and nonces MUST be generated using cryptographically random functions, and *not* through non-cryptographically random functions.
    -   *Secured delivery against man-in-the-middle (MITM) attacks*.&#8224;  
        The project MUST use a delivery mechanism that counters MITM attacks. Using https or ssh+scp is acceptable.  An even stronger mechanism is releasing the software with digitally signed packages, since that mitigates attacks on the distribution system, but this only works if the users can be confident that the public keys for signatures are correct *and* if the users will actually check the signature.  A cryptographic hash (e.g., a sha1sum) that is only retrieved over http and not separately signed is *not* acceptable, since this can be modified in transit.
    -   *Vulnerability report process*.   
        The project MUST publish the process for reporting vulnerabilities on the project site (e.g., a clearly designated mailing address on https://PROJECTSITE/security, often security@SOMEWHERE).  If private vulnerability reports are supported, the project MUST include how to send the information in a way that is kept private (e.g., a private defect report submitted on the web using TLS or an email encrypted using PGP).
    -   *Initial vulnerability report responsiveness*.  
        The project MUST provide an initial reply to a security vulnerability report sent to the project, on average, less than 7 days within the last 6 months.  (If a project is being spammed on its vulnerability report channel, it is okay to only count non-spam messages.)
    -   *Patches up-to-date*.&#8224;  
        There MUST be no unpatched vulnerabilities of medium or high severity that have been *publicly* known for more than 60 days.  The vulnerability must be patched and released by the project itself (patches may be developed elsewhere). Note that this means that users will be left vulnerable to all attackers worldwide for up to 60 days.  A vulnerability becomes publicly known (for this purpose) once it has a CVE with publicly released non-paywalled information (reported, for example, in the [National Vulnerability Database](https://nvd.nist.gov/)) or when the project has been informed *and* the information has been released to the public (possibly by the project).  Note that projects SHOULD fix all critical vulnerabilities rapidly after they are reported. This criterion is often much easier to meet than what Google recommends in [Rebooting responsible disclosure](http://googleonlinesecurity.blogspot.com/2010/07/rebooting-responsible-disclosure-focus.html), because Google recommends that the 60-day period start when the project is notified *even* if the report is not public. We intentionally chose to start measurement from the time of public knowledge, and not from the time reported to the project, because this is much easier to measure and verify by those *outside* the project.  A vulnerability is medium to high severity if its [CVSS 2.0](https://nvd.nist.gov/cvss.cfm) base score is 4 or higher.
*   **Security analysis:**
    -   *Static source code analysis*.  
        At least one static source code analysis tool MUST be applied to any proposed major production release of the software before its release.  All discovered medium and high severity exploitable vulnerabilities MUST be fixed.
A vulnerability is medium to high severity if its [CVSS 2.0](https://nvd.nist.gov/cvss.cfm) is 4 or higher.  A static source code analysis tool examines the software source code without executing it with specific inputs.  For purposes of this criterion compiler warnings and "safe" language modes do not count as a static source code analysis tool (these typically avoid deep analysis because speed is vital).  Examples of such static source code analysis tools include cppcheck, the clang static analyzer, FindBugs (including FindSecurityBugs), PMD, Brakeman, [Coverity Quality Analyzer](https://scan.coverity.com/), and the HP Fortify Static Code Analyzer.   The analysis tool(s) MAY be focused on looking for security vulnerabilities, but this is not required.  It is RECOMMENDED that static source code analysis occur on every commit, or at least daily.  This criterion is not required if there is no OSS tool that can implement this criterion in the selected language.  A vulnerability is medium to high severity if its [CVSS 2.0](https://nvd.nist.gov/cvss.cfm) base score is 4 or higher.
    -   *Dynamic analysis*.  
        At least one dynamic analysis tool MUST be applied to any proposed major production release of the software before its release. All discovered medium and high severity exploitable vulnerabilities MUST be fixed.  A dynamic analysis tool examines the software by executing it with specific inputs.  For example, the project may use a fuzzing tool (e.g., [American Fuzzy Lop](http://lcamtuf.coredump.cx/afl/)) or a web application scanner (e.g., [OWASP ZAP](https://www.owasp.org/index.php/OWASP_Zed_Attack_Proxy_Project) or [w3af](http://w3af.org/)). For purposes of this criterion the dynamic analysis tool MUST vary the inputs in some way to look for various kinds of problems *or* be an automated test suite with at least 80% branch coverage.   It is RECOMMENDED that if the software is application-level software written using a memory-unsafe language (such as C or C++) then at least one tool to detect memory safety problems MUST be used during at least one dynamic tool use, e.g., Address Sanitizer (ASAN) or valgrind.  It is RECOMMENDED that the software include many run-time assertions that are checked during dynamic analysis.  The analysis tool(s) MAY be focused on looking for security vulnerabilities, but this is not required.  A vulnerability is medium to high severity if its [CVSS 2.0](https://nvd.nist.gov/cvss.cfm) base score is 4 or higher.  *Rationale*: Static source code analysis and dynamic analysis tend to find different kinds of defects (including defects that lead to vulnerabilities), so combining them is more likely to be effective.


Potential future criteria
=========================

Here are some other potential criteria.
As the criteria become more mature, we expect some criteria to move between
the current criteria and these potential future criteria (in both directions).

We currently plan to launch with a single badge level (once it is ready).
There may eventually be multiple levels (bronze, silver, gold) or
other badges (with a prerequisite) later.
We are currently leaning towards using the Olympic system naming
(bronze, silver, gold) since these are widely known; the LEED naming
(with platinum at the top) is less well-known, and using the Olympic
naming would provide room for another (platinum) level if needed.
Then the "basic" level would be the same as a "bronze" level.

To help organize these potential criteria, they are currently grouped
in terms of a potential future silver, potential future gold, and
other potential criteria.
There is no guarantee that the final criteria will be the same,
or even grouped the same way.
This list of potential future criteria is even less mature than the
list of basic best practices; recommendations welcome.

Eventually these criteria will be worded per
[RFC 2119](https://tools.ietf.org/html/rfc2119).


Potential silver criteria
-------------------------

*   Achieve the lower (basic/bronze) badge.
*   Build and test:
    -   Continuous integration: Automated test suite applied on each check-in, preferably across many platforms.
    -   Whenever major new functionality is added to the program, tests of it are added to the automated test suite.  This needs to be *documented* in the instructions for change proposals, and there needs to be past evidence that such tests are being added in the most recent major changes.
    -   When a bug is fixed, a regression test is normally added to the automated test suite to prevent its reoccurrence (ideally all).
    -   Reproduceable build.  On rebuilding, the result should be bit-for-bit identical.
*   Code/build requirements:
    -   Coding standards / coding style guide (typically by pointing to something).  There are a number of coding standards that can be recommended for specific languages.  Widely-used coding standards that include ways to reduce the likelihood of defects (including vulnerabilities) might be especially helpful.  Projects can create their own coding standard by referring to an existing one and then adding their own additions or exceptions.  There are a number of secure coding standards, e.g., the SEI CERT's at https://www.securecoding.cert.org/
    -   Program can use the local version of system library/applications (so vulnerable ones easily replaced).  Many OSS programs are distributed with "convenience libraries" that are local copies of standard libraries (possibly forked).  However, if the program *must* use these local (forked) copies, then updating the "standard" libraries as a security update will leaved these additional copies still vulnerable. This is especially an issue for cloud-based systems (e.g., Heroku); if the cloud provider updates their "standard" libaries but the program won't use them, then the updates don't actually help.  In some cases it's important to use the "other" version; the goal here is to make it *possible* to easily use the standard version. See, e.g., http://spot.livejournal.com/312320.html .
*   Security analysis:
    -   Dependencies (including embedded dependencies) are periodically checked for known vulnerabilities (using an origin analyzer, e.g., Sonatype, Black Duck, Codenomicon AppScan, OWASP Dependency-Check), and if they have known vulnerabilities, they are updated or verified as unexploitable.  It is acceptable if the components' vulnerability cannot be exploited, but this analysis is difficult and it is sometimes easier to simply update or fix the part.  Developers must periodically re-scan to look for newly found publicly known vulnerabilities in the components they use, since new vulnerabilities are continuously being discovered.
*   Release:
    -   Releases MUST be cryptographically signed.  These may be implemented as signed git tags (using cryptographic digital signatures).  There MUST be a way for users to obtain the public keys used for signing so that they can verify the signature, and there MUST be a documented process explaining to users how they can verify the signature.
    -   Releases MUST be downloadable through a channel that both encrypts and authenticates (e.g., TLS).  That way, third parties will not be able to determine exactly what version is being downloaded, and this also provides some verification that the correct software is being downloaded from the site.


Potential gold criteria
-----------------------

*   Achieve the lower (silver) badge.
*   General criteria:
    -   Roadmap exists.  There should be some information on where the project is going or not going.
    -   Posted list of small tasks for new users.
    -   Multiple contributors from more than one organization.
    -   License statement in each file (aka per-file licensing).
    -   (Ideal) Copyright notice in each file, e.g., "Copyright [year project started] - [current year], [project founder] and the [project name] contributors."
*   Quality:
    -   Commits reviewed.  There should be evidence that at least one other person (other than the committer) are normally reviewing commits.
    -   Automated test suite covers 100% of branches in source code.  We will *not* add 100% branch coverage to the *basic* set of criteria.  Some projects (like SQLite) do achieve this, but for some projects (such as the Linux kernel) this would be exceptionally difficult to achieve.  Some higher/different related badge *might* add 100% branch coverage.


Potential other criteria
------------------------

*   Issue tracking (This must be different for big projects like the Linux kernel; it is not clear how to capture that.):
    -   Issue tracking for defects.
    -   Issue tracking for requirements/enhancement requests.
    -   Bug/vulnerability report responsiveness, e.g., commitment to respond to any vulnerability report within (say) 14 days.
    -   If this is a project fork, actively working to become sustainable by either growing its community *or* working to heal the fork (e.g., contribute to the mainline).
*   Quality:
    -   Automated test suite covers >=X% branches of source code (80% considered good).
    -   Documented test plan.
*   Security:
    -   "Announcement" mailing list for new versions (at least for security updates).
    -   All inputs from untrusted sources checked against whitelist (not a blacklist) and/or escaped before being transmitted to other users.
    -   Privileges limited/minimized.
    -   Attack surface documented and minimized.
    -   Automated regression test suite includes at least one check for rejection of invalid data for each input field.  Rationale: Many regression test suites check only for perfect data; attackers will instead provide invalid data, and programs need to protect themselves against it.
    -   If passwords are stored to allow users to log into the software, the passwords must be stored as iterated per-user salted cryptographic hashes (at least) and *not* in the clear or as simple hashes.
    -   Developers contributing a majority of the software (over 50%) have learned how to develop secure software.
    -   Standard security advisory template and a pre-notification process (useful for big projects; see Xen project as an example).
    -   All inputs from potentially untrusted sources are checked to ensure they are valid (a *whitelist*).  Invalid inputs are rejected.  Note that comparing against a list of "bad formats" (a *blacklist*) is not enough.  In particular, numbers are converted and checked if they are between their minimum and maximum (inclusive), and text strings are checked to ensure that they are valid text patterns.
    -   OWASP Application Security Verification Standard (ASVS).
    -   SANS' Securing Web Application Technologies (SWAT) criteria.
    -   Privacy requirements.  The distribution system does not reveal to third parties what software or version number is being distributed, or to who.  The distribution system does not require users to identify themselves nor does it perform passive machine fingerprinting.
*   Security analysis:
    -   Current/past security review of the code.
    -   Must have a process for rapidly fixing vulnerabilities and releasing the updated software.  Note that having a good test suite makes it easier to make changes and be confident the system still works.  Also note that OSS projects are often embedded in larger systems and projects cannot control the larger projects they are in.
    -   An automated test suite must achieve at least an aggregate 80% branch coverage (the goal is to cover a significant portion of the program; this can be a combination of unit tests and larger integration tests).

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
We will also not require or forbid any particular programming language
(though for some programming languages we may be able to make
some recommendations).
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

Uniquely identifying a project
==============================

One challenge is uniquely identifying a project.
Our rails application gives a unique id to each new project, so
we can certainly use that id to identify projects.
However, that doesn't help people who searching for the project
and do not already know that id.

The *real* name of a project, for our purposes, is the project URL.
This may be a project "front page" URL and/or the front URL for its repository.
Most projects have a human-readable name, but these names are not enough.
The same human-readable name can be used for many different projects
(including project forks), and the same project may go by many different names.
In many cases it will be useful to point to other names for the project
(e.g., the source package name in Debian, the package name in some
language-specific repository, or its name in OpenHub).
We expect that users will *not* be able to edit the URL in most cases,
since if they could, they might fool people into thinking they controlled
a project that they did not.

Thus, a badge would have its URL as its name, year range, and level/name
(once there is more than one).

We will probably implement some search mechanisms so that people can
enter common names and find projects.


Why have criteria?
==================

The paper [Open badges for education: what are the implications at the intersection of open systems and badging?](http://www.researchinlearningtechnology.net/index.php/rlt/article/view/23563)
identifies three general reasons for badging systems (all are valid for this):

1.  Badges as a motivator of behaviour.  We hope that by identifying best practices, we'll encourage projects to implement those best practices if they do not do them already.
2.  Badges as a pedagogical tool.  Some projects may not be aware of some of the best practices applied by others, or how they can be practically applied.  The badge will help them become aware of them and ways to implement them.
3.  Badges as a signifier or credential.  Potential users want to use projects that are applying best practices to consistently produce good results; badges make it easy for projects to signify that they are following best practices, and make it easy for users to see which projects are doing so.

We have chosen to use self-certification, because this makes it possible for a large number of projects (even small ones) to participate.  There's a risk that projects may make false claims, but we think the risk is small, and in any case we require that projects document *why* they think they meet the criteria (so users can quickly see the project's rationale).


Improving the criteria
======================

We are hoping to get good suggestions and feedback from the public;
please contribute!

See the "[background](./background.md)" file
for more information about these criteria and the supporting tool,
including sources we've considered.

