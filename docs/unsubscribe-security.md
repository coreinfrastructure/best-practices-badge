# Unsubscribe Feature Security Documentation

## Overview
The unsubscribe feature provides a secure way for users to opt out of email notifications. This implementation follows security best practices to prevent abuse and protect user privacy. The system now includes time-based validation with issued dates and uses a dedicated secret key for enhanced security.

## Security Features

### 1. Authentication & Authorization
- **HMAC-based tokens**: Uses HMAC-SHA256 with dedicated `BADGEAPP_UNSUBSCRIBE_KEY` environment variable
- **Time-based validation**: Tokens include issued date and expire after configurable period (default 30 days)
- **Constant-time comparison**: Prevents timing attacks when validating tokens
- **Token binding**: Tokens are bound to user ID, email, and issued date
- **No user enumeration**: Doesn't reveal whether an email exists in the system

### 2. Input Validation
- **Email format validation**: Strict regex validation for email addresses
- **Token format validation**: Ensures tokens contain only safe characters
- **Date format validation**: Strict YYYY-MM-DD format validation with range checks
- **Length limits**: Prevents DoS attacks with oversized inputs
- **Parameter sanitization**: Strips HTML and dangerous characters

### 3. Time-Based Security
- **Issued date validation**: Links must include valid issued date in YYYY-MM-DD format
- **Expiration handling**: Tokens expire after configurable period (BADGEAPP_UNSUBSCRIBE_DAYS)
- **Future date prevention**: Rejects tokens with future issued dates
- **Clock skew tolerance**: Allows 1-day tolerance for clock differences

### 4. Rate Limiting & Abuse Prevention
- **IP-based rate limiting**: Maximum 5 attempts per hour per IP address
- **Honeypot fields**: Client-side bot detection
- **CSRF protection**: Requires valid CSRF tokens for form submissions
- **Database transactions**: Ensures atomicity of unsubscribe operations

### 5. Privacy Protection
- **No PII in logs**: Logs only user IDs, not email addresses
- **Timing attack mitigation**: Random delays for non-existent emails
- **Secure headers**: X-Frame-Options, X-XSS-Protection, Content-Type-Options
- **Content Security Policy**: Restricts script execution and resource loading

### 6. Error Handling
- **Graceful degradation**: Handles database errors without exposing internals
- **Secure error messages**: Doesn't leak sensitive information
- **Comprehensive logging**: Security events logged for monitoring
- **Safe defaults**: Fails securely when validation fails

## Environment Variables

### Required Configuration
- `BADGEAPP_UNSUBSCRIBE_KEY`: Secret key for HMAC token generation (should be unique and random)
- `BADGEAPP_UNSUBSCRIBE_DAYS`: Number of days tokens remain valid (default: 30)

### Example Configuration
```bash
# Generate a random 64-character hex key
BADGEAPP_UNSUBSCRIBE_KEY=a1b2c3d4e5f6...
BADGEAPP_UNSUBSCRIBE_DAYS=30
```

## Implementation Components

### Routes
```ruby
# Within scope '(:locale)', locale: LEGAL_LOCALE block
get 'unsubscribe' => 'unsubscribe#show'
post 'unsubscribe' => 'unsubscribe#create'
```

**Locale Support**:
- **With locale**: `/en/unsubscribe` - works directly in English locale
- **Without locale**: `/unsubscribe` - redirects to user's preferred locale (e.g., `/en/unsubscribe`)
- **Email links**: Commonly include locale for immediate localized experience
- **Browser detection**: When no locale provided, uses browser language preferences

### Controller: `UnsubscribeController`
- Handles both GET (form display) and POST (processing) requests
- Validates issued date parameter for time-based security
- Implements comprehensive input validation and security checks
- Uses database transactions for data consistency

### View: `app/views/unsubscribe/show.html.erb`
- Displays read-only email, token, and issued date fields
- CSRF-protected form with client-side validation
- Content Security Policy with nonce-based script execution
- Honeypot field for bot detection

### Helper: `UnsubscribeHelper`
- Time-based token generation and verification utilities
- URL generation with issued date for email templates
- Privacy-preserving logging functions
- Date validation and parsing utilities

### Database Migration
- Adds `notification_emails` boolean field to users table
- Safe default values and proper indexing
- Backwards-compatible with existing data

### Email Integration: `ReportMailer`
- Modified to check user notification preferences
- Includes unsubscribe links in reminder emails
- Uses helper methods for secure token generation

## Usage in Email Templates

To include unsubscribe links in emails:

```ruby
class UserMailer < ApplicationMailer
  include UnsubscribeHelper

  def notification_email(user)
    @user = user

    # Only send if user has notifications enabled
    return unless user.notification_emails?

    # Generate unsubscribe URL with current date
    @unsubscribe_url = generate_unsubscribe_url(user, Date.current)

    mail(to: user.email, subject: 'Notification')
  end
end
```

## Testing

Comprehensive test suite includes:
- Valid and invalid token testing with issued dates
- Time-based validation (expired/future dates)
- Input validation testing
- Rate limiting verification
- SQL injection prevention
- XSS protection validation
- CSRF protection testing
- Secure header verification
- Notification preference checking

## Security Considerations

1. **Secret Key Management**: Store `BADGEAPP_UNSUBSCRIBE_KEY` securely and rotate it periodically
2. **Time Window Configuration**: Balance security vs usability when setting expiration period
3. **Clock Synchronization**: Ensure server clocks are synchronized to prevent time-based issues
4. **Monitoring**: Log analysis should monitor for:
   - Unusual numbers of failed unsubscribe attempts
   - Rate limit violations
   - Invalid token patterns
   - Expired token usage attempts

5. **GDPR Compliance**: The unsubscribe feature supports data subject rights by allowing users to control their email preferences

6. **Backup Security**: Even if tokens are compromised, attackers can only unsubscribe users (no privilege escalation possible)

## Dependencies

- Rails 8.0+ with ActiveRecord
- OpenSSL for HMAC generation
- ActionController for sanitization
- Rails cache for rate limiting

## Maintenance

- Regularly update dependencies for security patches
- Monitor rate limiting effectiveness
- Review logs for security incidents
- Rotate unsubscribe secret key periodically
- Adjust token expiration period based on usage patterns
