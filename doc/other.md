# Other potential future criteria

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

Here are some other potential criteria.

We currently plan to launch with a single badge level (once it is ready).
There may eventually be multiple levels or
other badges (with a prerequisite) later.
We are currently leaning towards using the silver/gold/platinum naming system,
which is similar to the
[LEED certification naming system of certified, silver, gold, platinum](http://www.usgbc.org/leed) and how the
[Linux Foundation ranks membership (silver, gold, platinum)](http://www.linuxfoundation.org/about/members)
An alternative is the Olympic system naming (bronze, silver, gold).

To help organize these potential criteria, they are currently grouped
in terms of a potential future silver, potential future gold, and
other potential criteria.
There is no guarantee that the final criteria will be the same,
or even grouped the same way.
This list of potential future criteria is even less mature than the
initial list of best practices; recommendations welcome.
As the criteria become more mature, we expect some criteria to move between
the current criteria and these potential future criteria (in both directions).
In particular, we expect a number of the SHOULD or RECOMMENDED criteria
at lower levels to become MUST in higher/later badges.

Eventually these criteria will be worded per
[RFC 2119](https://tools.ietf.org/html/rfc2119).


## Potential silver criteria

*   **Achieve the lower (passing) badge**.
*   **Turn many should/suggested into MUST**
*   **Build and test:**
    -   **Continuous integration**.<br />
        An automated test suite MUST applied on each check-in to a shared
        repository, at least for some branches,
        with a generated report available to at least project members on
        success or failure of the tests.
        This test suite SHOULD be applied across many platforms where
        appropriate.
        *Rationale*:  Continuous integration provides much more rapid feedback
        on whether or not changes will cause test failures,
        including regressions.
    -   *Tests are rigorously added for new functionality*.<br />
        There MUST be a stated policy that when major new functionality is
        added, tests of that functionality MUST be added to an automated test
        suite, at least in the documentation for creating change proposals.
        There MUST be evidence that such tests are being added in the most
        recent major changes to the project.
    -   *Regression tests*.<br />
        When a bug is fixed, a regression test MUST normally be added to the
        automated test suite to prevent its reoccurrence.
    -   *Reproduceable build*.
        It MUST be possible to rebuild executables that are bit-for-bit
        identical, given the same executables of the tools used for building.
        This criterion is automatically met if there is no process for
        creating a separate executable or package.
        *Rationale*:  Reproduceable builds make it much easier to verify that
        the executable and source code of a program correspond,
        countering certain kinds of malicious attacks.
        (Proposed for main criteria.)
*   Documentation
    - <a name="documentation-architecture"></a>
        The project MUST include reference documentation that describes
        its architecture.
        <sup>[<a href="#documentation-architecture">documentation-architecture</a>]</sup>
    - <a name="documentation-interface"></a>
        The project MUST include reference documentation that describes
        its interface.
        <sup>[<a href="#documentation-interface">documentation-interface</a>]</sup>
    - <a name="documentation-dataflow"></a>
        The project MUST include reference documentation that describes
        its data flow.
        <sup>[<a href="#documentation-dataflow">documentation-dataflow</a>]</sup>
    - The project's documentation MUST be consistent with the current
      version of the program.
      Documentation of other versions MAY be included.
*   Code/build requirements:
    -   Coding standards / coding style guide
        (typically by pointing to something).
        There are a number of coding standards that can be recommended
        for specific languages.
        Widely used coding standards that include ways to reduce the likelihood
        of defects (including vulnerabilities) might be especially helpful.
        Projects can create their own coding standard by referring to
        an existing one and then adding their own additions or exceptions.
        There are a number of secure coding standards,
        e.g., the SEI CERT's at <https://www.securecoding.cert.org/>
    -   Program can use the local version of system library/applications
        (so vulnerable ones easily replaced).
        Many FLOSS programs are distributed with "convenience libraries"
        that are local copies of standard libraries (possibly forked).
        However, if the program *must* use these local (forked) copies,
        then updating the "standard" libraries as a security update will
        leave these additional copies still vulnerable.
        This is especially an issue for cloud-based systems (e.g., Heroku);
        if the cloud provider updates their "standard" libaries but the program
        won't use them, then the updates don't actually help.
        In some cases it's important to use the "other" version;
        the goal here is to make it *possible* to easily use the
        standard version.
        See, e.g., <http://spot.livejournal.com/312320.html> .
*   Bus factor aka truck factor:
    -   No one developer should be indispensible.
        If a developer was killed or incapacitated ("hit by a bus"),
        the project should be able to continue.
        [Truck-Factor](https://github.com/mtov/Truck-Factor) can
        calculate this for projects on GitHub.
        See [Assessing the Bus Factor of Git Repositories](https://www.researchgate.net/publication/272824568_Assessing_the_Bus_Factor_of_Git_Repositories)
        by Cosentino et al.
*   Security analysis:
    -   Dependencies (including embedded dependencies) are periodically checked
        for known vulnerabilities
        (using an origin analyzer, e.g., Sonatype, Black Duck,
        Codenomicon AppScan, OWASP Dependency-Check),
        and if they have known vulnerabilities,
        they are updated or verified as unexploitable.
        It is acceptable if the components' vulnerability cannot be exploited,
        but this analysis is difficult and it is sometimes easier to
        simply update or fix the part.
        Developers must periodically re-scan to look for newly found publicly
        known vulnerabilities in the components they use,
        since new vulnerabilities are continuously being discovered.
*   Release:
    -   Releases MUST be cryptographically signed.
        These may be implemented as signed git tags
        (using cryptographic digital signatures).
        There MUST be a documented process explaining how users can obtain
        the public keys used for signing and how to verify the signature.
    -   Releases MUST be downloadable through a channel that both encrypts
        and authenticates (e.g., TLS).
        That way, third parties will not be able to determine exactly what
        version is being downloaded.  This also provides some verification that
        the correct software is being downloaded from the site.
* Cryptography
    -    <a name="crypto_alternatives"></a>The project SHOULD support multiple
  cryptographic algorithms, so users can quickly switch if one is broken.
  Common symmetric key algorithms include AES, Twofish, Serpent,
  Blowfish, and 3DES.
  Common cryptographic hash algorithm alternatives include SHA-2
  (including SHA-224, SHA-256, SHA-384 and SHA-512) and SHA-3.
  However, see discussion per
  [issue #215](https://github.com/linuxfoundation/cii-best-practices-badge/issues/215)

It would be quite plausible to add many requirements specific to security.
For example, it would be plausible to require that a system meet the
requirements (or a specified subset) of the
[OWASP Application Security Verification Standard Project](https://www.owasp.org/index.php/Category:OWASP_Application_Security_Verification_Standard_Project)
or the
[Securing Web Application Technologies (SWAT) Checklist](https://software-security.sans.org/resources/swat).
Note that both of these focus only on web applications.


## Potential gold criteria

*   Achieve the lower (silver) badge.
*   General criteria:
    -   Roadmap exists.  There should be some information on where the
        project is or isn't going.
    -   Posted list of small project tasks for new users.
        These new tasks need not be adding functionality;
        they can be improving documentation, adding test cases,
        or anything else that aids the project and helps the contributor
        understand more about the project.
        There SHOULD be at least 3 small tasks made available
        over a one-year period
        that have been accepted by a relatively new contributor
        (those who started contributing less than a year ago) or left available
        (unimplemented by experienced developers) for at least 3 weeks.
        *Rationale*:  Identified small tasks make it easier for new potential
        contributors to become involved in a project, and projects with more
        contributors have an increased likelihood of continuing.
    -   Multiple contributors from more than one organization.
    -   License statement in each file (aka per-file licensing).
    -   (Ideal) Copyright notice in each file, e.g.,
        "Copyright [year project started] - [current year], [project founder]
        and the [project name] contributors."
*   Quality:
    -   Commits reviewed.  There should be evidence that at least one
        other person (other than the committer) are normally reviewing commits.
    -   Automated test suite covers 100% of branches in source code.
        We will *not* add 100% branch coverage to the *passing* set of criteria.
        Some projects (like SQLite) do achieve this, but for some projects
        (such as the Linux kernel)
        this would be exceptionally difficult to achieve.
        Some higher/different related badge *might* add 100% branch coverage.


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

We are considering moving the criteria continuous integration
and reproduceable builds into the initial best practices criteria.

In the future we might add some criteria that a project has to meet
some subset of (e.g., it must meet at least 3 of 5 criteria).


## Improving the criteria

We are hoping to get good suggestions and feedback from the public;
please contribute!

See [criteria](./criteria.md) for the main current set of criteria.
You may also want to see the "[background](./background.md)" file
for more information about these criteria,
and the "[implementation](./implementation.md)" notes
about the BadgeApp application.
