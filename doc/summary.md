# Best Practices Criteria Summary

This is a summary of the criteria; for details, see the
[full list of criteria](criteria.md).

- **Have a [stable website](criteria.md#project_homepage_url)**,
  [accessible over HTTPS](project_homepage_https), which says:
  - **[what it does](criteria.md#description_sufficient)**
  - **[how to get it](criteria.md#interact)**
  - **[how to give feedback](criteria.md#interact)**
  - **[how to contribute](criteria.md#contribution)** and
    [preferred styles](criteria.md#contribution_criteria)
- **[Explicitly specify](criteria.md#license_location) an
  [OSS](criteria.md#oss_license) [license](criteria.md#oss_license_osi)**
- **[Document how to install and run (securely)](criteria.md#documentation_basics),
  and [any API](criteria.md#documentation_interface)**
- **Have a** [distributed](criteria.md#repo_distributed)
  **[public version control system](criteria.md#repo_url),
  including [changes between releases](criteria.md#repo_interim)**:
  - **[Give each release a unique version](criteria.md#version_unique)**, using
    [semantic versioning format](criteria.md#version_semver)
  - **Give a [summarized change log for each release](criteria.md#changelog),
    [identifying any fixed vulnerabilities](criteria.md#changelog_vulns)**
- **Allow [bug reports to be submitted](criteria.md#report_process),
  [archived](criteria.md#report_archive)** and
  [tracked](criteria.md#report_tracker):
  - **[Acknowledge](criteria.md#report_responses)**/respond to bugs &
    [enhancement requests](criteria.md#enhancement_responses), rather than
    ignoring them
  - **Have a [secure](criteria.md#vulnerability_report_private),
    [documented process](criteria.md#vulnerability_report_process) for
    reporting vulnerabilities**
  - **[Respond within 7 days](criteria.md#vulnerability_report_response)
    (on average), and [fix vulnerabilities](criteria.md#vulnerabilities_critical_fixed),
    [within 60 days if they're public](criteria.md#vulnerabilities_fixed_60_days)**
- **[Have a build that works](criteria.md#build)**, using
  [standard](criteria.md#build_common_tools)
  [open-source](criteria.md#build_oss_tools) tools
  - **Enable (and [fix](criteria.md#warnings_fixed))
    [compiler warnings and lint-like checks](criteria.md#warnings)**
  - **[Run other static analysis tools](criteria.md#static_analysis) and
    [fix exploitable problems](criteria.md#static_analysis_fixed)**
- **[Have an automated test suite](criteria.md#test)** that
  [covers most of the code/functionality](criteria.md#test_most), and
  [officially](criteria.md#tests_documented_added)
  **[require new tests for new code](criteria.md#test_policy)**
- [Automate running the tests on all changes](criteria.md#test_continuous_integration),
  and apply dynamic checks:
  - [Run memory/behaviour analysis tools](criteria.md#dynamic_analysis)
    ([sanitizers/Valgrind](criteria.md#dynamic_analysis_unsafe) etc.)
  - [Run a fuzzer or web-scanner over the code](criteria.md#dynamic_analysis)
- **[Have a developer who understands secure software](criteria.md#know_secure_design)
  and [common vulnerability errors](criteria.md#know_common_errors)**
- If cryptography is used:
  - **[Use public protocols/algorithm](criteria.md#crypto_published)**
  - **[Don't re-implement standard functionality](criteria.md#crypto_call)**
  - **[Use open-source cryptography](criteria.md#crypto_oss)**
  - **[Use key lengths that will stay secure](criteria.md#crypto_keylength)**
  - **[Don't use known-broken](criteria.md#crypto_working)** or
    [known-weak](criteria.md#crypto_weaknesses) algorithms
  - [Use algorithms with forward secrecy](criteria.md#crypto_pfs)
  - [Support multiple algorithms, and allow switching between them](criteria.md#crypto_alternatives)
  - **[Store any passwords with iterated, salted, hashes using a key-stretching algorithm](criteria.md#crypto_password_storage)**
  - **[Use cryptographic random number sources](criteria.md#crypto_random)**
