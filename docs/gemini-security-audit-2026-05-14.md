# Gemini Security Audit Report - 2026-05-14

## Executive Summary
This report documents the preliminary findings of a security audit performed by the Gemini CLI agent. The audit focuses on the Best Practices Badge system, focusing on core controllers, models, and utility libraries.

## Current Audit Scope
- **Controllers**: `ProjectsController`, `UsersController`, `SessionsController`, `ApplicationController`.
- **Models**: `Project`, `User`.
- **Libraries**: `MarkdownProcessor`, `GithubContentAccess`.

## Preliminary Findings and Concerns

### 1. Potential XSS in Markdown Optimization
- **Location**: `app/lib/markdown_processor.rb`
- **Description**: The system uses a complex regular expression (`MARKDOWN_UNNECESSARY`) to identify text that doesn't require Markdown processing. If matched, the text is returned as `.html_safe`.
- **Risk**: High. Any bypass in the regex that allows HTML tags or dangerous entities through would lead to direct XSS, as the application bypasses the standard sanitizer.
- **Investigation Plan**: Perform a "stress test" on the `MARKDOWN_UNNECESSARY` regex to identify potential bypasses.

### 2. Potential SQL Injection in Search Scopes
- **Location**: `app/models/project.rb` (scopes: `text_search`, `url_search`, `search_for`)
- **Description**: User-provided search strings (`params[:q]`, `params[:pq]`, `params[:url]`) are passed to ActiveRecord scopes. 
- **Risk**: Medium-High. While some scopes use parameterization, the `text_search` scope uses Arel's `.matches()` with manual wildcard concatenation (`#{sanitize_sql_like(text)}%`).
- **Investigation Plan**: Trace the data flow from `ProjectsController#retrieve_projects` to these scopes and verify that the underlying database driver correctly parameterizes the resulting SQL.

### 3. Open Redirect Risk in Locale and Session Logic
- **Location**: `app/controllers/application_controller.rb` (`redir_missing_locale`) and `SessionsController`.
- **Description**: Redirections are performed based on `request.original_url` or `params[:return_to]`.
- **Risk**: Medium. If these redirects do not strictly enforce same-origin or an allow-list, they could be used for phishing attacks.
- **Investigation Plan**: Verify the implementation of `force_locale_url` and `valid_return_path?` (if it exists) to ensure they prevent off-site redirects.

### 4. DoS/SSRF Vulnerability in GitHub Content Access
- **Location**: `app/lib/github_content_access.rb`
- **Description**: The `get_content` method relies on trusting GitHub's reported file size before fetching. Because the Octokit gem reads the entire response into memory, a malicious "upstream" could cause an Out-Of-Memory (OOM) condition.
- **Risk**: Low-Medium (Requires compromised GitHub or MITM).
- **Status**: Noted as a known architectural limitation with a "trust but verify" mitigation.

### 5. Privacy of User Data
- **Observation**: User email addresses are protected using `attr_encrypted` (AES-256-GCM) and `blind_index` for searching.
- **Conclusion**: This appears to be a robust implementation of privacy best practices for PII.

## Further Investigation Tasks
- [ ] Investigate data flow for SQL Injection in `Project` scopes.
- [ ] Test `MARKDOWN_UNNECESSARY` regex for XSS bypasses.
- [ ] Locate and audit `force_locale_url` for open redirect risks.
- [ ] Audit `valid_return_path?` in `SessionsController`.
