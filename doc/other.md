# Other potential future criteria

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

## Introduction

This document lists the draft potential criteria for badges.
We initially launched with a single badge level called "passing".
We're currently in the process of developing higher level badges.

For now, we'll use the terms "passing+1" and "passing+2" to refer to the
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


### Build and test

-   An automated test suite MUST be applied on each check-in to a shared
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

-   The project MUST have a formal written policy that as major
    new functionality is added, tests for it MUST be added to an automated
    test suite.
    <sup>[<a href="#test_policy_mandated">test_policy_mandated</a>]</sup>

    *Rationale*: This ensures that major new functionality is tested.
    This is related to the criterion test_policy, but is rewritten
    to be stronger.

-   The project MUST add regression tests to an automated test suite
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

-   <a name="build_repeatable"></a>
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

### Documentation

-   The project MUST have a documented roadmap that describes
    what the project intends to do and not do for at least the next year.
    The project might not achieve the roadmap, and that's fine;
    the purpose of the roadmap is to help potential users and
    constributors understand the intended direction of the project.
    It need not be detailed.

-   <a name="documentation_architecture"></a>
    The project MUST include reference documentation that describes
    its software architecture.
    A software architecture explains a program's fundamental structures,
    i.e., the program's major components, the relationships among them, and
    the key properties of these components and relationships.
    <sup>[<a href="#documentation_architecture">documentation_architecture</a>]</sup>

-   <a name="documentation_interface"></a>
    The project MUST provide reference documentation that describes
    its external interface (both input and output).
    Note that this may be automatically generated, e.g., 
    documentation of a REST interface may be generated using Swagger/OpenAPI,
    and code interfaces documentation may be generated using Doxygen.
    Merely having comments in code is not sufficient to satisfy this criterion.
    <sup>[<a href="#documentation_interface">documentation_interface</a>]</sup>

-   <a name="documentation_current"></a>
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

### Code/build requirements:

-   The project MUST identify the specific coding style guides
    for the primary languages it uses, and require that contributions
    comply with it (where exceptions occur, they MUST be rare and documented
    in the code at that locations).
    In most cases this is done by referring to some existing style guide(s),
    possibly listing differences, and then enforcing the style guide where
    possible using an automated style guide checker that is configured to match.
    These style guides can include ways to improve readability and
    ways to reduce the likelihood of defects (including vulnerabilities).
    Many programming languages have one or more widely-used style guides.
    Examples of style guides include
    [Google's style guides](https://github.com/google/styleguide) and
    [SEI CERT Coding Standards](https://www.securecoding.cert.org/).
    <sup>[<a href="#coding_standards">coding_standards</a>]</sup>

-   The project MUST make it easy to either
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

### Continuity

-   The project MUST be able to continue with minimal interruption
    if any one person is incapacitated or killed.
    In particular, the project MUST be able to create and close issues,
    accept proposed changes, and release versions of software, within a
    week of confirmation that an individual is incapacitated or killed.
    This MAY be done by ensuring someone else has any necessary
    keys, passwords, and legal rights to continue the project.
    <sup>[<a href="#access_continuity">access_continuity</a>]</sup>

-   The project SHOULD have a "bus factor" of 2 or more.
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

-   Projects MUST monitor or periodically check their dependencies
    (including embedded dependencies) to detect known vulnerabilities and
    fix exploitable vulnerabilities or verify them as unexploitable.
    This can be done using an origin analyzer / dependency checking tool
    such as
    [OWASP's Dependency-Check](https://www.owasp.org/index.php/OWASP_Dependency_Check),
    [Sonatype's Nexus Auditor](https://www.sonatype.com/nexus-auditor),
    [Black Duck's Protex](https://www.blackducksoftware.com/products/protex),
    [Synopsys' Protecode](http://www.protecode.com/), and
    [Bundler-audit (for Ruby)](https://github.com/rubysec/bundler-audit).
    It is acceptable if the components' vulnerability cannot be exploited,
    but this analysis is difficult and it is sometimes easier to
    simply update or fix the part.
    <sup>[<a href="#dependency_monitoring">dependency_monitoring</a>]</sup>

    *Rationale*:
    This must be monitored or periodically checked, because
    new vulnerabilities are continuously being discovered.

### Release

-   Project releases of the software intended for widespread use
    MUST be cryptographically signed, and there MUST be a documented
    process explaining to users how they can obtain the public signing keys
    and verify the signature.
    These may be implemented as signed git tags
    (using cryptographic digital signatures).
    <sup>[<a href="#signed_releases">signed_releases</a>]</sup>

### Cryptography

-   <a name="crypto_agility"></a>
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


## Potential passing+2 criteria

*   Achieve the lower passing+1 badge.

-   The project SHOULD employ continuous integration, where
    the primary developers team integrate their work frequently.
    In most cases this means that each developer integrates at least daily.
    [continuous_integration]

    *Rationale*: See
    [Martin Fowler](http://martinfowler.com/articles/continuousIntegration.html)
    We realize that this can be difficult for some projects to apply,
    which is why it proposed as a SHOULD.

### General criteria

-   The project MUST clearly identify small tasks that can be performed
    by new or casual contributors.
    This identification is typically done by marking selected issues
    in an issue tracker, e.g., up-for-grabs, first-timers-only,
    "Small fix", microtask, or IdealFirstBug.
    These new tasks need not involve adding functionality;
    they can be improving documentation, adding test cases,
    or anything else that aids the project and helps the contributor
    understand more about the project.

    *Rationale*:  Identified small tasks make it easier for new potential
    contributors to become involved in a project, and projects with more
    contributors have an increased likelihood of continuing.

-   The project MUST have at least two unassociated significant
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

    *Rationale*: This reduces the risk of non-support if
    a single organization stops supporting the project as FLOSS.
    It also reduces the risk of malicious code insertion, since there
    is more independence between contributors.
    This covers the case where "two people work for company X, but
    only one is paid to work on this project" (because the non-paid person
    could still have many of the same incentives).
    It also covers the case where "two people got paid working for
    Red Cross for a day, but Red Cross doesn't use the project".

-   The project MUST include a license statement in each source file.
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

-   The project MUST have a second person review at least
    50% of all proposed modifications
    before release, to determine if it is a worthwhile modification and
    free of known issues which would argue against its inclusion.

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

???
    -   Automated test suite covers 100% of branches in source code.
        We will *not* add 100% branch coverage to the *passing* set of criteria.
        Some projects (like SQLite) do achieve this, but for some projects
        (such as the Linux kernel)
        this would be exceptionally difficult to achieve.
        Some higher/different related badge *might* add 100% branch coverage.

-   <a name="build_reproducible"></a>
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

    *Rationale*: If a project needs to be built but there is no working
    build system, then potential co-developers will not be able to easily
    contribute and many security analysis tools will be ineffective.
    Reproduceable builds counter malicious attacks that generate malicious
    executables, by making it easy to recreate the executable to determine
    if the result is correct.
    By itself, reproducible builds do not counter malicious compilers,
    but they can be extended to counter malicious compilers using
    processes such as diverse double-compiling (DDC).


## Potential other criteria

*   Issue tracking (This must be different for big projects like the Linux
    kernel; it is not clear how to capture that.):
    -   Issue tracking for defects.
    -   Issue tracking for requirements/enhancement requests.
    -   Bug/vulnerability report responsiveness,
        e.g., commitment to respond to any vulnerability
        report within (say) 14 days,
        or respond to all/nearly all bug reports (far more than 50%).
    -   If this is a project fork,
        actively working to become sustainable by either growing its community
        *or* working to heal the fork (e.g., contribute to the mainline).
*   Quality:
    -   Automated test suite covers >=X% branches of source code
        (80% considered good).
    -   Documented test plan.
*   Security:
    -   Public advisories issued for vulnerabilities,
        this could include advisories on the <https://SOMEWHERE/security> page
        and/or an "Announcement" mailing list for new versions
        (at least for security updates).
    -   All inputs from untrusted sources checked against whitelist
        (not a blacklist) and/or escaped before being transmitted
        to other users.
    -   Privileges limited/minimized.
    -   Attack surface documented and minimized.
    -   Automated regression test suite includes at least one check for
        rejection of invalid data for each input field.
        *Rationale:* Many regression test suites check only for perfect data;
        attackers will instead provide invalid data, and programs need to
        protect themselves against it.
    -   Developers contributing a majority of the software
        (over 50%) have learned how to develop secure software.
    -   Standard security advisory template and a pre-notification process
        (useful for big projects; see Xen project as an example).
    -   All inputs from potentially untrusted sources are checked to ensure
        they are valid (a *whitelist*).
        Invalid inputs are rejected.
        Note that comparing against a list of "bad formats" (a *blacklist*)
        is not enough.
        In particular, numbers are converted and checked if they are between
        their minimum and maximum (inclusive), and text strings are checked
        to ensure that they are valid text patterns.
    -   OWASP Application Security Verification Standard (ASVS).
    -   SANS' Securing Web Application Technologies (SWAT) criteria.
    -   Privacy requirements.  The distribution system does not reveal to
        third parties what software or version number is being distributed,
        or to who.
        The distribution system does not require users to identify
        themselves nor does it perform passive machine fingerprinting.
*   Security analysis:
    -   Current/past security review of the code.
    -   Must have a process for rapidly fixing vulnerabilities and
        releasing the updated software.
        Note that having a good test suite makes it easier
        to make changes and be
        confident the system still works.
        Also note that FLOSS projects are often embedded in larger systems and
        projects cannot control the larger projects they are in.
    -   An automated test suite must achieve at least an aggregate 80% branch
        coverage (the goal is to cover a significant portion of the program;
        this can be a combination of unit tests and larger integration tests).
*   Release:
    -   Executable binaries that are released (both DLL and EXE's on Windows)
        MUST be cryptographically signed (the goal is to allow application
        whitelisting systems to use the signature to allow applications to
        run rather then relying on path or hash based rules -
        this might be at odds with some users requirement to be able to
        build from source but I thought I'd raise it anyways).

-   The project MUST have active development.  At the least,
    questions are routinely answered, and proposed issues and changes are
    responded to.
    This could be
    demonstrated by active number of commits, issues opened and closed,
    discussion (e.g., in issues, mailing list, or whatever the project
    uses for discussion), multiple developers, etc.
    However, note that the criteria report_responses and enhancement_responses
    already take steps in this direction.
    Some projects are essentially "completed" and so have relatively
    little to respond to.

-   Test coverage.  See:
    https://lists.coreinfrastructure.org/pipermail/cii-badges/2016-December/000350.html
    Note that Ruby doesn't support branch testing.

We are considering moving the criteria continuous integration
and reproducible builds into the initial best practices criteria.

In the future we might add some criteria that a project has to meet
some subset of (e.g., it must meet at least 3 of 5 criteria).

## To be reviewed

-   Releases must be downloadable through a channel that both encrypts
    and authenticates (e.g., tls).
    that way, third parties will not be able to determine exactly what
    version is being downloaded.  this also provides some verification that
    the correct software is being downloaded from the site.
    (This is probably already covered by https_sites.)

-   Review all comment replies on
    https://lists.coreinfrastructure.org/pipermail/cii-badges/2016-December/000347.html

- It would be quite plausible to add many requirements specific to security.
for example, it would be plausible to require that a system meet the
requirements (or a specified subset) of the
[owasp application security verification standard project](https://www.owasp.org/index.php/category:owasp_application_security_verification_standard_project)
or the
[securing web application technologies (swat) checklist](https://software-security.sans.org/resources/swat).
note that both of these focus only on web applications.

## Keep thinking

These are criteria were are currently *not* planning to add.

-   Copyright notice in each file, e.g.,
    "Copyright [year project started] - [current year], [project founder]
    and the [project name] contributors."

    *Rationale*: It isn't legally required.
    That said,
    [Ben Balter's "Copyright notices for open source projects"](http://ben.balter.com/2015/06/03/copyright-notices-for-websites-and-open-source-projects/)
    provides a good argument for why it *should* be included,
    and it is not hard to add.

## Probably not

## Improving the criteria

We are hoping to get good suggestions and feedback from the public;
please contribute!

See [criteria](./criteria.md) for the main current set of criteria.
You may also want to see the "[background](./background.md)" file
for more information about these criteria,
and the "[implementation](./implementation.md)" notes
about the BadgeApp application.

