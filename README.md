# Core Infrastructure Initiative Best Practices Badge

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1/badge)](https://bestpractices.coreinfrastructure.org/projects/1)
[![CircleCI Build Status](https://circleci.com/gh/linuxfoundation/cii-best-practices-badge.svg?&style=shield&circle-token=ca450ac150523030464677a1aa7f3cacfb8b3472)](https://circleci.com/gh/linuxfoundation/cii-best-practices-badge)
[![codecov](https://codecov.io/gh/linuxfoundation/cii-best-practices-badge/branch/master/graph/badge.svg)](https://codecov.io/gh/linuxfoundation/cii-best-practices-badge)
[![Dependency Status](https://gemnasium.com/linuxfoundation/cii-best-practices-badge.svg)](https://gemnasium.com/linuxfoundation/cii-best-practices-badge)
[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://badges.mit-license.org)

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
*[Core Infrastructure Initiative (CII) Best Practices badge website](https://bestpractices.coreinfrastructure.org/)* if you want to try to actually get a badge.

This is the development site for the criteria and badge application
software that runs the website.
Feedback is very welcome via the
[GitHub site](https://github.com/linuxfoundation/cii-best-practices-badge)
as issues or pull (merge) requests.
There is also a
[mailing list](https://lists.coreinfrastructure.org/mailman/listinfo/cii-badges)
for general discussion.

* Badging **[Criteria](./doc/criteria.md)**
* Information on how to **[contribute](./CONTRIBUTING.md)**
* **[Background](./doc/background.md)** on Badging
* **[ChangeLog](./CHANGELOG.md)**
* Current **[implementation](./doc/implementation.md)**  - notes about the
  BadgeApp implementation
* **[security](./doc/security.md)**  - notes about BadgeApp security
* **[testing](./doc/testing.md)**  - notes about BadgeApp automated tests
* Current **[Burndown](https://burndown.io/#linuxfoundation/cii-best-practices-badge/1)** and
**[Kanban Board](https://waffle.io/linuxfoundation/cii-best-practices-badge)**
of this project.

## Summary of Best Practices Criteria

This is a summary of the criteria, with requirements in bold
(for details, see the [full list of criteria](doc/criteria.md)):

- **Have a [stable website](doc/criteria.md#homepage_url)**, which says:
  - **[what it does](doc/criteria.md#description_good)**
  - **[how to get it](doc/criteria.md#interact)**
  - **[how to give feedback](doc/criteria.md#interact)**
  - **[how to contribute](doc/criteria.md#contribution)** and
    [preferred styles](doc/criteria.md#contribution_requirements)
- **[Explicitly specify](doc/criteria.md#license_location) a
  [FLOSS](doc/criteria.md#floss_license) [license](doc/criteria.md#floss_license_osi)**
- **[Support HTTPS on the project sites](doc/criteria.md#sites_https)**
- **[Document how to install and run (securely)](doc/criteria.md#documentation_basics),
  and [any API](doc/criteria.md#documentation_interface)**
- **Have a** [distributed](doc/criteria.md#repo_distributed)
  **[public version control system](doc/criteria.md#repo_public),
  including [changes between releases](doc/criteria.md#repo_interim)**:
  - **[Give each release a unique version](doc/criteria.md#version_unique)**, using
    [semantic versioning format](doc/criteria.md#version_semver)
  - **Give a [summary of changes for each release](doc/criteria.md#release_notes),
    [identifying any fixed vulnerabilities](doc/criteria.md#release_notes_vulns)**
- **Allow [bug reports to be submitted](doc/criteria.md#report_process),
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
- **[Have a build that works](doc/criteria.md#build)**, using
  [standard](doc/criteria.md#build_common_tools)
  [open-source](doc/criteria.md#build_floss_tools) tools
  - **Enable (and [fix](doc/criteria.md#warnings_fixed))
    [compiler warnings and lint-like checks](doc/criteria.md#warnings)**
  - **[Run other static analysis tools](doc/criteria.md#static_analysis) and
    [fix exploitable problems](doc/criteria.md#static_analysis_fixed)**
- **[Have an automated test suite](doc/criteria.md#test)** that
  [covers most of the code/functionality](doc/criteria.md#test_most), and
  [officially](doc/criteria.md#tests_documented_added)
  **[require new tests for new code](doc/criteria.md#test_policy)**
- [Automate running the tests on all changes](doc/criteria.md#test_continuous_integration),
  and apply dynamic checks:
  - [Run memory/behaviour analysis tools](doc/criteria.md#dynamic_analysis)
    ([sanitizers/Valgrind](doc/criteria.md#dynamic_analysis_unsafe) etc.)
  - [Run a fuzzer or web-scanner over the code](doc/criteria.md#dynamic_analysis)
- **[Have a developer who understands secure software](doc/criteria.md#know_secure_design)
  and [common vulnerability errors](doc/criteria.md#know_common_errors)**
- If cryptography is used:
  - **[Use public protocols/algorithm](doc/criteria.md#crypto_published)**
  - **[Don't re-implement standard functionality](doc/criteria.md#crypto_call)**
  - **[Use open-source cryptography](doc/criteria.md#crypto_floss)**
  - **[Use key lengths that will stay secure](doc/criteria.md#crypto_keylength)**
  - **[Don't use known-broken](doc/criteria.md#crypto_working)** or
    [known-weak](doc/criteria.md#crypto_weaknesses) algorithms
  - [Use algorithms with forward secrecy](doc/criteria.md#crypto_pfs)
  - **[Store any passwords with iterated, salted, hashes using a key-stretching algorithm](doc/criteria.md#crypto_password_storage)**
  - **[Use cryptographic random number sources](doc/criteria.md#crypto_random)**

## License

All material is released under the [MIT license](./LICENSE).
All material that is not executable, including all text when not executed,
is also released under the
[Creative Commons Attribution 3.0 International (CC BY 3.0) license](https://creativecommons.org/licenses/by/3.0/) or later.
In SPDX terms, everything here is licensed under MIT;
if it's not executable, including the text when extracted from code, it's
"(MIT OR CC-BY-3.0+)".
