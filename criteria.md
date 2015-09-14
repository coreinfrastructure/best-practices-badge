Basic Best Practices Criteria for Open Source Software (OSS) (version 0.2.0)
========================================================================

Introduction
============

This is a *draft* of proposed basic best practices
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
[more advanced badges](./other.md) later.
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
The key words "MUST", "MUST NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
[RFC 2119](https://tools.ietf.org/html/rfc2119).
MUST is an absolute requirement, and MUST NOT is an absolute prohibition.
The terms SHOULD and RECOMMENDED acknowledge that there
may exist valid reasons in particular circumstances to ignore a
particular criterion, but the full implications must be understood and
carefully weighed before choosing a different course, and that rationale
MUST be documented to acquire a badge.
Often a criterion is stated as something that SHOULD be done, or is
RECOMMENDED, because the costs or difficulties of doing so can sometimes
circumstances be high.
We assume that you are already familiar with
software development and running an OSS project;
if not, see introductory materials like
[*Producing Open Source Software* by Karl Fogel](http://producingoss.com/).


Current criteria: Basic Best Practices for OSS
==============================================

Here are the current (draft) criteria; it is certain to change.
The criteria marked with &#8224; are intended to be automatically testable
if the project is hosted on GitHub and follows standard conventions.
The [name] markings is the short name of each required criterion;
it is also the basis of the database table field name
(chaging "-" to "_") with the results.
In a few cases rationale is also included.

### OSS project basics

*Project website*

- The project MUST have a public website with a stable URL. [project-url]&#8224;
- It is RECOMMENDED that project websites use HTTPS, not HTTP.  Future versions of these criteria may make HTTPS a requirement. [project-url-https]&#8224;

*Basic project website content*

- The project website MUST succinctly describe what the software does (what problem does it solve?), in language that potential users can understand (e.g., it uses a minimum of jargon). [description]
- The project website MUST provide information on how to:
  - obtain,
  - provide feedback (as bug reports or enhancements),
  - and contribute to the sofware. [interact]
- The information on how to contribute MUST explain the contribution process (e.g., are pull requests used?) [contribution]
- The information on how to contribute SHOULD include the basic criteria for acceptable contributions (e.g., a reference to any required coding standard). [contribution-criteria]

*OSS license*

- License(s) MUST be posted in a standard location (e.g., as a top-level file named LICENSE or COPYING).  License filenames MAY be followed by an extension such as ".txt" or ".md" [license-location]&#8224;
- The software MUST be released as OSS; meaning licenses MUST be at least one of the following:
  - [an approved license by the Open Source Initiative (OSI)](http://opensource.org/licenses)
  - [a free license as approved by the Free Software Foundation (FSF)](http://www.gnu.org/licenses/license-list.html)
  - [a free license acceptable to Debian main](https://www.debian.org/legal/licenses/)
  - [a "good" license according to Fedora](https://fedoraproject.org/wiki/Licensing:Main?rd=Licensing). [oss-license]&#8224;
- It is RECOMMENDED that any required license(s) be OSI-approved. [oss-license-osi]&#8224;
- The software MAY also be licensed other ways (e.g., "GPLv2 or proprietary" is acceptable).
- *Note*: We intend for the automated tool to focus on identifying common OSS licenses such as:     [CC0](http://creativecommons.org/publicdomain/zero/1.0/), [MIT](http://opensource.org/licenses/MIT), [BSD 2-clause](http://opensource.org/licenses/BSD-2-Clause), [BSD 3-clause revised](http://opensource.org/licenses/BSD-3-Clause), [Apache 2.0](http://opensource.org/licenses/Apache-2.0), [Lesser GNU General Public License (LGPL)](http://opensource.org/licenses/lgpl-license), and the [GNU General Public License (GPL)](http://opensource.org/licenses/gpl-license).
- *Rationale*: These criteria are designed for OSS projects, so we need to ensure that they're only used where they apply.  Some projects are thought of as OSS yet are not actually released as OSS (e.g., they might not have any license, in which case the defaults of the country's legal system apply, or they might use a non-OSS license).  Unusual licenses can cause long-term problems for OSS projects and are more difficult for tools to handle.  We expect that that "higher-level" criteria would set a higher bar, e.g., that it *must* be released under an OSI-approved license.  

*Documentation*

- The project MUST provide basic documentation for the software in some media (such as text or video) that in aggregate covers:
  - how to install it
  - how to start it
  - how to use it (possibly with a tutorial using examples)
  - how to use it securely (e.g., what to do and what not to do) if that is an appropriate topic for the software.  The security documentation need not be long, since the software SHOULD be designed to be secure by default.  [documentation-basics]
- The project MUST include reference documentation that describes its interface. [documentation-interface]
- Hypertext links to non-project material MAY be used, as long as the linked-to information is available.

### Change control

*Public version-controlled source repository*

- The project MUST have a version-controlled source repository that is publicly readable. [repo-url]&#8224;
- This source repository MUST track what changes were made, who made the changes, and when the changes were made. [repo-track]&#8224;
- The public repository MUST include interim versions for review before release; it MUST NOT include only final releases. [repo-interim]
- It is RECOMMENDED that projects use common distributed version control software (e.g., git, though git is not specifically required).&#8224;
- Projects MAY use private (non-public) branches in specific cases while the change is not publicly released (e.g., for fixing vulnerabilities before the vulnerability is revealed to the public).
- *Rationale*:  This enables easy tracking and public review.  Some OSS projects do not use a version control system or do not provide public access to it. The lack of a public version control repository makes it unnecessarily difficult to contribute to a project and to track its progress in detail.

*Unique version numbering*

- The project MUST have a unique version number for each release intended to be used by users. [version-unique]
- The [Semantic Versioning (SemVer) format](http://semver.org) is RECOMMENDED for releases. [version-semver]
- Commit IDs (or similar) MAY be used as as version numbers. They are unique, but note that these can cause problems for users as they may not be able to determine  whether or not they're up-to-date.
- It is RECOMMENDED that git users apply tags to releases. [version-tags]&#8224;

*ChangeLog*

- The project MUST provide a "ChangeLog" with a human-readable summary of major changes for each release.  The ChangeLog MUST NOT be the output of the version control log of every change (e.g., the "git log" command is not a ChangeLog). [changelog]&#8224;
- The ChangeLog MUST include whether the new release fixes any known vulnerabilities. [changelog-vulns]
- The ChangeLog MAY be a separate file (e.g., "ChangeLog" or "changelog" optionally appended by ".txt", ".md", or ".html" extensions), or it MAY use version control system mechanisms such as the [GitHub Releases workflow](https://github.com/blog/1547-release-your-software).
- *Rationale*: ChangeLogs are important because they help users decide whether or not they will want to update (and what the impact would be), e.g., if the new release fixes vulnerabilities.

### Reporting

*Bug-reporting process*&#8224;

- If an issue tracker is used, please provide its URL. [report-url]
- It is RECOMMENDED that an issue tracker be used for tracking individual issues. [report-tracker]&#8224;
- The project MUST provide a process for users to submit bug reports (e.g., using an issue tracker or a mailing list). [report-process]&#8224;
- Developers MUST respond to most bug reports submitted in the last 2-12 months (inclusive); the response need not include a fix. [report-responses]&#8224;
- Developers SHOULD respond to most enhancement requests in the last 2-12 months (inclusive). Developers MAY choose not to respond. [enhancement-responses]&#8224;
- Reports and responses MUST be archived for later searching. [report-archive]&#8224;

*Vulnerability report process*

- The project MUST publish the process for reporting vulnerabilities on the project site (e.g., a clearly designated mailing address on https://PROJECTSITE/security, often security@SOMEWHERE); this MAY be the same as its bug reporting process. [vulnerability-report-process]&#8224;
- If private vulnerability reports are supported, the project MUST include how to send the information in a way that is kept private (e.g., a private defect report submitted on the web using TLS or an email encrypted using PGP). If private vulnerability reports are not supported this criterion is automatically met. [vulnerability-report-private]
- The project MUST provide an initial reply to a security vulnerability report sent to the project, on average, less than 7 days within the last 6 months.  (If a project is being spammed on its vulnerability report channel, it is okay to only count non-spam messages.) [vulnerability-report-response]


### Quality

*Working build system*

- Either the project MUST never need to be built or the project MUST provide a working build system that can automatically rebuild the software from source code.  A build system determines what actions need to occur to rebuild the software (and in what order), and then performs those steps. [build]&#8224;
- It is RECOMMENDED that common tools be used for this purpose (e.g., Maven, Ant, cmake, the autotools, make, or rake), in which case only the instructions to the build system are required (there's no requirement to teach people how to use common tools). [build-common-tools]&#8224;
- The project SHOULD be buildable using only OSS tools. [build-oss-tools]
- *Rationale*: If a project needs to be built but there is no working build system, then potential co-developers will not be able to easily contribute and many security analysis tools will be ineffective.

*Automated test suite*

- There MUST be at least one automated test suite. [test]
- A test suite SHOULD be invocable in a standard way for that language (e.g., "make check", "mvn test", and so on). [test-invocation]
-  It is RECOMMENDED that the test suite cover most (or ideally all) the code branches, input fields, and functionality [test-most]
- Systems MAY have multiple automated test suites (e.g., one that runs quickly, vs. another that is more thorough but requires special equipment).
- *Rationale*: Automated test suites immediately help detect a variety of problems.  A large test suite can find more problems, but even a small test suite can detect problems and provide a framework to build on.

*Tests are added for new functionality*

- There MUST be a general policy (formal or not) that when major new functionality is added, tests of that functionality SHOULD be added to an automated test suite. [tests-should-added]
- There MUST be evidence that such tests are being added in the most recent major changes to the project.  Major functionality would typically be mentioned in the ChangeLog.  Perfection is not required, merely evidence that tests are typically being added in practice. [tests-are-added]
- It is RECOMMENDED that this be *documented* in the instructions for change proposals, but even an informal rule is acceptable as long as the tests are being added in practice. [tests-documentated-added]

*Warning flags*

- The project MUST enable some compiler warnings (e.g. "-Wall"), a "safe" language mode (e.g., "use strict", "use warnings", or similar), and/or use a separate "linter" tool to look for code quality errors or common simple mistakes. [warnings]
- The project MUST address the issues that are found (by fixing them or marking them in the source code as false positives).  Ideally there would be no warnings, but a project MAY accept some warnings (typically less than 1 warning per 100 lines or less than 10 warnings). [warnings-fixed]
- It is RECOMMENDED that projects be maximally strict, but this is not always practical. [warnings-strict]
- This criterion is not required if there is no OSS tool that can implement this criterion in the selected language. [warnings-irrelevant]

### Security

*Secure development knowledge*

- At least one of the primary developers MUST know how to design secure software.  In particular, the developer must know the value of limiting the attack surface, why and how to do input input validation, the advantages of whitelists over blacklists in input validation, and the meaning of least privilege. [know-secure-design]
- At least one of the primary developers MUST know of common kinds of errors that lead to vulnerabilities in this kind of software, as well as at least one method to counter or mitigate each of them.  Examples (depending on the type of software) include SQL injection, OS injection, classic buffer overflow, cross-site scripting, missing authentication, and missing authorization.  See the [CWE/SANS top 25](http://cwe.mitre.org/top25/) or [OWASP Top 10](https://www.owasp.org/index.php/Category:OWASP_Top_Ten_Project) for commonly-used lists. [know-common-errors]

*Uses basic good cryptographic practices*

1.  Cryptographic protocols and algorithms used by default in the software AND the delivery mechanisms MUST be publicly published and reviewed by experts.  [crypto-published]
2.  Application software that is not itself a cryptographic system/library MUST NOT implement its own cryptographic functions, but MUST instead call on software specifically designed for the purpose.  [crypto-call]
3.  All functionality that depends on cryptography MUST be implementable using OSS because its specification meets the [*Open Standards Requirement for Software* by the Open Source Initiative](http://opensource.org/osr)  [crypto-oss]
4.  The default keylengths MUST meet NIST requirements through the year 2030. For example, symmetric keys must be at least 112 bits, factoring modulus must be at least 2048 bits, and elliptic curve must be at least 224 bits.  See <http://www.keylength.com> for a comparison of keylength recommendations from various organizations.  The software MUST be configurable so that it will reject smaller keylengths.  The software MAY allow smaller keylengths in some configurations (ideally it would not, since this allows downgrade attacks, but shorter keylengths may be necessary for interoperability.)  [crypto-keylength]
5.  Security mechanisms MUST NOT on depend cryptographic algorithms that are broken or have too-short key lengths (e.g., MD4, MD5, single DES, or RC4).  It is RECOMMENDED that SHA-1 not be used (we are well aware that git uses SHA-1).  Currently-recommended algorithms include AES and SHA-256/SHA-512.  Implementations SHOULD support multiple cryptographic algorithms, so users can quickly switch if one is broken.  [crypto-working]
6.  Any key agreement protocol SHOULD implement perfect forward secrecy so a session key derived from a set of long-term keys cannot be compromised if one of the long-term keys is compromised in the future.  [crypto-pfs]
7.  If passwords for later authentication are stored, they MUST be stored as iterated hashes with per-user salt.  [crypto-password-storage]
8.  All keys and nonces MUST be generated using cryptographically random functions, and *not* through non-cryptographically random functions. [crypto-random]

*Secured delivery against man-in-the-middle (MITM) attacks*

- The project MUST use a delivery mechanism that counters MITM attacks. Using https or ssh+scp is acceptable.  An even stronger mechanism is releasing the software with digitally signed packages, since that mitigates attacks on the distribution system, but this only works if the users can be confident that the public keys for signatures are correct *and* if the users will actually check the signature. [delivery-mitm]&#8224;
- A cryptographic hash (e.g., a sha1sum) MUST NOT be retrieved over http and used without checking for a cryptographic signature, since these hashes can be modified in transit. [delivery-unsigned]

*Publicly-known vulnerabilities fixed*

- There MUST be no unpatched vulnerabilities of medium or high severity that have been *publicly* known for more than 60 days.  The vulnerability must be patched and released by the project itself (patches may be developed elsewhere).  A vulnerability becomes publicly known (for this purpose) once it has a CVE with publicly released non-paywalled information (reported, for example, in the [National Vulnerability Database](https://nvd.nist.gov/)) or when the project has been informed *and* the information has been released to the public (possibly by the project).  A vulnerability is medium to high severity if its [CVSS 2.0](https://nvd.nist.gov/cvss.cfm) base score is 4 or higher. [vulnerabilities-fixed-60-days]&#8224;
- Projects SHOULD fix all critical vulnerabilities rapidly after they are reported. [vulnerabilities-critical-fixed]
- *Note*: this means that users might be left vulnerable to all attackers worldwide for up to 60 days.  This criterion is often much easier to meet than what Google recommends in [Rebooting responsible disclosure](http://googleonlinesecurity.blogspot.com/2010/07/rebooting-responsible-disclosure-focus.html), because Google recommends that the 60-day period start when the project is notified *even* if the report is not public.
- *Rationale*: We intentionally chose to start measurement from the time of public knowledge, and not from the time reported to the project, because this is much easier to measure and verify by those *outside* the project.

### Security analysis

*Static code analysis*

- At least one static code analysis tool MUST be applied to any proposed major production release of the software before its release.  A static code analysis tool examines the software code (as source code, intermediate code, or executable) without executing it with specific inputs.  For purposes of this criterion compiler warnings and "safe" language modes do not count as a static code analysis tool (these typically avoid deep analysis because speed is vital).  Examples of such static code analysis tools include cppcheck, the clang static analyzer, FindBugs (including FindSecurityBugs), PMD, Brakeman, [Coverity Quality Analyzer](https://scan.coverity.com/), and the HP Fortify Static Code Analyzer. [static-analysis]
- The analysis tool(s) MAY be focused on looking for security vulnerabilities, but this is not required.
- It is RECOMMENDED that the tool include rules or approaches to look for common vulnerabilities in the analyzed language or environment. [static-analysis-common-vulnerabilities]
- All confirmed medium and high severity exploitable vulnerabilities discovered with static code analysis MUST be fixed.  A vulnerability is medium to high severity if its [CVSS 2.0](https://nvd.nist.gov/cvss.cfm) is 4 or higher. [static-analysis-fixed]
- It is RECOMMENDED that static source code analysis occur on every commit or at least daily. [static-analysis-often]
- This criterion is not required if there is no OSS tool that can implement this criterion in the selected language. [static-analysis-irrelevant]

*Dynamic analysis*

- At least one dynamic analysis tool MUST be applied to any proposed major production release of the software before its release.  A dynamic analysis tool examines the software by executing it with specific inputs.  For example, the project may use a fuzzing tool (e.g., [American Fuzzy Lop](http://lcamtuf.coredump.cx/afl/)) or a web application scanner (e.g., [OWASP ZAP](https://www.owasp.org/index.php/OWASP_Zed_Attack_Proxy_Project) or [w3af](http://w3af.org/)). For purposes of this criterion the dynamic analysis tool MUST vary the inputs in some way to look for various kinds of problems *or* be an automated test suite with at least 80% branch coverage. [dynamic-analysis]
- It is RECOMMENDED that if the software is application-level software written using a memory-unsafe language (such as C or C++) then at least one tool to detect memory safety problems MUST be used during at least one dynamic tool use, e.g., Address Sanitizer (ASAN) or valgrind. If the software is not application-level, or is not in a memory-unsafe language, then this criterion is automatically met.  [dynamic-analysis-unsafe]
- It is RECOMMENDED that the software include many run-time assertions that are checked during dynamic analysis. [dynamic-analysis-enable-assertions]
- The analysis tool(s) MAY be focused on looking for security vulnerabilities, but this is not required.
- All confirmed medium and high severity exploitable vulnerabilities discovered with dynamic code analysis MUST be fixed.  A vulnerability is medium to high severity if its [CVSS 2.0](https://nvd.nist.gov/cvss.cfm) base score is 4 or higher. [dynamic-analysis-fixed]
- *Rationale*: Static source code analysis and dynamic analysis tend to find different kinds of defects (including defects that lead to vulnerabilities), so combining them is more likely to be effective.


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

We have chosen to use self-certification, because this makes it
possible for a large number of projects (even small ones) to
participate.  There's a risk that projects may make false claims,
but we think the risk is small, and in any case we require that
projects document *why* they think they meet the criteria
(so users can quickly see the project's rationale).


Improving the criteria
======================

We are hoping to get good suggestions and feedback from the public;
please contribute!

We currently plan to launch with a single badge level (once it is ready).
There may eventually be multiple levels (bronze, silver, gold) or
other badges (with a prerequisite) later.
See [other](./other.md) for more information.

You may also want to see the "[background](./background.md)" file
for more information about these criteria,
and the "[implementation](./implementation.md)" notes
about the BadgeApp application.

