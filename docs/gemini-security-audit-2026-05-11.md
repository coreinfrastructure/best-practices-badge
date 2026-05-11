# Security Audit Report: OpenSSF Best Practices Badge

**Date:** Sunday, May 10, 2026
**Scope:** Core Controllers, Models, Validators, and Helpers.

## Executive Summary
The OpenSSF Best Practices Badge application demonstrates a mature security posture. The codebase implements advanced defensive patterns, including email encryption, blind indexing, constant-time authentication, and strict input validation. 
Our audit found **no critical vulnerabilities** (such as RCE or SQL injection). We identified several areas that initially appeared suspicious but were determined to be safe upon deeper investigation due to existing defensive layers.

---

## Findings

### 1. Potential Vulnerability Review (Determined Secure)

#### A. User Search Wildcards
- **Initial Observation:** `UsersController#search_name` uses a `LIKE` query with unescaped user input: `User.where('lower(name) LIKE ?', "%#{desired_name.strip.downcase}%")`.
- **Determination:** **FALSE POSITIVE / INTENTIONAL**.
- **Reasoning:** The code explicitly documents this as intentional for admin users to support GDPR and legal requests. Access is strictly controlled by a `current_user.admin?` check in `search_users`. Non-admins cannot trigger this search. The performance risk (DoS via leading wildcard) is mitigated by the restricted access.

#### B. Open Redirects in Sessions
- **Initial Observation:** `SessionsController` uses `params[:return_to]` and `omniauth.params['return_to']` for post-login redirects.
- **Determination:** **FALSE POSITIVE / SECURE**.
- **Reasoning:** Every instance of a user-supplied return path is validated using `valid_return_path?` in `SessionsHelper`. This method rejects non-server-relative paths (must start with `/` but not `//`) and blocks sensitive paths like `/login` or `/signout`.

#### C. SQL Injection in Project Deletion
- **Initial Observation:** `params[:deletion_rationale]` is passed to a mailer and potentially logged.
- **Determination:** **FALSE POSITIVE / SECURE**.
- **Reasoning:** The rationale is treated as a plain string. It is rendered in a text email template (`report_project_deleted.text.erb`) and is not used in any database query or shell command.

#### D. PII in Logs
- **Initial Observation:** Numerous controllers handle emails and tokens.
- **Determination:** **FALSE POSITIVE / SECURE**.
- **Reasoning:** `config/initializers/filter_parameter_logging.rb` contains a comprehensive filter list: `%i[passw email secret token _key crypt salt certificate otp ssn]`. This ensures PII is masked in Rails logs.

---

## Identified Risks and Recommendations

### VULN-001: Potential Timing Attack on Account Activation
- **Severity:** Low
- **Vulnerability Type:** Security
- **Description:** `AccountActivationsController` finds users by email before checking the activation token. While finding a user by encrypted email via blind index is fast, the difference in response time when an email exists vs. when it doesn't could theoretically leak the presence of an account.
- **Recommendation:** Use a timing-safe search pattern similar to `User.authenticate_local_user` if account enumeration is a concern for this specific endpoint.

### VULN-002: Weak URL Detection in Justifications
- **Severity:** Low
- **Vulnerability Type:** Security/Logic
- **Description:** `Project#contains_url?` uses a very loose regex: `%r{https?://[^ ]{5}}`. While intended to be non-strict (as documented), it could be bypassed by a user to satisfy "URL required" criteria without providing a valid, reachable URL.
- **Recommendation:** The current "soft" approach is documented as intentional to avoid breaking legitimate but unusual URLs, but a slightly more robust check (e.g., requiring at least one dot after the scheme) would improve data quality without significantly increasing the attack surface.
- **Decision:** This is *not* a vulnerability, as the URL is used as data. However, requiring at least one period in the URL is a reasonble measure. So we'll add that, but not consider it as a vulnerability.

---

## Conclusion
The application is exceptionally well-hardened. The developers have consistently applied security best practices, and many "potential" flaws were found to have been anticipated and mitigated by existing architectural choices (like `valid_return_path?` and `filter_parameters`).

**Audit Status:** CLEAN (with minor low-severity recommendations)
