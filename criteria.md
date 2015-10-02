Basic Best Practices Criteria for Open Source Software (OSS) (version 0.2.0)
========================================================================

Introduction
============

This is a *draft* of proposed basic best practices
for open source software (OSS) projects.
OSS projects that follow these best practices
will be able to voluntarily self-certify and show that they've
achieved a Core Infrastructure Initiative (CII) badge.
Projects can do this, at no cost,
by using a web application (BadgeApp)
to explain how they meet these practices and their detailed criteria.

There is no set of practices that can guarantee that software
will never have defects or vulnerabilities;
even formal methods can fail if the specifications or assumptions are wrong.
However, following best practices can help improve the results
of OSS projects.
For example, some practices enable multi-person review before release
that can help find otherwise hard-to-find vulnerabilities.

These best practices have been created to:

1. encourage OSS projects to follow best practices,
1. help new OSS projects discover what those practices are, and
1. help users know which projects are following best practices (so users can prefer such projects).

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
and will phase out after a year or two. 
We expect it will be easy to update the information,
so this relatively short badge life should not be a barrier.

Feedback is *very* welcome via the
[GitHub site as issues or pull requests](https://github.com/linuxfoundation/cii-best-practices-badge).
There is also a
[mailing list for general discussion](https://lists.coreinfrastructure.org/mailman/listinfo/cii-badges).

Below are the current *draft* criteria, potential criteria,
non-criteria, future plans, and where to get more information.
The key words "MUST", "MUST NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED",  and "MAY"
in this document are to be interpreted as described in
[RFC 2119](https://tools.ietf.org/html/rfc2119), with a slight distinction
between SHOULD and RECOMMENDED:

- The term MUST is an absolute requirement, and MUST NOT
  is an absolute prohibition.
- The term SHOULD indicates a criterion that should be implemented, but
  valid reasons may exist to not do so in particular circumstances.
  The full implications must be considered,
  understood, and carefully weighed before choosing a different course.
- The term RECOMMENDED is used instead of SHOULD when the criterion must
  be considered, but valid reasons
  to not do so are even more common than for SHOULD.
- Often a criterion is stated as something that SHOULD be done, or is
  RECOMMENDED, because it may be difficult to implement or the costs
  to do so may be high.
- The term MAY provides one way something can be done, e.g.,
  to make it clear that the described implementation is acceptable.
- To obtain a badge, all MUST and MUST NOT criteria must be met, and all
  SHOULD and RECOMMENDED criteria must be met OR the rationale for
  not implementing the criterion must be documented.

We're experimenting with when justifications are required;
since the badge is self-asserted, it might be wise to require justifications
for all claims, so that others can review the truth of those claims.

We assume that you are already familiar with
software development and running an OSS project;
if not, see introductory materials such as
[*Producing Open Source Software* by Karl Fogel](http://producingoss.com/).


Current criteria: Basic Best Practices for OSS
==============================================

Here are the current *draft* criteria; it is certain to change.
The criteria marked with &#8224; are intended to be automatically testable
if the project is hosted on GitHub and follows standard conventions.
The criteria marked with * at the end may be not applicable or not required;
see their text for more information.
Text inside square brackets is the short name of the criterion.
In a few cases rationale is also included.

We expect that there will be a few other fields for the
project name, description, project URL, repository URL (which may be the
same as the project URL), and license(s).

### OSS project basics

*Project website*

- <a name="project-url"></a>The project MUST have a public website with a stable URL. <sup>[<a href="#project-url">project-url</a>]&#8224;</sup>
- <a name="project-url-https"></a>It is RECOMMENDED that project websites use HTTPS, not HTTP.  Future versions of these criteria may make HTTPS a requirement. <sup>[<a href="#project-url-https">project-url-https</a>]&#8224;</sup>

*Basic project website content*

- <a name="description-sufficient"></a>The project website MUST succinctly describe what the software does (what problem does it solve?), in language that potential users can understand (e.g., it uses minimal jargon). <sup>[<a href="#description-sufficient">description-sufficient</a>]</sup>
- The project website MUST provide information on how to:
  - obtain,
  - provide feedback (as bug reports or enhancements),
  - <a name="interact"></a>and contribute to the sofware. <sup>[<a href="#interact">interact</a>]</sup>
- <a name="contribution"></a>The information on how to contribute MUST explain the contribution process (e.g., are pull requests used?) <sup>[<a href="#contribution">contribution</a>]</sup>
- <a name="contribution-criteria"></a>The information on how to contribute SHOULD include the basic criteria for acceptable contributions (e.g., a reference to any required coding standard). <sup>[<a href="#contribution-criteria">contribution-criteria</a>]</sup>

*OSS license*

- <a name="license-location"></a>The project MUST post licence(s) in a standard location (e.g., as a top-level file named LICENSE or COPYING).  License filenames MAY be followed by an extension such as ".txt" or ".md" <sup>[<a href="#license-location">license-location</a>]&#8224;</sup>
- The software MUST be licensed as OSS.  For our purposes, this means that the license MUST be at least one of the following:
  - [an approved license by the Open Source Initiative (OSI)](http://opensource.org/licenses)
  - [a free license as approved by the Free Software Foundation (FSF)](http://www.gnu.org/licenses/license-list.html)
  - [a free license acceptable to Debian main](https://www.debian.org/legal/licenses/)
  - <a name="oss-license"></a>[a "good" license according to Fedora](https://fedoraproject.org/wiki/Licensing:Main?rd=Licensing). <sup>[<a href="#oss-license">oss-license</a>]&#8224;</sup>
- <a name="oss-license-osi"></a>It is RECOMMENDED that any required license(s) be [OSI-approved](http://opensource.org/licenses). <sup>[<a href="#oss-license-osi">oss-license-osi</a>]&#8224;</sup>
- The software MAY also be licensed other ways (e.g., "GPLv2 or proprietary" is acceptable).
- *Note*: We intend for the automated tool to focus on identifying common OSS licenses such as:     [CC0](http://creativecommons.org/publicdomain/zero/1.0/), [MIT](http://opensource.org/licenses/MIT), [BSD 2-clause](http://opensource.org/licenses/BSD-2-Clause), [BSD 3-clause revised](http://opensource.org/licenses/BSD-3-Clause), [Apache 2.0](http://opensource.org/licenses/Apache-2.0), [Lesser GNU General Public License (LGPL)](http://opensource.org/licenses/lgpl-license), and the [GNU General Public License (GPL)](http://opensource.org/licenses/gpl-license).
- *Rationale*: These criteria are designed for OSS projects, so we need to ensure that they're only used where they apply.  Some projects are thought of as OSS yet are not actually released as OSS (e.g., they might not have any license, in which case the defaults of the country's legal system apply, or they might use a non-OSS license).  Unusual licenses can cause long-term problems for OSS projects and are more difficult for tools to handle.  We expect that [more advanced badges](./other.md) would set a higher bar (e.g., that it *must* be released under an OSI-approved license).

*Documentation*

- The project MUST provide basic documentation for the software in some media (such as text or video) that includes:
  - how to install it,
  - how to start it,
  - how to use it (possibly with a tutorial using examples), and 
  - <a name="documentation-basics"></a>how to use it securely (e.g., what to do and what not to do) if that is an appropriate topic for the software.  The security documentation need not be long (it is better for the software to be designed to be secure by default).  <sup>[<a href="#documentation-basics">documentation-basics</a>]</sup>
- <a name="documentation-interface"></a>The project MUST include reference documentation that describes its interface. <sup>[<a href="#documentation-interface">documentation-interface</a>]</sup>
- The project MAY use hypertext links to non-project material as documentation, as long as the linked-to information is available and meets the requirements.

### Change control

*Public version-controlled source repository*

- <a name="repo-url"></a>The project MUST have a version-controlled source repository that is publicly readable and has a URL (the URL MAY be the same as the project URL). <sup>[<a href="#repo-url">repo-url</a>]&#8224;</sup>
- <a name="repo-track"></a>The source repository MUST track what changes were made, who made the changes, and when the changes were made. <sup>[<a href="#repo-track">repo-track</a>]&#8224;</sup>
- <a name="repo-interim"></a>The source repository MUST include interim versions for review between releases; it MUST NOT include only final releases. <sup>[<a href="#repo-interim">repo-interim</a>]</sup>
- <a name="repo-distributed"></a>It is RECOMMENDED that common distributed version control software is used (e.g., git).  Git is not specifically required and projects can use centralized version control software (such as subversion) with justification. <sup>[<a href="#repo-distributed">repo-distributed</a>]&#8224;</sup>
- The project MAY use private (non-public) branches in specific cases while the change is not publicly released (e.g., for fixing a vulnerability before it is revealed to the public).
- *Rationale*:  This enables easy tracking and public review.  Some OSS projects do not use a version control system or do not provide public access to it. The lack of a public version control repository makes it unnecessarily difficult to contribute to a project and to track its progress in detail.

*Version numbering*

- <a name="version-unique"></a>The project MUST have a unique version number for each release intended to be used by users. <sup>[<a href="#version-unique">version-unique</a>]</sup>
- <a name="version-semver"></a>It is RECOMMENDED that the [Semantic Versioning (SemVer) format](http://semver.org) is used for releases. <sup>[<a href="#version-semver">version-semver</a>]</sup>
- Commit IDs (or similar) MAY be used as as version numbers. They are unique, but note that these can cause problems for users as they may not be able to determine  whether or not they're up-to-date.
- <a name="version-tags"></a>It is RECOMMENDED that projects identify each release within their version control system. For example, it is RECOMMENDED that those using git identify each release using git tags. <sup>[<a href="#version-tags">version-tags</a>]&#8224;</sup>

*ChangeLog*

- <a name="changelog"></a>The project MUST provide a "ChangeLog" (a human-readable summary of major changes in each release).  The ChangeLog MUST NOT be the output of the version control log of every change (e.g., the "git log" command is not a ChangeLog). <sup>[<a href="#changelog">changelog</a>]&#8224;</sup>
- <a name="changelog-vulns"></a>The ChangeLog MUST identify whether the new release fixes any publicly known vulnerabilities. <sup>[<a href="#changelog-vulns">changelog-vulns</a>]</sup>
- The ChangeLog MAY implmented in a variety of ways.  The ChangeLog MAY be a separate file (e.g., "ChangeLog" or "changelog") and the filename MAY be followed by an extension such as ".txt", ".md", or ".html".  The ChangeLog MAY instead use version control system mechanisms such as the [GitHub Releases workflow](https://github.com/blog/1547-release-your-software).
- *Rationale*: ChangeLogs are important because they help users decide whether or not they will want to update, and what the impact would be (e.g., if the new release fixes vulnerabilities).

### Reporting

*Bug-reporting process*

- <a name="report-url"></a>If an issue tracker is used, please provide its URL. <sup>[<a href="#report-url">report-url</a>]</sup>
- <a name="report-tracker"></a>It is RECOMMENDED that an issue tracker be used for tracking individual issues. <sup>[<a href="#report-tracker">report-tracker</a>]&#8224;</sup>
- <a name="report-process"></a>The project MUST provide a process for users to submit bug reports (e.g., using an issue tracker or a mailing list). <sup>[<a href="#report-process">report-process</a>]&#8224;</sup>
- <a name="report-responses"></a>Developers MUST respond to most bug reports submitted in the last 2-12 months (inclusive); the response need not include a fix. <sup>[<a href="#report-responses">report-responses</a>]&#8224;</sup>
- <a name="enhancement-responses"></a>Developers SHOULD respond to most enhancement requests in the last 2-12 months (inclusive). Developers MAY choose not to respond. <sup>[<a href="#enhancement-responses">enhancement-responses</a>]&#8224;</sup>
- <a name="report-archive"></a>Reports and responses MUST be archived for later searching. <sup>[<a href="#report-archive">report-archive</a>]&#8224;</sup>

*Vulnerability report process*

- <a name="vulnerability-report-process"></a>The project MUST publish the process for reporting vulnerabilities on the project site (e.g., a clearly designated mailing address on https://PROJECTSITE/security, often security@SOMEWHERE); this MAY be the same as its bug reporting process. <sup>[<a href="#vulnerability-report-process">vulnerability-report-process</a>]&#8224;</sup>
- <a name="vulnerability-report-private"></a>If private vulnerability reports are supported, the project MUST include how to send the information in a way that is kept private (e.g., a private defect report submitted on the web using TLS or an email encrypted using PGP). If private vulnerability reports are not supported this criterion is automatically met. <sup>[<a href="#vulnerability-report-private">vulnerability-report-private</a>]</sup>
- <a name="vulnerability-report-response"></a>The project MUST provide an initial reply to a security vulnerability report sent to the project, on average, less than 7 days within the last 6 months.  (If a project is being spammed on its vulnerability report channel, it is okay to only count non-spam messages.) <sup>[<a href="#vulnerability-report-response">vulnerability-report-response</a>]</sup>


### Quality

*Working build system*

- <a name="build"></a>If the software requires building for use, the project MUST provide a working build system that can automatically rebuild the software from source code.  A build system determines what actions need to occur to rebuild the software (and in what order), and then performs those steps. <sup>[<a href="#build">build</a>]*&#8224;</sup>
- <a name="build-common-tools"></a>It is RECOMMENDED that common tools be used for building the software (e.g., Maven, Ant, cmake, the autotools, make, or rake), in which case only the instructions to the build system are required (there's no requirement to teach people how to use common tools). <sup>[<a href="#build-common-tools">build-common-tools</a>]*&#8224;</sup>
- <a name="build-oss-tools"></a>The project SHOULD be buildable using only OSS tools. <sup>[<a href="#build-oss-tools">build-oss-tools</a>]*</sup>
- *Rationale*: If a project needs to be built but there is no working build system, then potential co-developers will not be able to easily contribute and many security analysis tools will be ineffective.  Criteria for a working build system are not applicable if there is no need to build anything for use.

*Automated test suite*

- <a name="test"></a>The project MUST have at least one automated test suite. <sup>[<a href="#test">test</a>]</sup>
- <a name="test-invocation"></a>A test suite SHOULD be invocable in a standard way for that language (e.g., "make check", "mvn test", and so on). <sup>[<a href="#test-invocation">test-invocation</a>]</sup>
- <a name="test-most"></a> It is RECOMMENDED that the test suite cover most (or ideally all) the code branches, input fields, and functionality. <sup>[<a href="#test-most">test-most</a>]</sup>
- The project MAY have multiple automated test suites (e.g., one that runs quickly, vs. another that is more thorough but requires special equipment).
- *Rationale*: Automated test suites immediately help detect a variety of problems.  A large test suite can find more problems, but even a small test suite can detect problems and provide a framework to build on.

*New functionality testing*

- <a name="tests-policy"></a>The project MUST have a general policy (formal or not) that as major new functionality is added, tests of that functionality SHOULD be added to an automated test suite. <sup>[<a href="#tests-policy">tests-policy</a>]</sup>
- <a name="tests-are-added"></a>The project MUST have evidence that such tests are being added in the most recent major changes to the project.  Major functionality would typically be mentioned in the ChangeLog.  (Perfection is not required, merely evidence that tests are typically being added in practice.) <sup>[<a href="#tests-are-added">tests-are-added</a>]</sup>
- <a name="tests-documented-added"></a>It is RECOMMENDED that this be *documented* in the instructions for change proposals, but even an informal rule is acceptable as long as the tests are being added in practice. <sup>[<a href="#tests-documented-added">tests-documented-added</a>]</sup>

*Warning flags*

- <a name="warnings"></a>The project MUST enable some compiler warning flagss (e.g. "-Wall"), a "safe" language mode (e.g., "use strict", "use warnings", or similar), and/or use a separate "linter" tool to look for code quality errors or common simple mistakes, if there is at least one OSS tool that can implement this criterion in the selected language. <sup>[<a href="#warnings">warnings</a>]*</sup>
- <a name="warnings-fixed"></a>The project MUST address the issues that are found (by fixing them or marking them in the source code as false positives).  Ideally there would be no warnings, but a project MAY accept some warnings (typically less than 1 warning per 100 lines or less than 10 warnings). <sup>[<a href="#warnings-fixed">warnings-fixed</a>]*</sup>
- <a name="warnings-strict"></a>It is RECOMMENDED that projects be maximally strict, but this is not always practical. <sup>[<a href="#warnings-strict">warnings-strict</a>]*</sup>

### Security

*Knowledge of secure development*

- <a name="know-secure-design"></a>The project MUST have at least one primary developer who knows how to design secure software.  This requires understanding the following design principles, including the 8 principles from [Saltzer and Schroeder](http://web.mit.edu/Saltzer/www/publications/protection/):
    - economy of mechanism (keep the design as simple and small as practical, e.g., by adopting sweeping simplifications)
    - fail-safe defaults (access decisions should deny by default)
    - complete mediation (every access that might be limited must be checked for authority and be non-bypassable)
    - open design (security mechanisms should not depend on attacker ignorance of its design, but instead on more easily protected and changed information like keys and passwords)
    - separation of privilege (multi-factor authentication, such as requiring both a password and a hardware token, is stronger than single-factor authentication)
    - least privilege (processes should operate with the least privilege necesssary)
    - least common mechanism (the design should minimize the mechanisms common to more than one user and depended on by all users, e.g., directories for temporary files)
    - psychological acceptability (the human interface must be designed for ease of use - designing for "least astonishment" can help)
    - limited attack surface (the attack surface - the set of the different points where an attacker can try to enter or extract data - should be limited)
    - input validation with whitelists (inputs should typically be checked to determine if they are valid before they are accepted; this validation should use whitelists (which only accept known-good values), not blacklists (which attempt to list known-bad values)) <sup>[<a href="#know-secure-design">know-secure-design</a>]</sup>
- <a name="know-common-errors"></a>The project MUST have at least one primary developer who knows the common kinds of errors that lead to vulnerabilities in the project, as well as at least one method to counter or mitigate each of them.  Examples (depending on the type of software) include SQL injection, OS injection, classic buffer overflow, cross-site scripting, missing authentication, and missing authorization.  See the [CWE/SANS top 25](https://cwe.mitre.org/top25/) or [OWASP Top 10](https://www.owasp.org/index.php/Category:OWASP_Top_Ten_Project) for commonly-used lists. <sup>[<a href="#know-common-errors">know-common-errors</a>]</sup>
- *Note*: If there is only one developer, by definition that individual is the primary developer.

*Good cryptographic practices*

- <a name="crypto-published"></a>The project MUST use cryptographic protocols and algorithms, within the software, that are publicly published and reviewed by experts. <sup>[<a href="#crypto-published">crypto-published</a>]*</sup>
- <a name="crypto-call"></a>If the software is not itself a cryptographic system/library, it MUST call on software specifically designed for cryptographic functions, and MUST NOT implement its own. <sup>[<a href="#crypto-call">crypto-call</a>]*</sup>
- <a name="crypto-oss"></a>The project MUST implement all functionality that depends on cryptography using OSS (this is to meet the [*Open Standards Requirement for Software* by the Open Source Initiative](https://opensource.org/osr). <sup>[<a href="#crypto-oss">crypto-oss</a>]*</sup>
- <a name="crypto-keylength"></a>The project MUST use default keylengths that meet the NIST minimum requirements at least through the year 2030 (as stated in 2012).  These minimum bitlengths are: symmetric key 112, factoring modulus 2048, discrete logarithm key 224, discrete logarithmic group 2048, elliptic curve 224, and hash 224.  See <http://www.keylength.com> for a comparison of keylength recommendations from various organizations. <sup>[<a href="#crypto-keylength">crypto-keylength</a>]*</sup>
- <a name="crypto-reject-small-keylength"></a>The software MUST be configurable so that it will reject smaller keylengths.  The software MAY allow smaller keylengths in some configurations (ideally it would not, since this allows downgrade attacks, but shorter keylengths are sometimes necessary for interoperability.)  <sup>[<a href="#crypto-reject-small-keylength">crypto-reject-small-keylength</a>]*</sup>
- <a name="crypto-working"></a>The project MUST NOT use security mechanisms that depend on cryptographic algorithms that are broken or have too-short key lengths (e.g., MD4, MD5, single DES, or RC4).  It is RECOMMENDED that SHA-1 not be used (we are well aware that git uses SHA-1).  Currently-recommended algorithms include AES and SHA-256/SHA-512.  Implementations SHOULD support multiple cryptographic algorithms, so users can quickly switch if one is broken.  <sup>[<a href="#crypto-working">crypto-working</a>]*</sup>
- <a name="crypto-password-storage"></a>If passwords are stored for authentication, the project MUST store them as iterated hashes with a per-user salt by using a key stretching algorithm (e.g., PBKDF2, Bcrypt or Scrypt). <sup>[<a href="#crypto-password-storage">crypto-password-storage</a>]*</sup>
- <a name="crypto-random"></a>The project MUST generate all keys and noncesusing cryptographically random functions, and MUST NOT do so through non-cryptographically random functions. <sup>[<a href="#crypto-random">crypto-random</a>]*</sup>
- <a name="crypto-pfs"></a>The project SHOULD implement perfect forward secrecy for key agreement protocols so a session key derived from a set of long-term keys cannot be compromised if one of the long-term keys is compromised in the future.  <sup>[<a href="#crypto-pfs">crypto-pfs</a>]*</sup>
- - *Note*: These criteria do not always apply because some software has no need to directly use cryptographic capabilities.

*Secured delivery mechanism*

- <a name="delivery-crypto"></a>The project MUST use cryptographic protocols and algorithms, for any delivery mechanisms, that are publicly published and reviewed by experts. <sup>[<a href="#delivery-crypto">delivery-crypto</a>]*</sup>
- <a name="delivery-mitm"></a>The project MUST use a delivery mechanism that counters MITM attacks.  HTTPS or SSH+SCP MAY be used.  An even stronger mechanism would be releasing the software with digitally signed packages as this mitigates attacks on the distribution system. This only works if users can be confident that the public keys for signatures are correct *and* if the user actually checks the signature. <sup>[<a href="#delivery-mitm">delivery-mitm</a>]&#8224;</sup>
- <a name="delivery-unsigned"></a>The project MUST NOT deliver a cryptographic hash (e.g., a sha1sum) over HTTP since these hashes can be modified in transit. <sup>[<a href="#delivery-unsigned">delivery-unsigned</a>]</sup>

*Publicly-known vulnerabilities fixed*

- <a name="vulnerabilities-fixed-60-days"></a>There MUST be no unpatched vulnerabilities of medium or high severity that have been *publicly* known for more than 60 days.  The vulnerability must be patched and released by the project itself (patches may be developed elsewhere).  A vulnerability becomes publicly known (for this purpose) once it has a CVE with publicly released non-paywalled information (reported, for example, in the [National Vulnerability Database](https://nvd.nist.gov/)) or when the project has been informed *and* the information has been released to the public (possibly by the project).  A vulnerability is medium to high severity if its [CVSS 2.0](https://nvd.nist.gov/cvss.cfm) base score is 4 or higher. <sup>[<a href="#vulnerabilities-fixed-60-days">vulnerabilities-fixed-60-days</a>]&#8224;</sup>
- <a name="vulnerabilities-critical-fixed"></a>Projects SHOULD fix all critical vulnerabilities rapidly after they are reported. <sup>[<a href="#vulnerabilities-critical-fixed">vulnerabilities-critical-fixed</a>]</sup>
- *Note*: this means that users might be left vulnerable to all attackers worldwide for up to 60 days.  This criterion is often much easier to meet than what Google recommends in [Rebooting responsible disclosure](http://googleonlinesecurity.blogspot.com/2010/07/rebooting-responsible-disclosure-focus.html), because Google recommends that the 60-day period start when the project is notified *even* if the report is not public.
- *Rationale*: We intentionally chose to start measurement from the time of public knowledge, and not from the time reported to the project, because this is much easier to measure and verify by those *outside* the project.

### Security analysis

*Static code analysis*

- <a name="static-analysis"></a>At least one static code analysis tool MUST be applied to any proposed major production release of the software before its release, if there is at least one OSS tool that implement this criterion in the selected language.  A static code analysis tool examines the software code (as source code, intermediate code, or executable) without executing it with specific inputs.  For purposes of this criterion compiler warnings and "safe" language modes do not count as a static code analysis tool (these typically avoid deep analysis because speed is vital).  Examples of such static code analysis tools include cppcheck, the clang static analyzer, FindBugs (including FindSecurityBugs), PMD, Brakeman, [Coverity Quality Analyzer](https://scan.coverity.com/), and the HP Fortify Static Code Analyzer. <sup>[<a href="#static-analysis">static-analysis</a>]*</sup>
- The analysis tool(s) MAY be focused on looking for security vulnerabilities, but this is not required.
- <a name="static-analysis-common-vulnerabilities"></a>It is RECOMMENDED that the tool include rules or approaches to look for common vulnerabilities in the analyzed language or environment. <sup>[<a href="#static-analysis-common-vulnerabilities">static-analysis-common-vulnerabilities</a>]*</sup>
- <a name="static-analysis-fixed"></a>All confirmed medium and high severity exploitable vulnerabilities discovered with static code analysis MUST be fixed.  A vulnerability is medium to high severity if its [CVSS 2.0](https://nvd.nist.gov/cvss.cfm) is 4 or higher. <sup>[<a href="#static-analysis-fixed">static-analysis-fixed</a>]*</sup>
- <a name="static-analysis-often"></a>It is RECOMMENDED that static source code analysis occur on every commit or at least daily. <sup>[<a href="#static-analysis-often">static-analysis-often</a>]*</sup>

*Dynamic analysis*

- <a name="dynamic-analysis"></a>At least one dynamic analysis tool MUST be applied to any proposed major production release of the software before its release.  A dynamic analysis tool examines the software by executing it with specific inputs.  For example, the project MAY use a fuzzing tool (e.g., [American Fuzzy Lop](http://lcamtuf.coredump.cx/afl/)) or a web application scanner (e.g., [OWASP ZAP](https://www.owasp.org/index.php/OWASP_Zed_Attack_Proxy_Project) or [<a href="#w3af">w3af</a>](http://w3af.org/)). For purposes of this criterion the dynamic analysis tool MUST vary the inputs in some way to look for various kinds of problems *or* be an automated test suite with at least 80% branch coverage. <sup>[dynamic-analysis]</sup>
- <a name="dynamic-analysis-unsafe"></a>It is RECOMMENDED that if the software is application-level software written using a memory-unsafe language (such as C or C++) then at least one tool to detect memory safety problems MUST be used during at least one dynamic tool use, e.g., Address Sanitizer (ASAN) or valgrind. If the software is not application-level, or is not in a memory-unsafe language, then this criterion is automatically met.  <sup>[<a href="#dynamic-analysis-unsafe">dynamic-analysis-unsafe</a>]</sup>
- <a name="dynamic-analysis-enable-assertions"></a>It is RECOMMENDED that the software include many run-time assertions that are checked during dynamic analysis. <sup>[<a href="#dynamic-analysis-enable-assertions">dynamic-analysis-enable-assertions</a>]</sup>
- The analysis tool(s) MAY be focused on looking for security vulnerabilities, but this is not required.
- <a name="dynamic-analysis-fixed"></a>All confirmed medium and high severity exploitable vulnerabilities discovered with dynamic code analysis MUST be fixed.  A vulnerability is medium to high severity if its [CVSS 2.0](https://nvd.nist.gov/cvss.cfm) base score is 4 or higher. <sup>[<a href="#dynamic-analysis-fixed">dynamic-analysis-fixed</a>]</sup>
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
One area we have often discussed is whether or not to require
continuous integration in this set of criteria;
if it is not, it is expected to be required at higher levels.
See [other](./other.md) for more information.

You may also want to see the "[background](./background.md)" file
for more information about these criteria,
and the "[implementation](./implementation.md)" notes
about the BadgeApp application.

