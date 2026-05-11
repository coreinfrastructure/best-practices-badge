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
- **Reasoning:** The code explicitly documents this as intentional for admin users to support GDPR and legal requests. Access is strictly controlled by a `current_user.admin?` check in `search_users`.
- **Improvement Plan:** To make this security intent "locally obvious" and provide defense-in-depth:
    - **Move to Private:** Relocate `search_name`, `search_email`, and `search_users_by_lists` to the `private` section of `UsersController`.
    - **Internal Admin Check:** Add an explicit `return User.none unless current_user&.admin?` check inside `search_users_by_lists` and `search_name`.
    - **Enhanced Comments:** Update method headers to explicitly state they are sensitive and only for admin use. Searching by email is security-sensitive. Searching by name doesn't reveal new information, but it imposes load we don't want to let non-admins impose.

#### B. Open Redirects in Sessions
- **Initial Observation:** `SessionsController` uses `params[:return_to]` and `omniauth.params['return_to']` for post-login redirects.
- **Determination:** **FALSE POSITIVE / SECURE**.
- **Reasoning:** Every instance of a user-supplied return path is validated using `valid_return_path?` in `SessionsHelper`. This method rejects non-server-relative paths (must start with `/` but not `//`) and blocks sensitive paths like `/login` or `/signout`.
- **Improvement Plan:**
    - **Warning Comments:** Add a prominent "SECURITY NOTE" block to the `valid_return_path?` method in `SessionsHelper` explaining its critical role in preventing Open Redirects.
    - **Explicit Enforcement:** Ensure all `redirect_to` calls using `return_to` (in `SessionsController#local_login_procedure` and `omniauth_login`) consistently use `allow_other_host: false`. This may be best handled by implementing a new method that combines `redirect_to`, `return_to`, and `allow_other_host: false` and using that new method wherever appropriate. It's not clear if we should implement this method, and if we do, where it should go (the Application Controller is a plausible location, but it's not clear it's the best location).

#### C. SQL Injection in Project Deletion
- **Initial Observation:** `params[:deletion_rationale]` is passed to a mailer and potentially logged.
- **Determination:** **FALSE POSITIVE / SECURE**.
- **Reasoning:** The rationale is treated as a plain string. It is rendered in a text email template (`report_project_deleted.text.erb`) and is not used in any database query or shell command.
- **Improvement Plan:**
    - **Clarifying Comments:** Add an inline comment in `ProjectsController#destroy` where `deletion_rationale` is extracted, noting that it is for informational/logging use only and must not be used in database queries.

#### D. PII in Logs
- **Initial Observation:** Numerous controllers handle emails and tokens.
- **Determination:** **FALSE POSITIVE / SECURE**.
- **Reasoning:** `config/initializers/filter_parameter_logging.rb` contains a comprehensive filter list: `%i[passw email secret token _key crypt salt certificate otp ssn]`. This ensures PII is masked in Rails logs.

#### E. Weak URL Detection in Justifications
- **Initial Observation:** `Project#contains_url?` uses a very loose regex: `%r{https?://[^ ]{5}}`.
- **Determination:** **NOT A VULNERABILITY**.
- **Reasoning:** These URLs serve as pointers to evidence for criteria fulfillment. The application does not automatically traverse or trust these URLs as part of a secure workflow, nor does it verify the relevance of the evidence they point to. They are strictly informational data.
- **Improvement Plan:** While not a security flaw, we plan to improve the regex to require at least one period (e.g., ensuring a domain-like structure). This update will be applied to:
    - **Ruby (Backend):** `app/models/project.rb`, method `contains_url?` (Line 413).
    - **JavaScript (Frontend):** `app/assets/javascripts/project-form.js`, function `containsURL` (Line 91).

---

## Identified Risks and Recommendations

### VULN-001: Potential Timing Attack on Account Activation
- **Severity:** Low
- **Vulnerability Type:** Security (Account Enumeration)
- **Description:** `AccountActivationsController` finds users by email before checking the activation token. Because Ruby's `&&` operator short-circuits, a request for a non-existent email returns almost instantly (~5ms), while a request for a valid email performs a slow BCrypt comparison (~100ms+). This allows an attacker to enumerate valid account emails via timing analysis.
- **Reference Pattern:** A secure version of this logic already exists in `app/models/user.rb` within the `authenticate_local_user` method, which utilizes a `DUMMY_HASH` to ensure a cryptographic operation occurs even when no user is found.
- **Remediation Plan:**
    - **Target File:** `app/controllers/account_activations_controller.rb`
    - **Target Method:** `edit`
    - **Implementation Details:** Refactor the conditional to perform a constant-time check. We will explicitly evaluate both the user's presence and the token's validity, ensuring the slow BCrypt operation is triggered regardless of whether the user exists.
    - **Proposed Fix:**
      ```ruby
      def edit
        user = User.find_by(email: params[:email])
        # Secure implementation using a constant-time approach:
        # 1. Determine if the user exists and is not already activated
        user_exists_and_unactivated = user && !user.activated?
        
        # 2. Perform the slow BCrypt check.
        # If user exists, check their real digest. 
        # If not, check against the DUMMY_HASH to maintain timing consistency.
        token_valid = if user_exists_and_unactivated
                        user.authenticated?(:activation, params[:id])
                      else
                        User.verify_password_against_hash?(User::DUMMY_HASH, params[:id])
                        false
                      end

        if user_exists_and_unactivated && token_valid
          user.can_login_starting_at = Time.zone.now + LOCAL_LOGIN_COOLOFF_TIME
          user.activate
          # ... rest of success logic ...
        else
          # ... rest of failure logic ...
        end
      end
      ```

---

## Conclusion
The application is exceptionally well-hardened. The developers have consistently applied security best practices, and many "potential" flaws were found to have been anticipated and mitigated by existing architectural choices (like `valid_return_path?` and `filter_parameters`).

**Audit Status:** CLEAN (with minor low-severity recommendations)
