# OpenSSF Best Practices Badge (formerly CII Best Practices Badge)

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

[![OpenSSF Best Practices](https://bestpractices.coreinfrastructure.org/projects/1/badge)](https://bestpractices.coreinfrastructure.org/projects/1)
[![CircleCI Build Status](https://circleci.com/gh/coreinfrastructure/best-practices-badge.svg?&style=shield&circle-token=ca450ac150523030464677a1aa7f3cacfb8b3472)](https://app.circleci.com/pipelines/github/coreinfrastructure/best-practices-badge)
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
* **[Background](./doc/background.md)** on Badging
* **[ChangeLog](./CHANGELOG.md)**
* **[Requirements](./doc/requirements.md)** - our overall requirements
* **[Design](./doc/design.md)** - our basic design
* Current **[implementation](./doc/implementation.md)**  - notes about the
  BadgeApp implementation
* **[security](./doc/security.md)**  - notes about BadgeApp security
* **[testing](./doc/testing.md)**  - notes about BadgeApp automated tests
* **[api](./doc/api.md)** - Application Programming Interface (API), including data downloads
* **[Installation](./doc/INSTALL.md)**  - Installation and quick start
* **[Vetting](./doc/vetting.md)**  - More about our vetting approach
* **[Roadmap](./doc/roadmap.md)**  - Roadmap (future plans)

## Summary of Best Practices Criteria "passing" level

This is a summary of the passing criteria, with requirements in bold:

* **Have a [stable website](doc/criteria.md#homepage_url)**, which says:
  - **[what it does](doc/criteria.md#description_good)**
  - **[how to get it](doc/criteria.md#interact)**
  - **[how to give feedback](doc/criteria.md#interact)**
  - **[how to contribute](doc/criteria.md#contribution)** and
    [preferred styles](doc/criteria.md#contribution_requirements)
* **[Explicitly specify](doc/criteria.md#license_location) a
  [FLOSS](doc/criteria.md#floss_license) [license](doc/criteria.md#floss_license_osi)**
* **[Support HTTPS on the project sites](doc/criteria.md#sites_https)**
* **[Document how to install and run (securely)](doc/criteria.md#documentation_basics),
  and [any API](doc/criteria.md#documentation_interface)**
* **Have a** [distributed](doc/criteria.md#repo_distributed)
  **[public version control system](doc/criteria.md#repo_public),
 including [changes between releases](doc/criteria.md#repo_interim)**:
  - **[Give each release a unique version](doc/criteria.md#version_unique)**, using
    [semantic versioning format](doc/criteria.md#version_semver)
  - **Give a [summary of changes for each release](doc/criteria.md#release_notes),
    [identifying any fixed vulnerabilities](doc/criteria.md#release_notes_vulns)**
* **Allow [bug reports to be submitted](doc/criteria.md#report_process),
  [archived](doc/criteria.md#report_archive)** and
  [tracked](doc/criteria.md#report_tracker):
  - **[Acknowledge](doc/criteria.md#report_responses)**/respond to bugs &
    [enhancement requests](doc/criteria.md#enhancement_responses), rather than
    ignoring them
  - **Have a [secure](doc/criteria.md#vulnerability_report_private),
    [documented process](doc/criteria.md#vulnerability_report_process) for
    reporting vulnerabilities**
  - **[Respond within 14 days](doc/criteria.md#vulnerability_report_response),
    and [fix vulnerabilities](doc/criteria.md#vulnerabilities_critical_fixed),
    [within 60 days if they're public](doc/criteria.md#vulnerabilities_fixed_60_days)**
* **[Have a build that works](doc/criteria.md#build)**, using
  [standard](doc/criteria.md#build_common_tools)
  [open-source](doc/criteria.md#build_floss_tools) tools
  - **Enable (and [fix](doc/criteria.md#warnings_fixed))
    [compiler warnings and lint-like checks](doc/criteria.md#warnings)**
  - **[Run other static analysis tools](doc/criteria.md#static_analysis) and
    [fix exploitable problems](doc/criteria.md#static_analysis_fixed)**
* **[Have an automated test suite](doc/criteria.md#test)** that
  [covers most of the code/functionality](doc/criteria.md#test_most), and
  [officially](doc/criteria.md#tests_documented_added)
  **[require new tests for new code](doc/criteria.md#test_policy)**
* [Automate running the tests on all changes](doc/criteria.md#test_continuous_integration),
  and apply dynamic checks:
  - [Run memory/behaviour analysis tools](doc/criteria.md#dynamic_analysis)
    ([sanitizers/Valgrind](doc/criteria.md#dynamic_analysis_unsafe) etc.)
  - [Run a fuzzer or web-scanner over the code](doc/criteria.md#dynamic_analysis)
* **[Have a developer who understands secure software](doc/criteria.md#know_secure_design)
  and [common vulnerability errors](doc/criteria.md#know_common_errors)**
* If cryptography is used:
  - **[Use public protocols/algorithm](doc/criteria.md#crypto_published)**
  - **[Don't re-implement standard functionality](doc/criteria.md#crypto_call)**
  - **[Use open-source cryptography](doc/criteria.md#crypto_floss)**
  - **[Use key lengths that will stay secure](doc/criteria.md#crypto_keylength)**
  - **[Don't use known-broken](doc/criteria.md#crypto_working)** or
    [known-weak](doc/criteria.md#crypto_weaknesses) algorithms
  - [Use algorithms with forward secrecy](doc/criteria.md#crypto_pfs)
  - **[Store any passwords with iterated, salted, hashes using a key-stretching algorithm](doc/criteria.md#crypto_password_storage)**
  - **[Use cryptographic random number sources](doc/criteria.md#crypto_random)**

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
(for details, see the [full list of silver criteria](doc/other.md)):

* **[Use a DCO or similar](doc/other.md#dco)**
* **[Define/document project governance](doc/other.md#governance)**
* **[Another will have the necessary access rights if someone dies](doc/other.md#access_continuity)**
* *["Bus factor" of 2 or more](doc/other.md#bus_factor)*
* **[Document security requirements](doc/other.md#security_requirements)**
* **[Have an assurance case explaining why security requirements are met](doc/other.md#assurance_case)**
* **[Have a quick start guide](doc/other.md#documentation_quick_start)**
* *[Follow accessibility best practices](doc/other.md#accessibility_best_practices)*
* **[Pick & follow coding standards](doc/other.md#coding_standards)**
* **[Monitor external dependencies to detect/fix known vulnerabilities](doc/other.md#dependency_monitoring)**
* **[Tests have 80%+ statement coverage](doc/other.md#test_statement_coverage80)**
* **[Project releases for widespread use are cryptographically signed](doc/other.md#signed_releases)**
* **[Check all inputs from potentially untrusted sources for validity (using an allowlist)](doc/other.md#input_validation)**
* *[Use hardening mechanisms](doc/other.md#hardening)*

### Gold

Here is a summary of the gold criteria, with requirements in bold
(for details, see the [full list of gold criteria](doc/other.md)):

* **[At least 2 unassociated significant contributors](doc/other.md#contributors_unassociated)**
* **[Per-file copyright and license](doc/other.md#copyright_per_file)**
* **[Use 2FA](doc/other.md#require_2FA)**
* **[At least 50% of all modifications are reviewed by another](doc/other.md#two_person_review)**
* **[Have a reproducible build](doc/other.md#reproducible_build)**
* **[Use continuous integration](doc/other.md#test_continuous_integration)**
* **[Statement coverage 90%+](doc/other.md#test_statement_coverage90)**
* **[Branch coverage 80%+](doc/other.md#test_branch_coverage80)**
* **[Support secure protocols & disable insecure protocols by default](doc/other.md#crypto_used_network)**
* **[Use TLS version 1.2 or higher](doc/other.md#crypto_tls12)**
* **[Have a hardened project website, repo, and download site](doc/other.md#hardened_site)**
* **[Have a security review (internal or external)](doc/other.md#security_review)**

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
