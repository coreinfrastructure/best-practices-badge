# OpenSSF Best Practices Badge (formerly CII Best Practices Badge)

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

[![OpenSSF Best Practices](https://bestpractices.coreinfrastructure.org/projects/1/badge)](https://bestpractices.coreinfrastructure.org/projects/1)
[![CircleCI Build Status](https://circleci.com/gh/coreinfrastructure/best-practices-badge.svg?&style=shield)](https://app.circleci.com/pipelines/github/coreinfrastructure/best-practices-badge)
[![codecov](https://codecov.io/gh/coreinfrastructure/best-practices-badge/branch/master/graph/badge.svg)](https://codecov.io/gh/coreinfrastructure/best-practices-badge)
[![License](https://img.shields.io/:license-mit-blue.svg)](https://badges.mit-license.org)
[![openssf scorecards](https://api.securityscorecards.dev/projects/github.com/coreinfrastructure/best-practices-badge/badge)](https://api.securityscorecards.dev/projects/github.com/coreinfrastructure/best-practices-badge)

This project identifies best practices for
Free/Libre and Open Source Software (FLOSS)
and implements a badging system for those best practices.
The "BadgeApp" badging system is a simple web application
that lets projects self-certify that they meet the criteria
and show a badge.
The real goal of this project is to encourage projects to
apply best practices, and to help users determine which FLOSS projects do so.
We believe that FLOSS projects that implement best practices are more likely
to produce better software, including more secure software.

See the
*[OpenSSF Best Practices badge website](https://bestpractices.coreinfrastructure.org/)* if you want to try to actually get a badge.

This is the development site for the criteria and badge application
software that runs the website.
Feedback is very welcome via the
[GitHub site](https://github.com/coreinfrastructure/best-practices-badge)
as issues or pull (merge) requests.
There is also a
[mailing list](https://lists.coreinfrastructure.org/mailman/listinfo/cii-badges)
for general discussion.
This project was originally developed under the CII, but it
is now part of the
[Open Source Security Foundation (OpenSSF)](https://openssf.org/)
[Best Practices Working Group (WG)](https://github.com/ossf/wg-best-practices-os-developers).
The original name of the project was the CII Best Practices badge, but
it is now the OpenSSF Best Practices badge project.

Interesting pages include:

* Badging **[Criteria for the passing level](https://bestpractices.coreinfrastructure.org/criteria/0)**
* **[Criteria for all badging levels](https://bestpractices.coreinfrastructure.org/criteria)**
* Information on how to **[contribute](./CONTRIBUTING.md)**
* Information on **[our own security, including how to report vulnerabilities in our badge application](./SECURITY.md)**
* [Up-for-grabs](https://github.com/coreinfrastructure/best-practices-badge/labels/up-for-grabs)
  lists smaller tasks that may take 1-3 days, and are ideal for people
  new to the project (or FLOSS in general)
* **[Background](./docs/gbackground.md)** on Badging
* **[ChangeLog](./CHANGELOG.md)**
* **[Requirements](./docs/grequirements.md)** - our overall requirements
* **[Design](./docs/gdesign.md)** - our basic design
* Current **[implementation](./docs/gimplementation.md)**  - notes about the
  BadgeApp implementation
* **[security](./docs/gsecurity.md)**  - notes about BadgeApp security
* **[testing](./docs/gtesting.md)**  - notes about BadgeApp automated tests
* **[api](./docs/gapi.md)** - Application Programming Interface (API), including data downloads
* **[Installation](./docs/gINSTALL.md)**  - Installation and quick start
* **[Vetting](./docs/gvetting.md)**  - More about our vetting approach
* **[Roadmap](./docs/groadmap.md)**  - Roadmap (future plans)

## Summary of Best Practices Criteria "passing" level

This is a summary of the passing criteria, with requirements in bold:

* **Have a [stable website](docs/gcriteria.md#homepage_url)**, which says:
  - **[what it does](docs/gcriteria.md#description_good)**
  - **[how to get it](docs/gcriteria.md#interact)**
  - **[how to give feedback](docs/gcriteria.md#interact)**
  - **[how to contribute](docs/gcriteria.md#contribution)** and
    [preferred styles](docs/gcriteria.md#contribution_requirements)
* **[Explicitly specify](docs/gcriteria.md#license_location) a
  [FLOSS](docs/gcriteria.md#floss_license) [license](docs/criteria.md#floss_license_osi)**
* **[Support HTTPS on the project sites](docs/gcriteria.md#sites_https)**
* **[Document how to install and run (securely)](docs/gcriteria.md#documentation_basics),
  and [any API](docs/gcriteria.md#documentation_interface)**
* **Have a** [distributed](docs/gcriteria.md#repo_distributed)
  **[public version control system](docs/gcriteria.md#repo_public),
 including [changes between releases](docs/gcriteria.md#repo_interim)**:
  - **[Give each release a unique version](docs/gcriteria.md#version_unique)**, using
    [semantic versioning format](docs/gcriteria.md#version_semver)
  - **Give a [summary of changes for each release](docs/gcriteria.md#release_notes),
    [identifying any fixed vulnerabilities](docs/gcriteria.md#release_notes_vulns)**
* **Allow [bug reports to be submitted](docs/gcriteria.md#report_process),
  [archived](docs/gcriteria.md#report_archive)** and
  [tracked](docs/gcriteria.md#report_tracker):
  - **[Acknowledge](docs/gcriteria.md#report_responses)**/respond to bugs &
    [enhancement requests](docs/gcriteria.md#enhancement_responses), rather than
    ignoring them
  - **Have a [secure](docs/gcriteria.md#vulnerability_report_private),
    [documented process](docs/gcriteria.md#vulnerability_report_process) for
    reporting vulnerabilities**
  - **[Respond within 14 days](docs/gcriteria.md#vulnerability_report_response),
    and [fix vulnerabilities](docs/gcriteria.md#vulnerabilities_critical_fixed),
    [within 60 days if they're public](docs/gcriteria.md#vulnerabilities_fixed_60_days)**
* **[Have a build that works](docs/gcriteria.md#build)**, using
  [standard](docs/gcriteria.md#build_common_tools)
  [open-source](docs/gcriteria.md#build_floss_tools) tools
  - **Enable (and [fix](docs/gcriteria.md#warnings_fixed))
    [compiler warnings and lint-like checks](docs/gcriteria.md#warnings)**
  - **[Run other static analysis tools](docs/gcriteria.md#static_analysis) and
    [fix exploitable problems](docs/gcriteria.md#static_analysis_fixed)**
* **[Have an automated test suite](docs/gcriteria.md#test)** that
  [covers most of the code/functionality](docs/gcriteria.md#test_most), and
  [officially](docs/gcriteria.md#tests_documented_added)
  **[require new tests for new code](docs/gcriteria.md#test_policy)**
* [Automate running the tests on all changes](docs/gcriteria.md#test_continuous_integration),
  and apply dynamic checks:
  - [Run memory/behaviour analysis tools](docs/gcriteria.md#dynamic_analysis)
    ([sanitizers/Valgrind](docs/gcriteria.md#dynamic_analysis_unsafe) etc.)
  - [Run a fuzzer or web-scanner over the code](docs/gcriteria.md#dynamic_analysis)
* **[Have a developer who understands secure software](docs/gcriteria.md#know_secure_design)
  and [common vulnerability errors](docs/gcriteria.md#know_common_errors)**
* If cryptography is used:
  - **[Use public protocols/algorithm](docs/gcriteria.md#crypto_published)**
  - **[Don't re-implement standard functionality](docs/gcriteria.md#crypto_call)**
  - **[Use open-source cryptography](docs/gcriteria.md#crypto_floss)**
  - **[Use key lengths that will stay secure](docs/gcriteria.md#crypto_keylength)**
  - **[Don't use known-broken](docs/gcriteria.md#crypto_working)** or
    [known-weak](docs/gcriteria.md#crypto_weaknesses) algorithms
  - [Use algorithms with forward secrecy](docs/gcriteria.md#crypto_pfs)
  - **[Store any passwords with iterated, salted, hashes using a key-stretching algorithm](docs/gcriteria.md#crypto_password_storage)**
  - **[Use cryptographic random number sources](docs/gcriteria.md#crypto_random)**

## Summary of Best Practices Criteria for higher levels

Getting a passing badge is a significant achievement;
on average only about 10% of pursuing projects have a passing badge.
That said, some projects would like to meet even stronger criteria,
and many users would like projects to do so.
We have established two higher levels beyond passing: silver and gold.
The higher levels strengthen some of the passing criteria and add new
criteria of their own.

### Silver

Here is a summary of the silver criteria, with requirements in bold
(for details, see the [full list of silver criteria](docs/gother.md)):

* **[Use a DCO or similar](docs/gother.md#dco)**
* **[Define/document project governance](docs/gother.md#governance)**
* **[Another will have the necessary access rights if someone dies](docs/gother.md#access_continuity)**
* *["Bus factor" of 2 or more](docs/gother.md#bus_factor)*
* **[Document security requirements](docs/gother.md#security_requirements)**
* **[Have an assurance case explaining why security requirements are met](docs/gother.md#assurance_case)**
* **[Have a quick start guide](docs/gother.md#documentation_quick_start)**
* *[Follow accessibility best practices](docs/gother.md#accessibility_best_practices)*
* **[Pick & follow coding standards](docs/gother.md#coding_standards)**
* **[Monitor external dependencies to detect/fix known vulnerabilities](docs/gother.md#dependency_monitoring)**
* **[Tests have 80%+ statement coverage](docs/gother.md#test_statement_coverage80)**
* **[Project releases for widespread use are cryptographically signed](docs/gother.md#signed_releases)**
* **[Check all inputs from potentially untrusted sources for validity (using an allowlist)](docs/gother.md#input_validation)**
* *[Use hardening mechanisms](docs/gother.md#hardening)*

### Gold

Here is a summary of the gold criteria, with requirements in bold
(for details, see the [full list of gold criteria](docs/gother.md)):

* **[At least 2 unassociated significant contributors](docs/gother.md#contributors_unassociated)**
* **[Per-file copyright and license](docs/gother.md#copyright_per_file)**
* **[Use 2FA](docs/gother.md#require_2FA)**
* **[At least 50% of all modifications are reviewed by another](docs/gother.md#two_person_review)**
* **[Have a reproducible build](docs/gother.md#reproducible_build)**
* **[Use continuous integration](docs/gother.md#test_continuous_integration)**
* **[Statement coverage 90%+](docs/gother.md#test_statement_coverage90)**
* **[Branch coverage 80%+](docs/gother.md#test_branch_coverage80)**
* **[Support secure protocols & disable insecure protocols by default](docs/gother.md#crypto_used_network)**
* **[Use TLS version 1.2 or higher](docs/gother.md#crypto_tls12)**
* **[Have a hardened project website, repo, and download site](docs/gother.md#hardened_site)**
* **[Have a security review (internal or external)](docs/gother.md#security_review)**

## Directory "doc" is now "docs"

If you've used this system in the past, you may have referred to our `doc`
subdirectory for documentation. We have renamed that to a `docs` subdirectory.

## License

All material here is released under the [MIT license](./LICENSE).
All material that is not executable, including all text when not executed,
is also released under the
[Creative Commons Attribution 3.0 International (CC BY 3.0) license](https://creativecommons.org/licenses/by/3.0/) or later.
In SPDX terms, everything here is licensed under MIT;
if it's not executable, including the text when extracted from code, it's
"(MIT OR CC-BY-3.0+)".

Like almost all software today, this software depends on many
other components with their own licenses.
Not all components we depend on are MIT-licensed, but all
*required* components are FLOSS. We prevent licensing issues
using various processes (see [CONTRIBUTING](./CONTRIBUTING.md)).
