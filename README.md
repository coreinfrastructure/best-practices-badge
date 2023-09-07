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
* **[Background](./docs/background.md)** on Badging
* **[ChangeLog](./CHANGELOG.md)**
* **[Requirements](./docs/requirements.md)** - our overall requirements
* **[Design](./docs/design.md)** - our basic design
* Current **[implementation](./docs/implementation.md)**  - notes about the
  BadgeApp implementation
* **[security](./docs/assurance-case.md)**  - notes about BadgeApp security, specifically its assurance case
* **[testing](./docs/testing.md)**  - notes about BadgeApp automated tests
* **[api](./docs/api.md)** - Application Programming Interface (API), including data downloads
* **[Installation](./docs/INSTALL.md)**  - Installation and quick start
* **[Vetting](./docs/vetting.md)**  - More about our vetting approach
* **[Roadmap](./docs/roadmap.md)**  - Roadmap (future plans)

## Summary of Best Practices Criteria "passing" level

This is a summary of the passing criteria, with requirements in bold:

* **Have a [stable website](docs/criteria.md#homepage_url)**, which says:
  - **[what it does](docs/criteria.md#description_good)**
  - **[how to get it](docs/criteria.md#interact)**
  - **[how to give feedback](docs/criteria.md#interact)**
  - **[how to contribute](docs/criteria.md#contribution)** and
    [preferred styles](docs/criteria.md#contribution_requirements)
* **[Explicitly specify](docs/criteria.md#license_location) a
  [FLOSS](docs/criteria.md#floss_license) [license](docs/criteria.md#floss_license_osi)**
* **[Support HTTPS on the project sites](docs/criteria.md#sites_https)**
* **[Document how to install and run (securely)](docs/criteria.md#documentation_basics),
  and [any API](docs/criteria.md#documentation_interface)**
* **Have a** [distributed](docs/criteria.md#repo_distributed)
  **[public version control system](docs/criteria.md#repo_public),
 including [changes between releases](docs/criteria.md#repo_interim)**:
  - **[Give each release a unique version](docs/criteria.md#version_unique)**, using
    [semantic versioning format](docs/criteria.md#version_semver)
  - **Give a [summary of changes for each release](docs/criteria.md#release_notes),
    [identifying any fixed vulnerabilities](docs/criteria.md#release_notes_vulns)**
* **Allow [bug reports to be submitted](docs/criteria.md#report_process),
  [archived](docs/criteria.md#report_archive)** and
  [tracked](docs/criteria.md#report_tracker):
  - **[Acknowledge](docs/criteria.md#report_responses)**/respond to bugs &
    [enhancement requests](docs/criteria.md#enhancement_responses), rather than
    ignoring them
  - **Have a [secure](docs/criteria.md#vulnerability_report_private),
    [documented process](docs/criteria.md#vulnerability_report_process) for
    reporting vulnerabilities**
  - **[Respond within 14 days](docs/criteria.md#vulnerability_report_response),
    and [fix vulnerabilities](docs/criteria.md#vulnerabilities_critical_fixed),
    [within 60 days if they're public](docs/criteria.md#vulnerabilities_fixed_60_days)**
* **[Have a build that works](docs/criteria.md#build)**, using
  [standard](docs/criteria.md#build_common_tools)
  [open-source](docs/criteria.md#build_floss_tools) tools
  - **Enable (and [fix](docs/criteria.md#warnings_fixed))
    [compiler warnings and lint-like checks](docs/criteria.md#warnings)**
  - **[Run other static analysis tools](docs/criteria.md#static_analysis) and
    [fix exploitable problems](docs/criteria.md#static_analysis_fixed)**
* **[Have an automated test suite](docs/criteria.md#test)** that
  [covers most of the code/functionality](docs/criteria.md#test_most), and
  [officially](docs/criteria.md#tests_documented_added)
  **[require new tests for new code](docs/criteria.md#test_policy)**
* [Automate running the tests on all changes](docs/criteria.md#test_continuous_integration),
  and apply dynamic checks:
  - [Run memory/behaviour analysis tools](docs/criteria.md#dynamic_analysis)
    ([sanitizers/Valgrind](docs/criteria.md#dynamic_analysis_unsafe) etc.)
  - [Run a fuzzer or web-scanner over the code](docs/criteria.md#dynamic_analysis)
* **[Have a developer who understands secure software](docs/criteria.md#know_secure_design)
  and [common vulnerability errors](docs/criteria.md#know_common_errors)**
* If cryptography is used:
  - **[Use public protocols/algorithm](docs/criteria.md#crypto_published)**
  - **[Don't re-implement standard functionality](docs/criteria.md#crypto_call)**
  - **[Use open-source cryptography](docs/criteria.md#crypto_floss)**
  - **[Use key lengths that will stay secure](docs/criteria.md#crypto_keylength)**
  - **[Don't use known-broken](docs/criteria.md#crypto_working)** or
    [known-weak](docs/criteria.md#crypto_weaknesses) algorithms
  - [Use algorithms with forward secrecy](docs/criteria.md#crypto_pfs)
  - **[Store any passwords with iterated, salted, hashes using a key-stretching algorithm](docs/criteria.md#crypto_password_storage)**
  - **[Use cryptographic random number sources](docs/criteria.md#crypto_random)**

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
(for details, see the [full list of silver criteria](docs/other.md)):

* **[Use a DCO or similar](docs/other.md#dco)**
* **[Define/document project governance](docs/other.md#governance)**
* **[Another will have the necessary access rights if someone dies](docs/other.md#access_continuity)**
* *["Bus factor" of 2 or more](docs/other.md#bus_factor)*
* **[Document security requirements](docs/other.md#security_requirements)**
* **[Have an assurance case explaining why security requirements are met](docs/other.md#assurance_case)**
* **[Have a quick start guide](docs/other.md#documentation_quick_start)**
* *[Follow accessibility best practices](docs/other.md#accessibility_best_practices)*
* **[Pick & follow coding standards](docs/other.md#coding_standards)**
* **[Monitor external dependencies to detect/fix known vulnerabilities](docs/other.md#dependency_monitoring)**
* **[Tests have 80%+ statement coverage](docs/other.md#test_statement_coverage80)**
* **[Project releases for widespread use are cryptographically signed](docs/other.md#signed_releases)**
* **[Check all inputs from potentially untrusted sources for validity (using an allowlist)](docs/other.md#input_validation)**
* *[Use hardening mechanisms](docs/other.md#hardening)*

### Gold

Here is a summary of the gold criteria, with requirements in bold
(for details, see the [full list of gold criteria](docs/other.md)):

* **[At least 2 unassociated significant contributors](docs/other.md#contributors_unassociated)**
* **[Per-file copyright and license](docs/other.md#copyright_per_file)**
* **[Use 2FA](docs/other.md#require_2FA)**
* **[At least 50% of all modifications are reviewed by another](docs/other.md#two_person_review)**
* **[Have a reproducible build](docs/other.md#reproducible_build)**
* **[Use continuous integration](docs/other.md#test_continuous_integration)**
* **[Statement coverage 90%+](docs/other.md#test_statement_coverage90)**
* **[Branch coverage 80%+](docs/other.md#test_branch_coverage80)**
* **[Support secure protocols & disable insecure protocols by default](docs/other.md#crypto_used_network)**
* **[Use TLS version 1.2 or higher](docs/other.md#crypto_tls12)**
* **[Have a hardened project website, repo, and download site](docs/other.md#hardened_site)**
* **[Have a security review (internal or external)](docs/other.md#security_review)**

## Directory "doc" is now "docs"

If you've used this system in the past, you may have referred to our `doc`
subdirectory for documentation. We have renamed that to a `docs` subdirectory.

## Main site

We have recently moved to the new main site
<https://www.bestpractices.dev>.
For many years the main site was at
<https://bestpractices.coreinfrastructure.org>.
However, the Core Infrastructure Initiative (CII) has ended, and we have
become part of the Open Source Security Foundation (OpenSSF).
Therefore, it made sense to change the domain name so it's no longer tied
to the CII. The domain name is much shorter, too.
We use the "www" subdomain because there are technical challenges using
a top-level domain with our CDN; it's more efficient to use the subdomain.

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
