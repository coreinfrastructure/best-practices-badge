# CLAUDE.md

This file provides guidance to the Claude Code (claude.ai/code) AI assistant when working with code in this repository.

## Project Overview

This is the **OpenSSF Best Practices Badge** project (formerly CII Best Practices Badge) - a Rails web application that helps FLOSS projects self-certify that they meet security and quality best practices. The application provides a badging system with three levels: passing, silver, and gold.

**Key URLs:**

- Production: https://www.bestpractices.dev/
- GitHub: https://github.com/coreinfrastructure/best-practices-badge

## Common Development Commands

### Testing

- `rails test` - Run unit/integration tests (excludes system tests by default)
- `rails test:system` - Run system tests (Capybara-based browser tests)
- `rails test:all` - Run ALL tests including system tests
- `rails test test/integration/project_list_test.rb` - Run the specified test file
- `rails test test/features/can_access_home_test.rb:4` - Run a test at line 4 of the specified test file.
- `rails test rails test TESTFILE -n NAME_OR_PATTERN` - Run the specific test or pattern `NAME_OR_PATTERN` in file TESTFILE

### Code Quality & Linting

- `rake` or `rake default` - Run complete CI pipeline (linting, tests, security checks).
- `rake rubocop` - Ruby style checker  
- `rake rails_best_practices` - Rails-specific best practices source checker
- `rake markdownlint` - Markdown linting
- `rake eslint` - JavaScript linting
- `rake whitespace_check` - Check for trailing whitespace
- `rake yaml_syntax_check` - YAML syntax validation
- `rake license_okay` - License compliance check
- `rake bundle_audit` - Security audit of gems

For specific files:

- `mdl FILENAME.md` - Markdownlint only the file `FILENAME.md`
- `rubocop FILENAME.rb` - Run rubocop on just `FILENAME.rb`

Don't run `rails_best_practices` to analyze individual files, as
it needs the full context to do its best.

### Development Environment Shortcut

As a convenience, in the development environment you don't need to use
`bundle exec` prefixes for ruby commands (though you may use them).
They *are* necessary in cases, such as rake tasks, that might be
used in the CI or production environments.

### Security Analysis

GitHub runs Brakeman and CodeQL remotely for static security analysis, it's
not done on the local system.

### Development Server

- `rails s` - Start development server (http://localhost:3000)
- `rails console` - Start Rails console for debugging

## Architecture & Key Concepts

### Core Models

- **Project** - Central model representing a FLOSS project seeking certification
  - Has three badge levels: passing, silver, gold (plus `in_progress`)
  - Uses PostgreSQL full-text search via `pg_search` gem
  - Stores criteria answers and justifications
  - Heavy security validation and input sanitization

- **User** - Project owners and contributors
  - Email addresses are encrypted in database using `attr_encrypted`
  - Uses OAuth (GitHub) and local authentication
  - Session management with automatic timeouts

- **Criteria** - The best practices criteria that projects must meet
  - Dynamic criteria system supporting multiple languages
  - Complex validation rules and automated checking

### Security Architecture

Security is *extremely* important to this project. Some features:

- **Encrypted Data**: User emails encrypted with AES-256-GCM
- **Blind Indexing**: Email searches use blind indices for privacy  
- **CSRF Protection**: All forms protected with Rails CSRF tokens
- **Rate Limiting**: Uses `rack-attack` for DoS protection
- **Content Security Policy**: Strict CSP headers via `secure_headers` gem
- **HTTPS Enforcement**: Force SSL in production
- **IP Validation**: Optional Fastly IP allowlisting (cloud piercing protection)

The file `docs/assurance-case.md` explains why we *believe* this is secure.

### Authentication & Authorization

- **Multi-provider**: GitHub OAuth + local accounts
- **Session Security**: Automatic timeouts, secure cookies
- **Additional Rights**: Project collaborator system via `additional_rights` table
- **Admin System**: Special admin user capabilities

### Internationalization

- **Multi-language Support**: Currently supports 6+ languages
- **URL Structure**: Routes include locale (e.g., `/en/projects`, `/fr/projets`)
- **Locale Handling**: Automatic locale detection and redirection
- **Translation Management**: Uses `translation.io` service

### Performance & Caching

- **CDN Integration**: Fastly CDN for badge images and static assets
- **Database Optimization**: Careful indexing, connection pooling
- **Pagination**: Uses `pagy` gem (currently v9.4.0)
- **Asset Pipeline**: Rails asset pipeline with Sass compilation

### Background Jobs

- **solid_queue**: ActiveJob backend for async processing
- **Email System**: Reminder emails, user notifications
- **Data Tasks**: Daily/monthly maintenance tasks

## Key Configuration Files

- `config/application.rb` - Core Rails app configuration  
- `config/routes.rb` - Complex routing with locale support
- `lib/tasks/default.rake` - Custom rake tasks including full CI pipeline

The directory `config`, especially `config/initializers`,
has many configuration files.

## Development Practices

### Code Style

- **Frozen String Literals**: All files must include `# frozen_string_literal: true`
- **Security Headers**: Each file has copyright and SPDX-License-Identifier
- **Refinements**: Uses custom `StringRefinements` and `SymbolRefinements`
- **Documentation**: Comprehensive inline documentation expected

### Testing Strategy

- **Minitest**: Uses Rails' default Minitest framework
- **System Tests**: Capybara-based browser automation tests
- **Parallel Safe**: Tests designed for process parallelism (not thread safe)
- **Coverage**: Maintains high test coverage via codecov integration

### Security Requirements

Security is *VERY* important in this application.

- **DCO Required**: All commits must be signed off per Developer Certificate of Origin
- **No Sensitive Data**: Never commit API keys, passwords, or encryption keys
- **Input Validation**: All user inputs heavily validated and sanitized
- **SQL Injection Prevention**: Always uses Rails parameterized queries (including its ORM) with untrusted input
- **XSS Prevention**: Uses templates to prevent XSS
- User inputs should be checked for expected format and length.
- When applicable, generate unit tests for security-critical functions (including negative tests to ensure the code fails safely).
- Do not add dependencies that may be malicious or hallucinated.
- Never log, expose, or commit passwords, API keys, encryption keys, or other secrets.

### Version Control

- **Git Workflow**: Feature branches with pull request review
- **Commit Signing**: DCO sign-off required (`git commit --signoff`)
- **Branch Protection**: Main branch requires review and CI passage

## Environment Variables

Key environment variables for development:

- `RAILS_ENV` - Rails environment (development/test/production)
- `EMAIL_ENCRYPTION_KEY` - 64 hex digits for email encryption  
- `EMAIL_BLIND_INDEX_KEY` - 64 hex digits for email search indices
- `BADGEAPP_REAL_PRODUCTION` - Set to "true" only on true production site
- `PUBLIC_HOSTNAME` - Hostname for the application
- `DB_POOL` - Database connection pool size

## Common Issues & Solutions

### Database Issues

- Email encryption keys must be exactly 64 hex digits (256 bits)
- Use `rails db:reset` carefully - will destroy all local data
- PostgreSQL full-text search requires specific indices

### Testing Issues

- System tests require JavaScript driver setup
- Tests are process-parallel safe but NOT thread-safe
- Use `RAILS_ENV=test` for test database operations

### Security Considerations

- Badge image URLs must be canonical for CDN caching
- All user input requires validation and sanitization  
- Session timeouts are enforced - don't extend arbitrarily
- Rate limiting is aggressive - be aware when testing

## Important File Locations

- `app/models/project.rb` - Core project model with badge logic
- `app/controllers/application_controller.rb` - Base controller with security
- `config/routes.rb` - Complex internationalized routing
- `docs/` - Extensive documentation including security assurance case
- `lib/tasks/default.rake` - CI pipeline and custom tasks
- `test/` - Comprehensive test suite
