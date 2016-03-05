# Best Practices Criteria for Free/Libre and Open Source Software (FLOSS) (version 0.5.0)

## Introduction

This is a *draft* of proposed best practices
for Free/Libre and Open Source Software (FLOSS) projects.
Projects that follow these best practices
will be able to voluntarily self-certify and show that they've
achieved a Core Infrastructure Initiative (CII) badge.
Projects can do this, at no cost,
by using a web application (BadgeApp)
to explain how they meet these practices and their detailed criteria.

There is no set of practices that can guarantee that software
will never have defects or vulnerabilities;
even formal methods can fail if the specifications or assumptions are wrong.
Nor is there any set of practices that can guarantee that a project will
sustain a healthy and well-functioning development community.
However, following best practices can help improve the results
of projects.
For example, some practices enable multi-person review before release,
which can both help find otherwise hard-to-find technical vulnerabilities
and help build trust and a desire for repeated interaction among developers
from different organizations.

These best practices have been created to:

1. encourage projects to follow best practices,
2. help new projects discover what those practices are, and
3. help users know which projects are following best practices
   (so users can prefer such projects).

We are currently focused on identifying best practices
that well-run projects typically already follow.
We are capturing other practices so that we can create
[more advanced badges](./other.md) later.
The best practices, and the more detailed criteria
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
"SHOULD", "SHOULD NOT", and "MAY"
in this document are to be interpreted as described in
[RFC 2119](https://tools.ietf.org/html/rfc2119).
The additional term SUGGESTED is added, as follows:

- The term MUST is an absolute requirement, and MUST NOT
  is an absolute prohibition.
- The term SHOULD indicates a criterion that should be implemented, but
  valid reasons may exist to not do so in particular circumstances.
  The full implications must be considered,
  understood, and carefully weighed before choosing a different course.
- The term SUGGESTED is used instead of SHOULD when the criterion must
  be considered, but valid reasons
  to not do so are even more common than for SHOULD.
- Often a criterion is stated as something that SHOULD be done, or is
  SUGGESTED, because it may be difficult to implement or the costs
  to do so may be high.
- The term MAY provides one way something can be done, e.g.,
  to make it clear that the described implementation is acceptable.
- To obtain a badge, all MUST and MUST NOT criteria must be met, all
  SHOULD criteria must be met OR the rationale for
  not implementing the criterion must be documented, and
  all SUGGESTED criteria have to be considered (rated as met or unmet).

We assume that you are already familiar with
software development and running a FLOSS project;
if not, see introductory materials such as
[*Producing Open Source Software* by Karl Fogel](http://producingoss.com/).


## Current criteria: Best Practices for FLOSS

Here are the current *draft* criteria; it is certain to change.
Note that:
* The criteria marked with "&#8224;" are intended to be automatically testable
  if the project follows standard conventions and
  is hosted on a site (e.g., GitHub) with decent API support.
* The criteria marked with "*" at the end may be not applicable
  or not required; see their text for more information.
* Text inside square brackets is the short name of the criterion.
* In a few cases rationale is also included.
* We expect that there will be a few other fields for the
  project name, description, project URL, repository URL (which may be the
  same as the project URL), and license(s).

### Basics

*Project website*

- <a name="project_homepage_url"></a>The project MUST have a public website
  with a stable URL.
  <sup>[<a href="#project_homepage_url">project_homepage_url</a>]&#8224;</sup>
- <a name="project_homepage_https"></a>It is SUGGESTED that the project website
  use HTTPS, not HTTP.
  Future versions of these criteria may make HTTPS a requirement.
  (The badging application will show a warning for HTTP-only URLs.)
  <sup>[<a href="#project_homepage_https">project_homepage_https</a>]&#8224;</sup>

*Basic project website content*

- <a name="description_sufficient"></a>The project website MUST succinctly
  describe what the software does (what problem does it solve?).
  This MUST be in language that potential users can understand
  (e.g., it uses minimal jargon).
  <sup>[<a href="#description_sufficient">description_sufficient</a>]</sup>
- <a name="interact"></a>The project website MUST provide information on how to:
  - obtain,
  - provide feedback (as bug reports or enhancements),
  - and contribute to the software.
  <sup>[<a href="#interact">interact</a>]</sup>
- <a name="contribution"></a>The information on how to contribute MUST
  explain the contribution process (e.g., are pull requests used?)
  We presume that
  <a href="https://guides.github.com/activities/contributing-to-open-source/">projects on GitHub use issues and pull requests</a>
  unless otherwise noted.
  <sup>[<a href="#contribution">contribution</a>]</sup>
- <a name="contribution_requirements"></a>The information on how to contribute
  SHOULD include the requirements for acceptable contributions
  (e.g., a reference to any required coding standard).
  <sup>[<a href="#contribution_requirements">contribution_requirements</a>]</sup>

*FLOSS license*

- <a name="floss_license"></a> The software MUST be licensed as FLOSS.
  Examples of such licenses include the
  [CC0](http://creativecommons.org/publicdomain/zero/1.0/),
  [MIT](https://opensource.org/licenses/MIT),
  [BSD 2-clause](https://opensource.org/licenses/BSD-2-Clause),
  [BSD 3-clause revised](https://opensource.org/licenses/BSD-3-Clause),
  [Apache 2.0](https://opensource.org/licenses/Apache-2.0),
  [Lesser GNU General Public License (LGPL)](https://opensource.org/licenses/lgpl-license) (any version),
  and the [GNU General Public License (GPL)](https://opensource.org/licenses/gpl-license) (any version).
  For our purposes, this means that the license MUST be:
    - [an approved license by the Open Source Initiative (OSI)](https://opensource.org/licenses), or
    - [a free license as approved by the Free Software Foundation (FSF)](https://www.gnu.org/licenses/license-list.html), or
    - [a free license acceptable to Debian main](https://www.debian.org/legal/licenses/), or
    - [a "good" license according to Fedora](https://fedoraproject.org/wiki/Licensing:Main?rd=Licensing).

  <sup>[<a href="#floss_license">floss_license</a>]&#8224;</sup>
- <a name="floss_license_osi"></a> It is SUGGESTED that any required license(s) be
  [approved by the Open Source Initiative (OSI)](https://opensource.org/licenses).
  The OSI uses a rigorous license approval
  process to determine which licenses are OSS.
  <sup>[<a href="#floss_license_osi">floss_license_osi</a>]&#8224;</sup>
- <a name="license_location"></a>The project MUST post license(s) in a standard
  location (e.g., as a top-level file named LICENSE or COPYING).
  License filenames MAY be followed by an extension such as ".txt" or ".md"
  <sup>[<a href="#license_location">license_location</a>]&#8224;</sup>
- The software MAY also be licensed other ways
  (e.g., "GPLv2 or proprietary" is acceptable).
- *Rationale*: These criteria are designed for FLOSS projects, so we need to
  ensure that they're only used where they apply.
  Some projects may be mistakenly considered FLOSS even though they are not
  (e.g., they might not have any license, in which case the defaults of the
  country's legal system apply, or they might use a non-FLOSS license).
  Unusual licenses can cause long-term problems for FLOSS projects and are
  more difficult for tools to handle.
  We expect that [more advanced badges](./other.md) would set a higher bar
  (e.g., that it *must* be released under an OSI-approved license).

*Documentation*

- <a name="documentation_basics"></a>The project MUST provide basic
  documentation for the software in some media (such as text or video)
  that includes:
  - how to install it,
  - how to start it,
  - how to use it (possibly with a tutorial using examples), and
  - how to use it securely (e.g., what to do and what not to do)
    if that is an appropriate topic for the software.

  The security documentation need not be long.
  <sup>[<a href="#documentation_basics">documentation_basics</a>]</sup>
- <a name="documentation_interface"></a>The project MUST include reference
  documentation that describes its interface.
  <sup>[<a href="#documentation_interface">documentation_interface</a>]</sup>
- The project MAY use hypertext links to non-project material as documentation.


*Other*

- <a name="discussion"></a>The project MUST have one or more mechanisms
  for discussion (including proposed changes and issues) that are:
    - searchable,
    - allow messages and topics to be addressed by URL,
    - enable new people to participate in some of the discussions, and
    - do not require client-side installation of proprietary software.

  Examples of acceptable mechanisms include
  GitHub issue and pull request discussions, Bugzilla, Mantis, and Trac.
  Asynchronous discussion mechanisms (like IRC) are acceptable if
  they meet these criteria; make sure there is a URL-addressable
  archiving mechanism.
  Proprietary Javascript, while discouraged, is permitted.
  <sup>[<a href="#discussion">discussion</a>]</sup>

### Change control

*Public version-controlled source repository*

- <a name="repo_public"></a>The project MUST have a version-controlled
  source repository that is publicly readable and has a URL.
  The URL MAY be the same as the project URL.
  The project MAY use private (non-public) branches in specific cases while the
  change is not publicly released
  (e.g., for fixing a vulnerability before it is revealed to the public).
   <sup>[<a href="#repo_public">repo_url</a>]&#8224;</sup>
- <a name="repo_track"></a>The source repository MUST track what changes
  were made, who made the changes, and when the changes were made.
  <sup>[<a href="#repo_track">repo_track</a>]&#8224;</sup>
- <a name="repo_interim"></a>To enable collaborative review,
  the project's source repository MUST include interim
  versions for review between releases;
  it MUST NOT include only final releases.
  Projects MAY choose to omit specific interim versions
  from their public source repositories
  (e.g., ones that fix specific non-public security vulnerabilities,
  may never be publicly released, or include material that cannot
  be legally posted and are not in the final release).
  <sup>[<a href="#repo_interim">repo_interim</a>]</sup>
- <a name="repo_distributed"></a>It is SUGGESTED that common distributed
  version control software be used (e.g., git).
  Git is not specifically required and projects can use centralized version
  control software (such as subversion).
  <sup>[<a href="#repo_distributed">repo_distributed</a>]&#8224;</sup>

*Version numbering*

- <a name="version_unique"></a>The project MUST have a unique version number
  for each release intended to be used by users.
  <sup>[<a href="#version_unique">version_unique</a>]</sup>
- <a name="version_semver"></a>It is SUGGESTED that the
  [Semantic Versioning (SemVer) format](http://semver.org) be used for releases.
  <sup>[<a href="#version_semver">version_semver</a>]</sup>
- Commit IDs (or similar) MAY be used as version numbers.
  They are unique, but note that these can cause problems for users as they may
  not be able to determine  whether or not they're up-to-date.
- <a name="version_tags"></a>It is SUGGESTED that projects identify each
  release within their version control system.
  For example, it is SUGGESTED that those using git identify each release
  using git tags.
  <sup>[<a href="#version_tags">version_tags</a>]&#8224;</sup>

*Release notes (ChangeLog)*

- <a name="release_notes"></a><a name="changelog"></a>The project
  MUST provide, in each release, release notes that are
  a human-readable *summary* of major changes in that release.
  The release notes MUST NOT be the output of a version control log
  (e.g., the "git log" command results are not release notes).
  <sup>[<a href="#release_notes">release_notes</a>]&#8224;</sup>
- <a name="release_notes_vulns"></a><a name="changelog_vulns"></a>The
  release notes MUST identify every publicly known vulnerability
  that is fixed in each new release.
  <sup>[<a href="#release_notes_vulns">release_notes_vulns</a>]</sup>
- The release notes MAY be implemented in a variety of ways.
  Many projects provide them in a file named "NEWS", "CHANGELOG",
  or "ChangeLog", optionally with extensions such as ".txt", ".md", or ".html".
  Historically the term "change log" meant a log of *every* change,
  but to meet these criteria what is needed is a human-readable summary.
  The release notes MAY instead be provided by
  version control system mechanisms such as the
  [GitHub Releases workflow](https://github.com/blog/1547-release-your-software).
- *Rationale*: Release notes are important because they help users
  decide whether or not they will want to update, and what the impact would be
  (e.g., if the new release fixes vulnerabilities).

### Reporting

*Bug reporting process*

- <a name="report_process"></a>The project MUST provide a process for users
  to submit bug reports (e.g., using an issue tracker or a mailing list).
  <sup>[<a href="#report_process">report_process</a>]&#8224;</sup>
- <a name="report_tracker"></a>The project SHOULD use an issue
  tracker for tracking individual issues.
  <sup>[<a href="#report_tracker">report_tracker</a>]&#8224;</sup>
- <a name="report_responses"></a>The project MUST acknowledge a majority of
  bug reports submitted in the last 2-12 months (inclusive);
  the response need not include a fix.
  <sup>[<a href="#report_responses">report_responses</a>]&#8224;</sup>
- <a name="enhancement_responses"></a>The project SHOULD respond to most
  enhancement requests in the last 2-12 months (inclusive).
  The project MAY choose not to respond.
  <sup>[<a href="#enhancement_responses">enhancement_responses</a>]&#8224;</sup>
- <a name="report_archive"></a>The project MUST have a publicly available
  archive for reports and responses for later searching.
  <sup>[<a href="#report_archive">report_archive</a>]&#8224;</sup>

*Vulnerability reporting process*

- <a name="vulnerability_report_process"></a>The project MUST publish the
  process for reporting vulnerabilities on the project site.
  E.g., a clearly designated mailing address on <https://PROJECTSITE/security>,
  often security@SOMEWHERE.
  This MAY be the same as its bug reporting process.
  <sup>[<a href="#vulnerability_report_process">vulnerability_report_process</a>]&#8224;</sup>
- <a name="vulnerability_report_private"></a>If private vulnerability reports
  are supported, the project MUST include how to send the information in a
  way that is kept private.
  E.g., a private defect report submitted on the web using TLS or an email
  encrypted using OpenPGP.
  If private vulnerability reports are not supported this criterion
  is automatically met.
  <sup>[<a href="#vulnerability_report_private">vulnerability_report_private</a>]</sup>
- <a name="vulnerability_report_response"></a>The project's
  initial response time for any vulnerability report received
  in the last 6 months MUST be less than or equal to 14 days.
  <sup>[<a href="#vulnerability_report_response">vulnerability_report_response</a>]</sup>

### Quality

*Working build system*

- <a name="build"></a>If the software requires building for use,
  the project MUST provide a working build system that can automatically
  rebuild the software from source code.
  A build system determines what actions need to occur to rebuild the software
  (and in what order), and then performs those steps.
  <sup>[<a href="#build">build</a>]\*&#8224;</sup>
- <a name="build_common_tools"></a>It is SUGGESTED that common
  tools be used for building the software.
  For example, Maven, Ant, cmake, the autotools, make, or rake.
  <sup>[<a href="#build_common_tools">build_common_tools</a>]\*&#8224;</sup>
- <a name="build_floss_tools"></a> The project SHOULD be buildable
  using only FLOSS tools.
  <sup>[<a href="#build_floss_tools">build_floss_tools</a>]\*</sup>
- *Rationale*: If a project needs to be built but there is no working
  build system, then potential co-developers will not be able to easily
  contribute and many security analysis tools will be ineffective.
  Criteria for a working build system are not applicable if there is
  no need to build anything for use.

*Automated test suite*

- <a name="test"></a>The project MUST have at least one automated test suite
  that is publicly released as FLOSS
  (this test suite may be maintained as a separate FLOSS project)."
  <sup>[<a href="#test">test</a>]</sup>
- <a name="test_invocation"></a>A test suite SHOULD be invocable in
  a standard way for that language.
  For example,  "make check", "mvn test", or "rake test".
  <sup>[<a href="#test_invocation">test_invocation</a>]</sup>
- <a name="test_most"></a>It is SUGGESTED that the test suite cover most
  (or ideally all) the code branches, input fields, and functionality.
  <sup>[<a href="#test_most">test_most</a>]</sup>
- <a name="test_continuous_integration"></a>It is SUGGESTED that the project
  implement continuous integration
  (where new or changed code is frequently integrated into a central code
  repository and automated tests are run on the result).
  <sup>[<a href="#test_continuous_integration">test_continuous_integration</a>]</sup>
- The project MAY have multiple automated test suites
  (e.g., one that runs quickly, vs. another that is more thorough but
  requires special equipment).
- *Rationale*: Automated test suites immediately help detect a
  variety of problems.  A large test suite can find more problems,
  but even a small test suite can detect problems and
  provide a framework to build on.


*New functionality testing*

- <a name="test_policy"></a>The project MUST have a general policy
  (formal or not) that as major new functionality is added,
  tests of that functionality SHOULD be added to an automated test suite.
  <sup>[<a href="#test_policy">test_policy</a>]</sup>
- <a name="tests_are_added"></a>The project MUST have evidence that such
  tests are being added in the most recent major changes to the project.
  Major functionality would typically be mentioned in the ChangeLog.
  (Perfection is not required, merely evidence that tests are
  typically being added in practice.)
  <sup>[<a href="#tests_are_added">tests_are_added</a>]</sup>
- <a name="tests_documented_added"></a>It is SUGGESTED that this policy on
  adding tests be *documented* in the instructions for change proposals.
  However, even an informal rule is acceptable as long as the tests
  are being added in practice.
  <sup>[<a href="#tests_documented_added">tests_documented_added</a>]</sup>

*Warning flags*

- <a name="warnings"></a>The project MUST enable one or more compiler
  warning flags, a "safe" language mode, or use a separate "linter" tool to
  look for code quality errors or common simple mistakes,
  if there is at least one FLOSS tool that can implement this criterion
  in the selected language.
  Examples of compiler warning flags include gcc/clang "-Wall".
  Examples of a "safe" language mode include Javascript "use strict"
  and perl5's "use warnings".
  A separate "linter" tool is simply a tool that examines the source
  code to look for code quality errors or common simple mistakes.
  <sup>[<a href="#warnings">warnings</a>]\*</sup>
- <a name="warnings_fixed"></a>The project MUST address warnings.
  The project should fix warnings or mark them in the source
  code as false positives.
  Ideally there would be no warnings, but a project MAY accept some warnings
  (typically less than 1 warning per 100 lines or less than 10 warnings).
  <sup>[<a href="#warnings_fixed">warnings_fixed</a>]\*</sup>
- <a name="warnings_strict"></a>It is SUGGESTED that projects be
  maximally strict with warnings, but this is not always practical.
  <sup>[<a href="#warnings_strict">warnings_strict</a>]\*</sup>

### Security

*Secure development knowledge*

- <a name="know_secure_design"></a>The project MUST have at least one
  primary developer who knows how to design secure software.
  This requires understanding the following design principles,
  including the 8 principles from
  [Saltzer and Schroeder](http://web.mit.edu/Saltzer/www/publications/protection/):
    - economy of mechanism (keep the design as simple and small as practical,
      e.g., by adopting sweeping simplifications)
    - fail-safe defaults (access decisions should deny by default, and
      projects' installation should be secure by default)
    - complete mediation (every access that might be limited must be
      checked for authority and be non-bypassable)
    - open design (security mechanisms should not depend on attacker
      ignorance of its design, but instead on more easily protected and
      changed information like keys and passwords)
    - separation of privilege (ideally, access to important objects
      should depend on more than one condition, so that defeating
      one protection system won't enable complete access.
      E.G., multi-factor authentication, such as requiring both a password
      and a hardware token, is stronger than single-factor authentication)
    - least privilege (processes should operate with the
      least privilege necessary)
    - least common mechanism (the design should minimize the mechanisms
      common to more than one user and depended on by all users,
      e.g., directories for temporary files)
    - psychological acceptability
      (the human interface must be designed for ease of use,
      designing for "least astonishment" can help)
    - limited attack surface (the attack surface, the set of the different
      points where an attacker can try to enter or extract data,
      should be limited)
    - input validation with whitelists
      (inputs should typically be checked to determine if they are valid
      before they are accepted; this validation should use whitelists
      (which only accept known-good values),
      not blacklists (which attempt to list known-bad values)).
      <sup>[<a href="#know_secure_design">know_secure_design</a>]</sup>
- <a name="know_common_errors"></a>At least one of the primary developers
  MUST know of common kinds of errors that lead to vulnerabilities in this kind
  of software, as well as at least one method
  to counter or mitigate each of them.
  Examples (depending on the type of software) include SQL injection,
  OS injection, classic buffer overflow, cross-site scripting,
  missing authentication, and missing authorization.
  See the [CWE/SANS top 25](http://cwe.mitre.org/top25/) or
  [OWASP Top 10](https://www.owasp.org/index.php/Category:OWASP_Top_Ten_Project)
  for commonly-used lists.
  <sup>[<a href="#know_common_errors">know_common_errors</a>]</sup>
- A "primary developer" in a project is anyone who is familiar with
  the project's code base, is comfortable making changes to it, and is
  acknowledged as such by most other participants in the project.
  A primary developer would typically make a number of contributions
  over the past year (via code, documentation, or answering questions).
  Developers would typically be considered primary developers if they
  initiated the project (and have not left the project more than three
  years ago), have the option of receiving information on a private
  vulnerability reporting channel (if there is one), can accept commits
  on behalf of the project, or perform final releases of the project software.
  If there is only one developer, that individual is the primary developer.


*Good cryptographic practices*

*Note*: These criteria do not always apply because some software has no
need to directly use cryptographic capabilities.
A "project security mechanism" is a security mechanism provided
by the delivered project's software.

- <a name="crypto_published"></a>The project's cryptographic software MUST
  use only cryptographic protocols and algorithms that are publicly published
  and reviewed by experts.
  <sup>[<a href="#crypto_published">crypto_published</a>]\*</sup>
- <a name="crypto_call"></a>If the project software is an application
  or library, and its primary purpose is not to implement cryptography,
  then it MUST only call on software specifically designed to implement
  cryptographic functions;
  it MUST NOT re-implement its own.
  <sup>[<a href="#crypto_call">crypto_call</a>]\*</sup>
- <a name="crypto_oss"></a>All project functionality that depends
  on cryptography MUST be implementable using FLOSS.  See the
  [*Open Standards Requirement for Software* by the Open Source Initiative](https://opensource.org/osr).
  <sup>[<a href="#crypto_oss">crypto_oss</a>]\*</sup>
- <a name="crypto_keylength"></a>The project security mechanisms
  MUST use default keylengths that meet the NIST minimum requirements
  at least through the year 2030 (as stated in 2012).
  These minimum bitlengths are: symmetric key 112, factoring modulus 2048,
  discrete logarithm key 224, discrete logarithmic group 2048,
  elliptic curve 224, and hash 224 (password hashing is not covered by this
  bitlength, more information on password hashing can be found in the
  <a href="#crypto_password_storage">crypto_password_storage</a> criterion).
  See <http://www.keylength.com> for a comparison of keylength
  recommendations from various organizations.
  The software MUST be configurable so that it will reject smaller keylengths.
  The software MAY allow smaller keylengths in some configurations
  (ideally it would not, since this allows downgrade attacks,
  but shorter keylengths are sometimes necessary for interoperability.)
  <sup>[<a href="#crypto_keylength">crypto_keylength</a>]\*</sup>
- <a name="crypto_working"></a>The project security mechanisms MUST NOT
  depend on cryptographic algorithms that are broken
  (e.g., MD4, MD5, single DES, RC4, or Dual_EC_DRBG).
  <sup>[<a href="#crypto_working">crypto_working</a>]\*</sup>
- <a name="crypto_weaknesses"></a>The project security mechanisms
  SHOULD NOT by default depend on cryptographic algorithms with known
  serious weaknesses (e.g., SHA-1).
  <sup>[<a href="#crypto_weaknesses">crypto_weaknesses</a>]\*</sup>
- <a name="crypto_pfs"></a>The project SHOULD implement perfect forward
  secrecy for key agreement protocols so a session key derived from a set
  of long-term keys cannot be compromised if one of the long-term keys is
  compromised in the future.
  <sup>[<a href="#crypto_pfs">crypto_pfs</a>]\*</sup>
- <a name="crypto_password_storage"></a>If passwords are stored for
  authentication of external users, the project MUST store them as
  iterated hashes with a per-user salt by using a key stretching
  (iterated) algorithm (e.g., PBKDF2, Bcrypt or Scrypt).
  <sup>[<a href="#crypto_password_storage">crypto_password_storage</a>]\*</sup>
- <a name="crypto_random"></a>The project MUST generate all
  cryptographic keys and nonces
  using a cryptographically secure random number generator,
  and MUST NOT do so using generators that are not cryptographically secure.
  A cryptographically secure random number generator may be a
  hardware random number generator, or it may be
  a cryptographically secure pseudo-random number generator (CSPRNG) using
  an algorithm such as Hash_DRBG, HMAC_DRBG, CTR_DRBG, Yarrow, or Fortuna.
  <sup>[<a href="#crypto_random">crypto_random</a>]\*</sup>

*Secured delivery mechanism*

- <a name="delivery_mitm"></a>The project MUST provide its materials
  using a delivery mechanism that counters man-in-the-middle (MITM) attacks.
  Using https or ssh+scp is acceptable.
  An even stronger mechanism is releasing the software with digitally signed
  packages, since that mitigates attacks on the distribution system,
  but this only works if the users can be confident that the public keys
  for signatures are correct *and* if the users will
   actually check the signature.
  <sup>[<a href="#delivery_mitm">delivery_mitm</a>]&#8224;</sup>

*Publicly-known vulnerabilities fixed*

- <a name="vulnerabilities_fixed_60_days"></a>There MUST be no unpatched
  vulnerabilities of medium or high severity that have been *publicly* known
  for more than 60 days.
  The vulnerability must be patched and released by the project itself
  (patches may be developed elsewhere).
  A vulnerability becomes publicly known (for this purpose) once it has a
  CVE with publicly released non-paywalled information
  (reported, for example, in the
  [National Vulnerability Database](https://nvd.nist.gov/))
  or when the project has been informed *and* the information has been
  released to the public (possibly by the project).
  A vulnerability is medium to high severity if its
  [CVSS 2.0](https://nvd.nist.gov/cvss.cfm) base score is 4 or higher.
  <sup>[<a href="#vulnerabilities_fixed_60_days">vulnerabilities_fixed_60_days</a>]&#8224;</sup>
- <a name="vulnerabilities_critical_fixed"></a>Projects SHOULD fix all
  critical vulnerabilities rapidly after they are reported.
  <sup>[<a href="#vulnerabilities_critical_fixed">vulnerabilities_critical_fixed</a>]</sup>
- *Note*: this means that users might be left vulnerable to all
  attackers worldwide for up to 60 days.
  This criterion is often much easier to meet than what Google recommends in
  [Rebooting responsible disclosure](http://googleonlinesecurity.blogspot.com/2010/07/rebooting-responsible-disclosure-focus.html),
  because Google recommends that the 60-day period start when the
  project is notified *even* if the report is not public.
- *Rationale*: We intentionally chose to start measurement from the time of
  public knowledge, and not from the time reported to the project,
  because this is much easier to measure and verify by those
  *outside* the project.

*Other security issues*

- <a name="no_leaked_credentials"></a>The public repositories
  MUST NOT leak a valid private credential
  (e.g., a working password or private key) that is intended to limit
  public access.
  A project MAY leak "sample" credentials for testing and
  unimportant databases, as long as they are not intended to limit
  public access.

### Analysis

*Static code analysis*

- <a name="static_analysis"></a>At least one static code analysis tool
  MUST be applied to any proposed major production release of the software
  before its release, if there is at least one FLOSS tool that implements this
  criterion in the selected language.
  A static code analysis tool examines the software code
  (as source code, intermediate code, or executable)
  without executing it with specific inputs.
  For purposes of this criterion, compiler warnings and "safe"
  language modes do not count as static code analysis tools
  (these typically avoid deep analysis because speed is vital).
  Examples of such static code analysis tools include
  [cppcheck](http://cppcheck.sourceforge.net/),
  [clang static analyzer](http://clang-analyzer.llvm.org/),
  [FindBugs](http://findbugs.sourceforge.net/)
  (including [FindSecurityBugs](https://h3xstream.github.io/find-sec-bugs/)),
  [PMD](https://pmd.github.io/),
  [Brakeman](http://brakemanscanner.org/),
  [Coverity Quality Analyzer](https://scan.coverity.com/),
  and [HP Fortify Static Code Analyzer](http://www8.hp.com/au/en/software-solutions/static-code-analysis-sast/).
  Larger lists of tools can be found in places such as the
  [Wikipedia list of tools for static code analysis](https://en.wikipedia.org/wiki/List_of_tools_for_static_code_analysis),
  [OWASP information on static code analysis](https://www.owasp.org/index.php/Static_Code_Analysis),
  [NIST list of source code security analyzers](http://samate.nist.gov/index.php/Source_Code_Security_Analyzers.html),
  and [Wheeler's list of static analysis tools](http://www.dwheeler.com/essays/static-analysis-tools.html).
  The [SWAMP](https://continuousassurance.org/) is a no-cost platform
  for assessing vulnerabilities in software using a variety of tools.
  <sup>[<a href="#static_analysis">static_analysis</a>]\*</sup>
- <a name="static_analysis_common_vulnerabilities"></a>It is SUGGESTED
  that the tool include rules or approaches to look for common
  vulnerabilities in the analyzed language or environment.
  <sup>[<a href="#static_analysis_common_vulnerabilities">static_analysis_common_vulnerabilities</a>]\*</sup>
- <a name="static_analysis_fixed"></a>All confirmed medium
  and high severity exploitable vulnerabilities discovered
  with static code analysis MUST be fixed.
  A vulnerability is medium to high severity if its
  [CVSS 2.0](https://nvd.nist.gov/cvss.cfm) is 4 or higher.
  <sup>[<a href="#static_analysis_fixed">static_analysis_fixed</a>]\*</sup>
- <a name="static_analysis_often"></a>It is SUGGESTED that
  static source code analysis occur on every commit or at least daily.
  <sup>[<a href="#static_analysis_often">static_analysis_often</a>]\*</sup>

*Dynamic analysis*

- <a name="dynamic_analysis"></a>It is SUGGESTED that at least one
  dynamic analysis tool be applied to any proposed major production
  release of the software before its release.
  A dynamic analysis tool examines the software by executing
  it with specific inputs.
  For example, the project MAY use a fuzzing tool
  (e.g., [American Fuzzy Lop](http://lcamtuf.coredump.cx/afl/))
  or a web application scanner
  (e.g., [OWASP ZAP](https://www.owasp.org/index.php/OWASP_Zed_Attack_Proxy_Project)
  or [<a href="(https://w3af.org/)">w3af</a>](http://w3af.org/)).
  For purposes of this criterion the dynamic analysis tool needs to vary
  the inputs in some way to look for various kinds of problems *or*
  be an automated test suite with at least 80% branch coverage.
  The [Wikipedia page on dynamic analysis](https://en.wikipedia.org/wiki/Dynamic_program_analysis)
  and the [OWASP page on fuzzing](https://www.owasp.org/index.php/Fuzzing)
  identify some dynamic analysis tools.
  <sup>[<a href="#dynamic_analysis">dynamic_analysis</a>]</sup>
- <a name="dynamic_analysis_unsafe"></a>It is SUGGESTED that if the
  software is application-level software written using a memory-unsafe language
  (such as C or C++) then at least one tool to detect memory safety
  problems will be used during at least one dynamic tool use.
  Examples of memory safety tools include Address Sanitizer (ASAN) and
  [valgrind](http://valgrind.org/).
  If the software is not application-level,
   or is not in a memory-unsafe language,
   then this criterion is automatically met.
   <sup>[<a href="#dynamic_analysis_unsafe">dynamic_analysis_unsafe</a>]</sup>
- <a name="dynamic_analysis_enable_assertions"></a>It is SUGGESTED that
  the software include many run-time assertions that are
  checked during dynamic analysis.
  <sup>[<a href="#dynamic_analysis_enable_assertions">dynamic_analysis_enable_assertions</a>]</sup>
- The analysis tool(s) MAY be focused on looking for security
  vulnerabilities, but this is not required.
- <a name="dynamic_analysis_fixed"></a>All confirmed medium and high
  severity exploitable vulnerabilities discovered with dynamic
  code analysis MUST be fixed.
  A vulnerability is medium to high severity if its
  [CVSS 2.0](https://nvd.nist.gov/cvss.cfm)
  base score is 4 or higher.
  <sup>[<a href="#dynamic_analysis_fixed">dynamic_analysis_fixed</a>]</sup>
- *Rationale*: Static source code analysis and dynamic
  analysis tend to find different kinds of defects
  (including defects that lead to vulnerabilities),
  so combining them is more likely to be effective.


## Non-criteria

We plan to *not* require any specific products or services.
In particular, we plan to *not* require
proprietary tools or services,
since many [free software](https://www.gnu.org/philosophy/free-sw.en.html)
developers would reject such criteria.
Therefore, we will intentionally *not* require git or GitHub.
We will also not require or forbid any particular programming language
(though for some programming languages we may be able to make
some recommendations).
This also means that as new tools and capabilities become available,
projects can quickly switch to them without failing to meet any criteria.
However, the criteria will sometimes identify
common methods or ways of doing something
(especially if they are FLOSS) since that information
can help people understand and meet the criteria.
We do plan to create an "easy on-ramp" for projects using git on GitHub,
since that is a common case.
We would welcome good patches that help provide an "easy on-ramp" for
projects on other repository platforms.

We do not plan to require active user discussion within a project.
Some highly mature projects rarely change and thus may have little activity.
We *do*, however, require that the project be responsive
if vulnerabilities are reported to the project (see above).

## Uniquely identifying a project

One challenge is uniquely identifying a project.
Our rails application gives a unique id to each new project, so
we can certainly use that id to identify projects.
However, that doesn't help people who searching for the project
and do not already know that id.

The *real* name of a project, for our purposes, is the
project "front page" URL and/or the URL for its repository.
Most projects have a human-readable name, but these names are not enough.
The same human-readable name can be used for many different projects
(including project forks), and the same project may go by many different names.
In many cases it will be useful to point to other names for the project
(e.g., the source package name in Debian, the package name in some
language-specific repository, or its name in OpenHub).

In the future we may try to check more carefully that a user can
legitimately represent a project.
For the moment, we primarily focus on checking if GitHub repositories
are involved; there are ways to do this for other situations if that
becomes important.
We expect that users will *not* be able to edit the URL in most cases,
since if they could, they might fool people into thinking they controlled
a project that they did not.
That said, creating a bogus row entry does not really help someone very
much; what matters is the id used by the project when it refers to its
badge, and the project determines that.

Thus, a badge would have its URL as its name, year range, and level/name
(once there is more than one).

We will probably implement some search mechanisms so that people can
enter common names and find projects.


## Why have criteria?

The paper [Open badges for education: what are the implications at the
intersection of open systems and badging?](http://www.researchinlearningtechnology.net/index.php/rlt/article/view/23563)
identifies three general reasons for badging systems (all are valid for this):

1. Badges as a motivator of behavior.  We hope that by identifying
   best practices, we'll encourage projects to implement those
   best practices if they do not do them already.
2. Badges as a pedagogical tool.  Some projects may not be aware
   of some of the best practices applied by others,
   or how they can be practically applied.
   The badge will help them become aware of them and ways to implement them.
3. Badges as a signifier or credential.
   Potential users want to use projects that are applying best
   practices to consistently produce good results; badges make it easy
   for projects to signify that they are following best practices,
   and make it easy for users to see which projects are doing so.

We have chosen to use self-certification, because this makes it
possible for a large number of projects (even small ones) to
participate.  There's a risk that projects may make false claims,
but we think the risk is small, and users can check the claims for themselves.


## Improving the criteria

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
