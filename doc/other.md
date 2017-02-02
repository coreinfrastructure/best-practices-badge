# Other criteria for higher-level badges

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

## Introduction

This document lists the draft potential criteria for badges
beyond the "passing" level.
We initially launched with a single badge level called "passing".
We're currently in the process of developing higher level badges.

For now, we use the terms "passing+1" and "passing+2" to refer to the
two levels above the current "passing" level.
There are various options for naming higher level badges.
We are currently leaning towards using the silver/gold/platinum naming system,
which is similar to the
[LEED certification naming system of certified, silver, gold, platinum](http://www.usgbc.org/leed) and how the
[Linux Foundation ranks membership (silver, gold, platinum)](http://www.linuxfoundation.org/about/members)
An alternative is the Olympic system naming (bronze, silver, gold).

To help organize these potential criteria, they are currently grouped
in terms of a potential future passing+1, potential future passing+2, and
other potential criteria.
There is no guarantee that the final criteria will be the same,
or even grouped the same way.
Recommendations welcome.

We expect a number of the SHOULD criteria to become MUST in higher level
badges, and SUGGESTED criteria at lower levels to become SHOULD or MUST
in higher level badges.

Eventually these criteria will be worded per
[RFC 2119](https://tools.ietf.org/html/rfc2119).

## Potential passing+1 criteria

You must achieve the lower (passing) badge.  In addition,
some SHOULD will become MUST, and some SUGGESTED will become
SHOULD or MUST.

* FIXME - list of upgrades of SHOULD and SUGGESTED.

    - Upgrade dynamic_analysis_unsafe from SUGGESTED to MUST.
      This would mean that C/C++ would be required to use something like
      ASAN during some testing/ and fuzz testing. See:
      <https://github.com/linuxfoundation/cii-best-practices-badge/issues/256>

### Test

*   An automated test suite MUST be applied on each check-in to a shared
    repository for at least one branch.  This test suite MUST
    produce a report on test success or failure.
    <sup>[<a href="#automated_integration_testing">automated_integration_testing</a>]</sup>

    *Rationale*: This is inspired by continuous integration.
    Continuous integration provides much more rapid feedback
    on whether or not changes will cause test failures,
    including regressions.  The term "continuous integration" (CI)
    is defined in Wikipedia as "merging all developer working copies
    to a shared mainline several times a day".
    [Martin Fowler](http://martinfowler.com/articles/continuousIntegration.html)
    says that
    "Continuous Integration is a software development practice where
    members of a team integrate their work frequently, usually each
    person integrates at least daily - leading to multiple integrations
    per day. Each integration is verified by an automated build (including
    test) to detect integration errors as quickly as possible. Many teams
    find that this approach leads to significantly reduced integration
    problems and allows a team to develop cohesive software more rapidly."
    However, while merging all developer working copies at this pace can
    be very useful, in practice many projects do not or cannot always do this.
    In practice, many developers maintain at least some branches that are
    not merged for longer than a day.

*   The project MUST have a formal written policy that as major
    new functionality is added, tests for it MUST be added to an automated
    test suite.
    <sup>[<a href="#test_policy_mandated">test_policy_mandated</a>]</sup>

    *Rationale*: This ensures that major new functionality is tested.
    This is related to the criterion test_policy, but is rewritten
    to be stronger.

*   The project MUST add regression tests to an automated test suite
    for at least 50% of the bugs fixed within the last six months.
    <sup>[<a href="#regression_tests_added50">regression_tests_added50</a>]</sup>

    *Rationale*: Regression tests prevent undetected resurfacing of
     defects.  If a defect has happened before, there is an increased
     likelihood that it will happen again.  We only require 50% of bugs to
     have regression tests; not all bugs are equally likely to recur,
     and in some cases it is extremely difficult to build robust tests for
     them.  Thus, there is a diminishing point of return for adding
     regression tests.  The 50% value could be argued as being arbitrary,
     however, requiring less than 50% would mean that projects could
     get the badge even if a majority of their bugs in the time frame
     would not have regression tests.  Projects may,
     of course, choose to have much larger percentages.
     We choose six months, as with other requirements, so that projects
     that have done nothing in the past (or recorded nothing in the past)
     can catch up in a reasonable period of time.

*   The project MUST have FLOSS automated test suite(s) that provide at least
    80% statement coverage if there is at least
    one FLOSS tool that can measure this criterion in the selected language.
    Many FLOSS tools are available to measure test coverage,
    including gcov/lcov, Blanket.js, Istanbul, and JCov.
    Note that meeting this criterion is not a guarantee that the
    test suite is thorough, instead, failing to meet this criterion is
    a strong indicator of a poor test suite.
    <sup>[<a href="#test_statement_coverage80">test_statement_coverage80</a>]</sup>

    *Rationale*: Statement coverage is widely used as a test quality measure;
    it's often a first "starter" measure for test quality.
    It's well-supported, including by gcov/lcov and codecov.io.
    Bad test suites could also meet this requirement, but it's generally
    agreed that any good test suite will meet this requirement, so it
    provides a useful way to filter out clearly-bad test suites.
    After all, if your tests aren't even *running* many of the program's
    statements, you don't have very good tests.
    Only FLOSS test suites are considered, to ensure that the test
    suite can be examined and improved over time.

    A good automated test suite enables rapid response
    to vulnerability reports.  If a vulnerability is reported to a project,
    the project may be able to quickly repair it, but that is not enough.
    A good automated test suite is necessary so the project can rapidly
    gain confidence that the repair doesn't break anything else so it can
    field the update.

    It could be argued that anything less than 100% is unacceptable, but
    this is not a widely held belief.
    There are many ways to determine if a program is correct -
    testing is only one of them.  Some conditions are hard to create
    during testing, and the return-on-investment to get those last few
    percentages is arguably not worth it.  The time working to get 100%
    statement coverage might be much better spent on checking the results
    more thoroughly (which statement coverage does *not* measure).

    The 80% suggested here is supported by various sources.
    The defaults of codecov.io
    <http://docs.codecov.io/docs/coverage-configuration>.  They define
    70% and below as red, 100% as perfectly green, and anything between
    70..100 as a range between red and green. This renders ~80% as yellow,
    and somewhere between ~85% and 90% it starts looking pretty green.

    The paper "Minimum Acceptable Code Coverage" by Steve
    Cornett <http://www.bullseye.com/minimum.html> claims, "Code
    coverage of 70-80% is a reasonable goal for system test of most
    projects with most coverage metrics. Use a higher goal for projects
    specifically organized for high testability or that have high failure
    costs. Minimum code coverage for unit testing can be 10-20% higher
    than for system testing... Empirical studies of real projects found
    that increasing code coverage above 70-80% is time consuming and
    therefore leads to a relatively slow bug detection rate. Your goal
    should depend on the risk assessment and economics of the project...
    Although 100% code coverage may appear like a best possible effort,
    even 100% code coverage is estimated to only expose about half the
    faults in a system. Low code coverage indicates inadequate testing,
    but high code coverage guarantees nothing."

    "TestCoverage" by Martin Fowler (17 April 2012)
    <http://martinfowler.com/bliki/TestCoverage.html> points out the
    problems with coverage measures.  he states that "Test coverage is
    a useful tool for finding untested parts of a codebase. Test coverage
    is of little use as a numeric statement of how good your tests are...
    The trouble is that high coverage numbers are too easy to reach with
    low quality testing... If you are testing thoughtfully and well,
    I would expect a coverage percentage in the upper 80s or 90s. I
    would be suspicious of anything like 100%... Certainly low coverage
    numbers, say below half, are a sign of trouble. But high numbers don't
    necessarily mean much, and lead to ignorance-promoting dashboards."

### Documentation

*   The project MUST have a documented roadmap that describes
    what the project intends to do and not do for at least the next year.
    The project might not achieve the roadmap, and that's fine;
    the purpose of the roadmap is to help potential users and
    constributors understand the intended direction of the project.
    It need not be detailed.
    <sup>documentation_roadmap</sup>

*   <a name="documentation_architecture"></a>
    The project MUST include reference documentation that describes
    its software architecture.
    A software architecture explains a program's fundamental structures,
    i.e., the program's major components, the relationships among them, and
    the key properties of these components and relationships.
    <sup>[<a href="#documentation_architecture">documentation_architecture</a>]</sup>

*   <a name="documentation_interface"></a>
    The project MUST provide reference documentation that describes
    its external interface (both input and output).
    Note that this may be automatically generated, e.g.,
    documentation of a REST interface may be generated using Swagger/OpenAPI,
    and code interfaces documentation may be generated using Doxygen.
    Merely having comments in code is not sufficient to satisfy this criterion.
    <sup>[<a href="#documentation_interface">documentation_interface</a>]</sup>
    ??? DUPLICATE?

*   <a name="documentation_security"></a>
    The project MUST document what the user can and cannot expect
    in terms of security.  This MUST identify the security requirements
    that the software is intended to meet and a justification
    ("assurance case") for why they are believed to have been met.
    <sup>[<a href="#documentation_security">documentation_security</a>]</sup>

    *Rationale*: Writing the specification helps the developers think about the
    interface (including the API) the developers are providing, as well
    letting any user or researcher know what to expect.
    This was inspired by
    [issue #502](https://github.com/linuxfoundation/cii-best-practices-badge/issues/502).

*   <a name="documentation_current"></a>
    The project MUST make an effort to
    keep the documentation consistent with the current version of the
    program and any known documentation defects making it inconsistent
    MUST be fixed.
    Documentation of other versions may be included.
    If the documentation is generally current, but erroneously
    includes some older information, just treat that as a defect, then
    track and fix as usual.  The intent of this criterion is that the
    documentation is kept consistent, not that the documentation
    must be perfect.
    *Rationale*: It's difficult to keep documentation up-to-date, so the
    criterion is worded this way to make it more practical.
    <sup>[<a href="#documentation_current">documentation_current</a>]</sup>

*   <a name="documentation_achievements"></a>
    The project repository front page and/or website MUST
    identify and hyperlink to any achievements,
    including this best practices badge, within 48 hours
    of public recognition that the achievement has been attained.
    An achievement is any set of external criteria that the project
    has specifically worked to meet, including some badges.
    This information does not need to be on the project website front page.
    A project using GitHub can put achievements on the repository front page
    by adding them to the README file.

    *Rationale*: Users and potential co-developers need to be able to
    see what achievements have been attained by a project they are considering
    using or contributing to.  This information can help them determine
    if they should.  In addition, if projects identify their achievements,
    other projects will be encouraged to follow suit and also make those
    achievements, benefitting everyone.

### Code/build requirements:

*   The project MUST identify the specific coding style guides
    for the primary languages it uses, and require that contributions
    generally comply with it.
    *Details*:
    In most cases this is done by referring to some existing style guide(s),
    possibly listing differences.
    These style guides can include ways to improve readability and
    ways to reduce the likelihood of defects (including vulnerabilities).
    Many programming languages have one or more widely-used style guides.
    Examples of style guides include
    [Google's style guides](https://github.com/google/styleguide) and
    [SEI CERT Coding Standards](https://www.securecoding.cert.org/).
    <sup>[<a href="#coding_standards">coding_standards</a>]</sup>

*   The project MUST automatically enforce its selected coding style(s)
    if there is at least one FLOSS tool that can do so in the selected
    language(s).
    *Details*:
    This MAY be implemented using static analysis tool(s) and/or by
    forcing the code through code reformatters.
    In many cases the tool configuration is included in the project's
    repository (since different projects may choose different configurations).
    Projects MAY allow style exceptions (and typically will);
    where exceptions occur, they MUST be rare and documented
    in the code at their locations, so that these exceptions can be reviewed
    and so that tools can automatically handle them in the future.
    Examples of such tools include ESLint (JavaScript) and Rubocop (Ruby).
    <sup>[<a href="#coding_standards_enforced">coding_standards_enforced</a>]</sup>

*   The project MUST make it easy to either
    (1) identify and update reused externally-maintained components or (2)
    use the standard components provided by the system or programming language.
    Then, if a vulnerability is found in a reused component, it will be
    easy to update that component.
    A typical way to meet this criterion is to use
    system and programming language package management systems.
    Many FLOSS programs are distributed with "convenience libraries"
    that are local copies of standard libraries (possibly forked).
    By itself, that's fine.
    However, if the program *must* use these local (forked) copies,
    then updating the "standard" libraries as a security update will
    leave these additional copies still vulnerable.
    This is especially an issue for cloud-based systems;
    if the cloud provider updates their "standard" libaries but the program
    won't use them, then the updates don't actually help.
    See, e.g.,
    ["Chromium: Why it isn't in Fedora yet as a proper package" by Tom Callaway](http://spot.livejournal.com/312320.html).
    <sup>[<a href="#updateable_reused_components">updateable_reused_components</a>]</sup>

*   <a name="build_standard_variables"></a>
    Build systems for native binaries MUST honor the relevant compiler and
    linker (environment) variables passed in to them (e.g., CC, CFLAGS,
    CXX, CXXFLAGS, and LDFLAGS) and pass them to compiler and linker
    invocations. A build system MAY extend them with additional flags;
    it MUST NOT simply replace provided values with its own.
    DETAILS: It should be easy to enable special build features like
    Address Sanitizer (ASAN), or to comply with distribution hardening
    best practices (e.g., by easily turning on compiler flags to do so).
    If no native binaries are being generated, select "N/A".

    *Rationale*: See
     <https://github.com/linuxfoundation/cii-best-practices-badge/issues/453>

*   <a name="build_preserve_debug"></a>
    The build and installation system SHOULD preserve debugging information if they are requested in the relevant flags (e.g., "install -s" is not used).
    If there is no build or installation system (e.g.,
    typical JavaScript libraries), this is N/A.
    *Details*: E.G., setting CFLAGS (C) or CXXFLAGS (C++) should create the
    relevant debugging information if those languages are used, and they
    should not be stripped during installation. Debugging information
    is needed for support and analysis, and also useful for measuring
    the presence of hardening features in the compiled binaries.

* <a name="build_non_recursive"></a>
  The project's build system MUST NOT recursively build subdirectories
  if there are cross-dependencies in the subdirectories.
  <sup>[<a href="#build_non_recursive">build_non_recursive</a>]</sup>
  *Details*: The project build system's internal dependency information
  needs to be
  accurate, otherwise, changes to the project may not build correctly.
  Incorrect builds can lead to defects (including vulnerabilities).
  A common mistake in large build systems is to use a "recursive build"
  or "recursive make", that is,
  a hierarchy of subdirectories containing source files,
  where each subdirectory is independently built.
  Unless each subdirectory is fully independent, this is a mistake,
  because the dependency information is incorrect.

  *Rationale*:
  For more information, see
  ["Recursive Make Considered Harmful" by Peter Miller](http://aegis.sourceforge.net/auug97.pdf)
  (note that this incorrect approach can be used in any build system,
  not just <i>make</i>).
  Note that ["Non-recursive Make Considered
  Harmful"](http://research.microsoft.com/en-us/um/people/simonpj/papers/ghc-shake/ghc-shake.pdf)
  agrees that recursive builds are bad; its argument is that
  for large projects you should use a tool other than make.
  In many cases it is better to automatically determine the dependencies,
  but this is not always accurate or practical, so we did not require
  that dependencies be automatically generated.

*   <a name="build_repeatable"></a>
    The project MUST be able to repeat the process of
    generating information from source files and get exactly
    the same bit-for-bit result.
    If no building occurs
    (e.g., scripting languages where the source code
    is used directly instead of being compiled), select "N/A".
    GCC and clang users may find the -frandom-seed option useful;
    in some cases, this can resolved by forcing some sort order.
    More suggestions can be found at the
    [reproducible build](https://reproducible-builds.org/) site.
    <sup>[<a href="#build_repeatable">build_repeatable</a>]</sup>

    *Rationale*: This is a step towards having a
    [reproducible build](https://reproducible-builds.org/).
    This criterion is much easier to meet, because it does not require
    that external parties be able to reproduce the results - merely
    that the project can.
    Supporting full reproducible builds requires that projects provide
    external parties enough information about their build environment(s),
    which can be harder to do - so we have split this requirement up.
    See the [reproducible build criterion](#reproducible_build).

* <a name="installation_common"></a>(Future criterion) The
  project MUST provide a way for end-users to easily install and
  uninstall the software using a commonly-used convention.  <sup>[<a
  href="#installation_common">installation_common</a>]</sup><dl><dt><i>Details</i>:<dt>
  <dd>Examples include using a language-level package manager (such as npm,
  pip, maven, or bundler), system-level package manager (such as apt-get
  or dnf), "make install/uninstall" (supporting DESTDIR), a container in
  a standard format, or a virtual machine image in a standard format. The
  installation and uninstallation process (e.g., its packaging) MAY be
  implemented by a third party as long as it is FLOSS.</dd></dl>

*   <a name="installation_standard_variables"></a>
    The installation system for end-users MUST honor standard conventions for
    selecting the location where built artifacts are written to
    at installation time.  For example, if it installs
    files on a POSIX system it MUST honor the DESTDIR environment variable.
    If there is no installation system or no standard convention,
    select "N/A".

    *Rationale* : This supports capturing the artifacts (e.g., for analysis)
    without interfering with the build or installation system due to
    system-wide changes. See
    <https://github.com/linuxfoundation/cii-best-practices-badge/issues/455>
    This doesn't apply when there's no "installation" process, or
    when POSIX filesystems aren't supported during installation (e.g.,
    Windows-only programs).  See
    <https://github.com/linuxfoundation/cii-best-practices-badge/issues/453>

* <a name="installation_development_quick"></a>The
  project MUST provide a way for potential developers to quickly install all
  the project results and support environment necessary to make changes,
  including the tests and test environment.
  This MUST be performed with a commonly-used convention.
  <sup>[<a
  href="#installation_development_quick">installation_development_quick</a>]</sup><dl><dt><i>Details</i>:<dt>
  <dd>
  This MAY be implemented using a generated container and/or
  installation script(s).
  External dependencies would typically be installed by invoking
  system and/or language package manager(s), per external_dependencies.
  </dd></dl>

*   <a name="external_dependencies"></a>
    The project MUST list external dependencies in a computer-processable
    way.
    <sup>[<a href="#external_dependencies">external_dependencies</a>]</sup>
    *Details*:
    Typically this is done using the conventions of package manager
    and/or build system.
    Note that this helps implement installation_development_quick.

### Continuity

*   The project MUST be able to continue with minimal interruption
    if any one person is incapacitated or killed.
    In particular, the project MUST be able to create and close issues,
    accept proposed changes, and release versions of software, within a
    week of confirmation that an individual is incapacitated or killed.
    This MAY be done by ensuring someone else has any necessary
    keys, passwords, and legal rights to continue the project.
    Individuals who run a FLOSS project MAY do this by providing keys in
    a lockbox and a will providing any needed legal rights
    (e.g., for DNS names).
    <sup>[<a href="#access_continuity">access_continuity</a>]</sup>

*   The project SHOULD have a "bus factor" of 2 or more.
    A "bus factor" (aka "truck factor") is the
    minimum number of project members that have to suddenly disappear from
    a project ("hit by a bus") before the project stalls
    due to lack of knowledgeable or competent personnel.
    The [truck-factor](https://github.com/mtov/truck-factor) tool can
    estimate this for projects on GitHub.  For more information, see
    [Assessing the Bus Factor of Git Repositories](https://www.researchgate.net/publication/272824568_assessing_the_bus_factor_of_git_repositories)
    by Cosentino et al.
    <sup>[<a href="#bus_factor">bus_factor</a>]</sup>

### Security analysis

*   Projects MUST monitor or periodically check their external dependencies
    (including convenience copies) to detect known vulnerabilities, and
    fix exploitable vulnerabilities or verify them as unexploitable.
    *Details*:
    This can be done using an origin analyzer / dependency checking tool
    such as
    [OWASP's Dependency-Check](https://www.owasp.org/index.php/OWASP_Dependency_Check),
    [Sonatype's Nexus Auditor](https://www.sonatype.com/nexus-auditor),
    [Black Duck's Protex](https://www.blackducksoftware.com/products/protex),
    [Synopsys' Protecode](http://www.protecode.com/), and
    [Bundler-audit (for Ruby)](https://github.com/rubysec/bundler-audit).
    Some package managers include mechanisms to do this.
    It is acceptable if the components' vulnerability cannot be exploited,
    but this analysis is difficult and it is sometimes easier to
    simply update or fix the part.
    <sup>[<a href="#dependency_monitoring">dependency_monitoring</a>]</sup>

    *Rationale*:
    This must be monitored or periodically checked, because
    new vulnerabilities are continuously being discovered.

### Release

*   Project releases of the software intended for widespread use
    MUST be cryptographically signed, there MUST be a documented
    process explaining to users how they can obtain the public signing keys
    and verify the signature. The private key for this signature MUST NOT
    be on site(s) used to directly distribute the software to the public.
    This includes both source code and executables (where applicable).
    Executables MAY be signed separately from source code.
    These may be implemented as signed git tags
    (using cryptographic digital signatures).
    <sup>[<a href="#signed_releases">signed_releases</a>]</sup>

    *Rationale*:
    This provides protection from compromised distribution systems.
    The public key must be accessible so that recipients can check the
    signature.  The private key must not be on sites(s) distributing the
    software to the public; that way, even if those sites are compromised,
    the signature cannot be altered.  This is sometimes called "code signing".
    A common way to implement this is by using GPG to sign the code,
    for example, the GPG keys of every person who signs releases
    could be in the project README.
    Node.js implements this via GPG keys in the README, but note that
    in the criterion we are intentionally more general:
    <https://github.com/nodejs/node#release-team>

### Cryptography

*   <a name="crypto_agility"></a>
    The project SHOULD support multiple
    cryptographic algorithms, so users can quickly switch if one is broken.
    Common symmetric key algorithms include AES, Twofish, and Serpent.
    Common cryptographic hash algorithm alternatives include SHA-2
    (including SHA-224, SHA-256, SHA-384 AND SHA-512) and SHA-3.
    <sup>[<a href="#crypto_agility">crypto_agility</a>]</sup>

    *Rationale*:
    The advantage of crypto agility is that if one crypto algorithm is
    broken, other algorithms can be used instead.
    Many protocols, including TLS and IPSEC, are specifically designed to
    support crypto agility.
    There is disagreement by some experts who argue that this
    negotiation can itself be a point of attack, and that
    people should instead simply choose and stay with with one good algorithm.
    The problem with this position is that no one can be certain about
    what that "one good algorithm" is; a new attack could be found at any time.
    See the discussion per
    [issue #215](https://github.com/linuxfoundation/cii-best-practices-badge/issues/215)

*   <a name="crypto_used_network"></a>(Future criterion) The project SHOULD NOT use unencrypted network communication protocols (such as HTTP and telnet) if there is an encrypted equivalent (e.g., HTTPS/TLS and SSH), unless the user specifically requests or configures it.
 (N/A allowed.) <sup>[<a href="#crypto_used_network">crypto_used_network</a>]</sup>

* <a name="crypto_tls12"></a>(Future criterion) The project SHOULD, if it supports TLS, support at least TLS version 1.2. Note that the predecessor of TLS was called SSL.
 (N/A allowed.) <sup>[<a href="#crypto_tls12">crypto_tls12</a>]</sup>

* <a name="crypto_certificate_verification"></a>(Future criterion) The project MUST, if it supports TLS, perform TLS certificate verification by default when using TLS, including on subresources.
 (N/A allowed.) <sup>[<a href="#crypto_certificate_verification">crypto_certificate_verification</a>]</sup><dl><dt><i>Details</i>:<dt> <dd>Note that having incorrect TLS certificate verification is a common mistake. For more information, see <a href="http://crypto.stanford.edu/~dabo/pubs/abstracts/ssl-client-bugs.html">"The Most Dangerous Code in the World: Validating SSL Certificates in Non-Browser Software" by Martin Georgiev et al.</a> and <a href="https://blogs.gnome.org/mcatanzaro/2016/03/12/do-you-trust-this-application/">"Do you trust this application?" by Michael Catanzaro</a>.
</dd></dl>

* <a name="crypto_verification_private"></a>(Future criterion) The project MUST, if it supports TLS, perform certificate verification before sending HTTP headers with private information (such as secure cookies).
 (N/A allowed.) <sup>[<a href="#crypto_verification_private">crypto_verification_private</a>]</sup>

### Accessibility

* Accessibility best practices SHOULD be followed so that
  persons with disabilities can still participate in the project and
  use the project results where it is reasonable to do so.
  *Details*:
  For web applications, see the [W3C accessibility information](https://www.w3.org/standards/webdesign/accessibility).
  For GUI applications, consider using the environment-specific
  accessibility guidelines (such as
  [Gnome](https://developer.gnome.org/accessibility-devel-guide/stable/),
  [KDE](https://accessibility.kde.org/),
  [XFCE](http://docs.xfce.org/xfce/xfce4-settings/accessibility),
  [Android](https://developer.android.com/guide/topics/ui/accessibility/),
  [iOS](https://developer.apple.com/accessibility/ios/),
  [Mac](http://www.apple.com/accessibility/osx/voiceover/), and
  [Windows](https://msdn.microsoft.com/en-us/windows/uwp/accessibility/accessibility-overview)).
  Some TUI applications (e.g. `ncurses` programs) can do
  certain things to make themselves more accessible (such as `alpine`'s
  `force-arrow-cursor` setting).
  Most command-line applications are fairly accessible as-is.
  This criterion is often N/A, e.g., for program libraries.
  Here are some examples of actions to take or issues to consider:

    - Neither color nor sound SHOULD be used as the only way information
      is conveyed
    - Color combinations SHOULD be tested in a high-contrast environment
    - If the software uses flashing or animation it SHOULD grant the user
      control to disable it
    - All applications SHOULD be tested for keyboard-only navigation
    - A GUI or web-based project SHOULD test with at least one
      screen-reader on the target platform(s) (e.g. NVDA, Jaws, or WindowEyes
      on Windows; VoiceOver on Mac & iOS; Orca on Linux/BSD; TalkBack on
      Android). TUI programs MAY work to reduce overdraw to prevent redundant
      reading by screen-readers.

### Other passing+1 criteria

*   <a name="implement_secure_design"></a>
    The project MUST implement secure design principles
    (from "know_secure_design") to the largest practical extent.
    This includes performing input validation with whitelists
    on all untrusted input.
    Note that in some cases principles will conflict, in which case
    a choice must be made
    (e.g., many mechanisms can make things more complex, contravening
    "economy of mechanism" / keep it simple)
    <sup>[<a href="#implement_secure_design">implement_secure_design</a>]</sup>

* <a name="hardening"></a>(Future criterion) Hardening mechanisms SHOULD be used so software defects are less likely to result in security vulnerabilities.
 <sup>[<a href="#hardening">hardening</a>]</sup><dl><dt><i>Details</i>:<dt> <dd>Hardening mechanisms may include HTTP headers like Content Security Policy (CSP), compiler flags to mitigate attacks (such as -fstack-protector), or compiler flags to eliminate undefined behavior. For our purposes least privilege is not considered a hardening mechanism (least privilege is important, but separate).
</dd></dl>

* <a name="warnings_strict"></a>
  Projects MUST be maximally strict with warnings, where practical.
  *Details*: Some warnings cannot be effectively enabled on some projects,
  or specific exceptions must be given.
  What is needed is evidence that the project is striving to enable
  warning flags where it can, so that errors are detected early.

* <a name="dco"></a>The project SHOULD have a legal mechanism where
  all developers of non-trivial amounts of project software assert that
  they are legally authorized to make these contributions. The most
  common and easily-implemented approach for doing this is by using a <a
  href="http://developercertificate.org/">Developer Certificate of Origin
  (DCO)</a>, where users add "signed-off-by" in their commits and
  the project links to the DCO website.
  However, this MAY be implemented as a
  Contributor License Agreement (CLA), or other legal mechanism.
  *Details*: The DCO is the recommended
  mechanism because it's easy to implement, tracked in the source code,
  and git directly supports a "signed-off" feature using "commit -s".
  To be most effective it is best if the project documentation
  explains what "signed-off" means for that project.
  A CLA is a legal agreement that defines
  the terms under which intellectual works have been licensed to an
  organization or project.  A contributor assignment agreement (CAA)
  is a legal agreement that transfers rights in an intellectual work
  to another party; projects are not required to have CAAs, since
  having CAA increases the risk that potential contributors
  will not contribute, especially if the receiver is a for-profit organization.

* <a name="code_of_conduct"></a>The project MUST adopt a code of conduct and post it in a standard location. <sup>code_of_conduct</sup>

  *Rationale*: Projects may be able to improve the civility of their
  community and to set expectations about acceptable conduct by adopting a
  code of conduct. This can help avoid problems before they occur and make
  the project a more welcoming place to encourage contributions. Example
  codes of conduct are the
  [Contributor Covenant Code of Conduct](http://contributor-covenant.org/)
  and the Linux kernel [Code of Conflict](https://www.kernel.org/doc/html/latest/process/code-of-conflict.html).

* <a name="governance"></a>The project MUST clearly define and document
  its project governance model (the way it makes decisions,
  including key roles).  <sup>governance</sup>

  *Details*: There needs to be some well-established documented way
  to make decisions and resolve disputes.
  In small projects, this may be as simple as "the project owner and lead
  makes all final decisions".
  There are various governance models, including benevolent dictator
  and formal meritocracy; for more details, see
  <a href="http://oss-watch.ac.uk/resources/governancemodels">Governance models</a>.
  The governance information does not need to document the possibility
  of creating a project fork, since that is always possible
  for FLOSS projects.

  *Rationale*:
  There are many different governance models used by a wide array of
  successful projects.  Therefore, we do not believe that we should
  specify a particular governance model.  However, we do think it is
  important to have a governance model, and clearly define it, so that
  all participants and potential participants will know how decisions
  will be made.

* <a name="documentation_design"></a>The project MUST include documentation of its high-level design (aka architecture), that is, documentation that identifies its major components and how they interact. <sup>documentation_design</sup>

  *Rationale*: Documenting the basic design makes it easier for potential
  new developers to understand its basics.
  This is related to know_secure_design, as well
  as implement_secure_design and proposed documentation_security.

* <a name="vulnerability_report_credit"></a>The project MUST give credit to the reporter(s) of all vulnerability reports resolved in the last 12 months, except for the reporter(s) who request anonymity.
 (N/A allowed.) <sup>[<a href="#vulnerability_report_credit">vulnerability_report_credit</a>]</sup><dl><dt><i>Details</i>:<dt> <dd>If there have been no vulnerabilities resolved in the last 12 months, choose "not applicable" (N/A).
</dd></dl></li>
  *Rationale*: It is only fair to credit those who provide vulnerability
  reports.  In many cases, the only reporter requirement is that
  they receive credit.  This is also important long-term, because giving
  credit encourages additional reporting.

* <a name="vulnerability_response_process"></a>The project MUST have a documented process for responding to vulnerability reports.
 <sup>[<a href="#vulnerability_response_process">vulnerability_response_process</a>]</sup>

  *Details*: This is strongly related to vulnerability_report_process,
  which requires that there be a documented way to report vulnerabilities.
  It also related to vulnerability_report_response, which requires
  response to vulnerability reports within a certain time frame.

  *Rationale*: This is inspired by
  <a href="http://community.apache.org/apache-way/apache-project-maturity-model.html">Apache Project Maturity Model</a> QU30.

* <a name="maintenance_or_update"></a>
  The project MUST maintain the most often used older versions of the product
  <i>or</i> provide an upgrade path to newer versions.
  If the upgrade path is difficult, the project MUST document how
  to perform the upgrade (e.g., the interfaces that have changed and
  detailed suggested steps to help upgrade).
  <sup>[<a href="#maintenance_or_update">maintenance_or_update</a>]</sup>

  *Rationale*:
  This was inspired by
  https://projects.ow2.org/bin/view/ow2/OMM DFCT-1.2

## Potential passing+2 criteria

* Achieve the lower passing+1 badge.

* FIXME - list of upgrades of SHOULD and SUGGESTED from passing and passing+1.

    - E.g., MUST have bus factor of 2 or more.
    - Change "report_tracker" to MUST, to require issue tracking.
      Using GitHub issues meets this.
      Note that the Linux kernel project has reported that this is very
      hard to do at their scale.
      NOTE: Kevin Wall thinks this should be at passing+1, not passing+2.

### General criteria

*   The project SHOULD employ continuous integration, where
    the primary developers team integrate their work frequently.
    In most cases this means that each developer integrates at least daily.
    [continuous_integration]
    ??? NOTE: There's at least one other "continuous_integration" criterion
    draft text, and there's difference in what CI means to people.

    *Rationale*: See
    [Martin Fowler](http://martinfowler.com/articles/continuousIntegration.html)
    We realize that this can be difficult for some projects to apply,
    which is why it proposed as a SHOULD.

*   The project MUST clearly identify small tasks that can be performed
    by new or casual contributors.
    This identification is typically done by marking selected issues
    in an issue tracker with one or more tags the project uses
    for the purpose, e.g.,
    [up-for-grabs](http://up-for-grabs.net/#/),
    [first-timers-only](http://www.firsttimersonly.com/),
    "Small fix", microtask, or IdealFirstBug.
    These new tasks need not involve adding functionality;
    they can be improving documentation, adding test cases,
    or anything else that aids the project and helps the contributor
    understand more about the project.
    <sup>[<a href="#small_tasks">small_tasks</a>]</sup>

    *Rationale*:  Identified small tasks make it easier for new potential
    contributors to become involved in a project, and projects with more
    contributors have an increased likelihood of continuing.
    [Alluxio uses SMALLFIX](http://www.alluxio.org/docs/master/en/Contributing-to-Alluxio.html) and
    [OWASP ZAP uses IdealFirstBug](https://github.com/zaproxy/zaproxy/issues?q=is%3Aopen+is%3Aissue+label%3AIdealFirstBug).
    This is related to criterion installation_development_quick.

*   The project MUST have at least two unassociated significant
    contributors.
    Contributors are associated if they are paid to work
    by the same organization (as an employee or contractor)
    and the organization stands to benefit from the project's results.
    Financial grants do not count as being from the same organization
    if they pass through other organizations
    (e.g., science grants paid to different organizations
    from a common government or NGO source do not cause contributors
    to be associated).
    Someone is a significant contributor if they have made non-trivial
    contributions to the project in the past year.
    Examples of good indicators of a significant contributor are:
    written at least 1,000 lines of code, contributed 50 commits, or
    contributed at least 20 pages of documentation.
    <sup>[<a href="#contributors_unassociated">contributors_unassociated</a>]</sup>

    *Rationale*: This reduces the risk of non-support if
    a single organization stops supporting the project as FLOSS.
    It also reduces the risk of malicious code insertion, since there
    is more independence between contributors.
    This covers the case where "two people work for company X, but
    only one is paid to work on this project" (because the non-paid person
    could still have many of the same incentives).
    It also covers the case where "two people got paid working for
    Red Cross for a day, but Red Cross doesn't use the project".

*   The project MUST have at least 50% of all proposed modifications
    reviewed before release by a person other than the author,
    to determine if it is a worthwhile modification and
    free of known issues which would argue against its inclusion.
    <sup>[<a href="#two_person_review">two_person_review</a>]</sup>

    *Rationale*: Review can counter many problems.
    The percentage here could be changed; 100% would be great but untenable for
    many projects.  We have selected 50%, because
    anything less than 50% would mean that most changes could go unreviewed.
    See, for example, the
    [Linux Kernel's "Reviewer's statement of oversight"](https://www.kernel.org/doc/Documentation/SubmittingPatches).
    Note that the set of criteria allow people within the same organization
    to review each others' work; it is better to require different
    organizations to review each others' work, but in many situations
    that is not practical.

*   The project MUST include a license statement in each source file.
    This may be done by including near the beginning
    of each file the following in a comment:
    ["SPDX-License-Identifier: [SPDX license expression]"](https://spdx.org/using-spdx#identifiers)
    (see [this tutorial](https://github.com/david-a-wheeler/spdx-tutorial) for more information).
    The project could also include, as a license statement, a stable URL
    pointing to the license text, or could include the full license text.
    Note that the criterion license_location requires the
    project license be in a standard location.
    <sup>[<a href="#license_per_file">license_per_file</a>]</sup>

    *Rationale*: Files are sometimes individually copied from one
    project into another.  Per-file license information increases the
    likelihood that the original license will be honored.
    SPDX provides a simple standard way to identify common licenses,
    without having to embed the full license text in each file;
    since this makes the criterion easier to do, we specifically mention it.
    Technically, the text after "SPDX-License-Identifier" is a
    SPDX license expression, not an identifier, but the tag
    "SPDX-License-Identifier" is what is used for backwards-compatibility.

### Quality

*   The project MUST have FLOSS automated test suite(s) that provide at least
    90% statement coverage if there is at least
    one FLOSS tool that can measure this criterion in the selected language.
    <sup>[<a href="#test_statement_coverage90">test_statement_coverage90</a>]</sup>

    *Rationale*: This increases the statement coverage requirement
    from the previous badge level, thus requiring even more
    thorough testing (by this measure).

*   The project MUST have FLOSS automated test suite(s) that provide at least
    80% branch coverage if there is at least
    one FLOSS tool that can measure this criterion in the selected language.
    <sup>[<a href="#test_branch_coverage80">test_branch_coverage80</a>]</sup>

    *Rationale*: This adds another test coverage requirement,
    again requiring more thorough testing.
    A program with many one-armed "if" statements could achieve
    100% statement coverage but only 50% branch coverage
    (if the tests only checked the "true" branches).
    Branch coverage is probably the second most common test coverage
    measure (after statement coverage), and is often added when
    a stricter measure of tests is used.
    Branch coverage is widely (but not universally) implemented.

*   <a name="build_reproducible"></a>
    The project MUST
    have a [reproducible build](https://reproducible-builds.org/).
    If no building occurs
    (e.g., scripting languages where the source code
    is used directly instead of being compiled), select "N/A".
    With reproducible builds, multiple parties can independently redo the
    process of generating information from source files and get exactly
    the same bit-for-bit result.
    GCC and clang users may find the -frandom-seed option useful;
    in some cases, this can resolved by forcing some sort order.
    The build environment (including the toolset) can often be defined
    for external parties by specifying the cryptographic hash of a
    specific container or virtual machine that they can use for rebuilding.
    The [reproducible builds project has documentation on how to do this](https://reproducible-builds.org/docs/).
    <sup>[<a href="#build_reproducible">build_reproducible</a>]</sup>

    TODO: There is an existing "build_reproducible" text, but this
    rewritten version is better.

    *Rationale*: If a project needs to be built but there is no working
    build system, then potential co-developers will not be able to easily
    contribute and many security analysis tools will be ineffective.
    Reproduceable builds counter malicious attacks that generate malicious
    executables, by making it easy to recreate the executable to determine
    if the result is correct.
    By itself, reproducible builds do not counter malicious compilers,
    but they can be extended to counter malicious compilers using
    processes such as diverse double-compiling (DDC).

* The project MUST require two-factor authentication (2FA)
  for developers for changing a central repository
  or accessing sensitive data (such as private vulnerability reports).
  This 2FA mechanism MAY use mechanisms without cryptographic mechanisms
  such as SMS, though that is not recommended.
  two_factor_authentication

  *Rationale*: 2FA is used by Node.js and the Linux kernel projects.
  See
  ["Linux Kernel Git Repositories Add 2-Factor Authentication" by
Kontin Ryabitsev](https://www.linux.com/blog/linux-kernel-git-repositories-add-2-factor-authentication)
  and
  ["Linux Foundation Protects Kernel Git Repositories With 2FA" by Eduard Kovacs](http://www.securityweek.com/linux-foundation-protects-kernel-git-repositories-2fa).

* The project's two-factor authentication (2FA) SHOULD use cryptographic
  mechanisms to prevent impersonation.  Short Message Service (SMS) based
  2FA, by itself, does not meet this criterion, since it is not encrypted.
  *Rationale*: SMS is easier and lower cost for many people,
  but it also provides much weaker security.  It has been argued
  that SMS isn't really 2FA at all; we permit it, because it's better
  than nothing, but we don't recommend it because of its weaknesses.
  [So Hey You Should Stop Using Texts for Two-Factor Authentication](https://www.wired.com/2016/06/hey-stop-using-texts-two-factor-authentication/)

## To be turned into criteria text

We intend to turn these into criteria text.

### Passing+1 to be created

*   All inputs from potentially untrusted sources are checked to ensure
    they are valid (a *whitelist*), if there are any restrictions on
    the data at all. A "MUST".
    Invalid inputs are rejected.
    Note that comparing against a list of "bad formats" (a *blacklist*)
    is not enough.
    In particular, numbers are converted and checked if they are between
    their minimum and maximum (inclusive), and text strings are checked
    to ensure that they are valid text patterns (valid UTF-8, length,
    syntax, etc.).  In rare cases data may need to be "anything at all"
    (e.g., a file uploader).

### Passing+2 to be created

*   Current/past security review of the code.
    Perhaps passing+2.  Ideally it would be independent, but that
    often requires a lot of money.
    Kevin Wall: "If passing+2 is going to be the highest back level, I'd
    also like to see some sort of mandatory code inspection (possibly
    SAST assisted), and when applicable, some sort of DAST (for APIs,
    probably just fuzzing), where failed tests would have to be added
    to the regression test suite."
    <sup>security_review</sup>

## Still considering as criteria

*   Developers contributing a majority of the software
        (over 50%) have learned how to develop secure software.
        Kevin Wall asked this question: "Exactly how would you measure
        that? Do you just except them to have some security-related
        certification or take some specific course or what?"

## Potential sources for other criteria

Here are some potential sources for criteria that need to be reviewed.

Review these larger criteria sets for things to add:

* It would be quite plausible to add many requirements specific to security.
  for example, it would be plausible to require that a system meet the
  requirements (or a specified subset) of the
  [owasp application security verification standard project](https://www.owasp.org/index.php/category:owasp_application_security_verification_standard_project)
  or the
  [securing web application technologies (swat) checklist](https://software-security.sans.org/resources/swat).
  note that both of these focus only on web applications.
  These are:

    - OWASP Application Security Verification Standard (ASVS)
      "provides a basis for testing web application technical security
      controls and also provides developers with a list of requirements
      for secure development."
    - SANS' Securing Web Application Technologies (SWAT) criteria.

In the future we might add some criteria that a project has to meet
some subset of (e.g., it must meet at least 3 of 5 criteria).

## Probably not

* Public advisories issued for vulnerabilities,
  this could include advisories on the <https://SOMEWHERE/security> page
  and/or an "Announcement" mailing list for new versions
  (at least for security updates).
  Often projects don't know (or are unsure) if they are vulnerabilities.

*   Automated regression test suite includes at least one check for
        rejection of invalid data for each input field.
        *Rationale:* Many regression test suites check only for perfect data;
        attackers will instead provide invalid data, and programs need to
        protect themselves against it.
        However, on many projects this would be a hard burden, and it's
        not clear it's necessarily worth it (there are diminishing returns).

* (Node.js)
    We're considering requiring GPG signing of all of their commits as well.
    Response: This is helpful, but somewhat onerous to *require*,
    especially for projects with a large number of commits.

*   Standard security advisory template and a pre-notification process
        (useful for big projects; see Xen project as an example).

*   Privacy requirements.  The distribution system does not reveal to
        third parties what software or version number is being distributed,
        or to who.
        The distribution system does not require users to identify
        themselves nor does it perform passive machine fingerprinting.
        Response: We'd like to add this, but the widespread use of
        "app stores" makes this kind of requirement untenable in
        many circumstances.  So we don't plan to add this.
        Maybe the EFF can help?!?

*   Copyright notice in each file, e.g.,
    "Copyright [year project started] - [current year], [project founder]
    and the [project name] contributors."
    *Rationale*: This isn't legally required.
    On the other hand, this is not hard to add.
    In addition,
    [Ben Balter's "Copyright notices for open source projects"](http://ben.balter.com/2015/06/03/copyright-notices-for-websites-and-open-source-projects/)
    provides a good argument for why it *should* be included:
    "First, someone may want to use your work in ways not allowed
    by your license; notices help them determine who to ask for
    permission. Explicit notices can help you prove that you and your
    collaborators really are the copyright holders. They can serve to put
    a potential infringer on notice by providing an informal sniff test to
    counter the “Oh yeah, well I didn’t know it was copyrighted”
    defense. For some users the copyright notice may suggest higher
    quality, as they expect that good software will include a notice...
    Git can track these things, but people may receive software outside
    of git or where the git history has not been retained."
    The question is, is this really that important?

### Probably not: Security Code review ideas from liujin28

liujin28 proposed some specifics for security code review in
<https://github.com/linuxfoundation/cii-best-practices-badge/pull/536>

Response: We think this is too detailed, and too restrictive to
specific situations.  Instead, we would want to discuss review, and
point to guidelines to follow (like CERT's).

* <a name="validate_the_tainted_array_index"></a>The direct data
  or the indirect data from the untrusted sources which is used as
  the array index MUST be ensured within a legal range.
  Input validation is always the best practices of secure coding.
  (e.g., [CERT](http://www.cert.org/secure-coding/research/secure-coding-standards.cfm),
  [OWASP](https://www.owasp.org/index.php/OWASP_Secure_Coding_Practices_-_Quick_Reference_Guide))
  A lot of vulnerabilities related to this topic.
  See the [CWE](http://cwe.mitre.org/data/definitions/129.html).
  <sup>[<a href="#validate_the_tainted_array_index">validate_the_tainted_array_index</a>]</sup>

* <a name="validate_the_tainted_buffer_length"></a>The direct data
  or the indirect data from the untrusted sources which is used as
  the buffer length for read/write MUST be ensured within a legal range.
  Input validation is always the best practices of secure coding.
  (e.g., [CERT](http://www.cert.org/secure-coding/research/secure-coding-standards.cfm),
  [OWASP](https://www.owasp.org/index.php/OWASP_Secure_Coding_Practices_-_Quick_Reference_Guide))
  A lot of vulnerabilities related to this topic.
  See the [CWE](http://cwe.mitre.org/data/definitions/119.html).
  <sup>[<a href="#validate_the_tainted_buffer_length">validate_the_tainted_buffer_length</a>]</sup>

* <a name="validate_the_tainted_loop_condiction"></a>The direct data
  or the indirect data from the untrusted sources which is used as
  the loop ending condiction MUST be avoided infinite loop or other logic mistake.
  Input validation is always the best practices of secure coding.
  (e.g., [CERT](http://www.cert.org/secure-coding/research/secure-coding-standards.cfm),
  [OWASP](https://www.owasp.org/index.php/OWASP_Secure_Coding_Practices_-_Quick_Reference_Guide))
  See the [CWE](http://cwe.mitre.org/data/definitions/606.html).
  <sup>[<a href="#validate_the_tainted_loop_condiction">validate_the_tainted_loop_condiction</a>]</sup>

* <a name="validate_the_tainted_string"></a>When copying from a string
  that is not a trusted source, it MUST ensure
  that there is enough space to hold the data and the end.
  Input validation is always the best practices of secure coding.
  (e.g., [CERT](http://www.cert.org/secure-coding/research/secure-coding-standards.cfm),
  [OWASP](https://www.owasp.org/index.php/OWASP_Secure_Coding_Practices_-_Quick_Reference_Guide))
  See the [CWE](http://cwe.mitre.org/data/definitions/120.html).
  <sup>[<a href="#validate_the_tainted_string">validate_the_tainted_string</a>]</sup>

* <a name="validate_the_tainted_integer_on_caculation"></a>The integer values
  from untrusted sources MUST be avoided the integer overflow or wraparound.
  (e.g., [CERT](http://www.cert.org/secure-coding/research/secure-coding-standards.cfm),
  [OWASP](https://www.owasp.org/index.php/OWASP_Secure_Coding_Practices_-_Quick_Reference_Guide))
  See the [CWE](http://cwe.mitre.org/data/definitions/190.html).
  <sup>[<a href="#validate_the_tainted_integer_on_caculation">validate_the_tainted_integer_on_caculation</a>]</sup>

* <a name="validate_the_malloc_size"></a>Appropriate size limits
  SHOULD be used to allocate memory from an unreliable source, and
  MUST check the return value of the allocate function.
  (e.g., [CERT](http://www.cert.org/secure-coding/research/secure-coding-standards.cfm),
  [OWASP](https://www.owasp.org/index.php/OWASP_Secure_Coding_Practices_-_Quick_Reference_Guide))
  See the [CWE](http://cwe.mitre.org/data/definitions/789.html).
  <sup>[<a href="#validate_the_malloc_size">validate_the_malloc_size</a>]</sup>

## To do

* Review proposed criteria changes (issues/PRs on GitHub)
* Review current non-MUST criteria in "passing"
* Review "Still considering as criteria"
* Review "Potential sources for other criteria"

## Improving the criteria

We are hoping to get good suggestions and feedback from the public;
please contribute!

See [criteria](./criteria.md) for the main current set of criteria.
You may also want to see the "[background](./background.md)" file
for more information about these criteria,
and the "[implementation](./implementation.md)" notes
about the BadgeApp application.

