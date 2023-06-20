# Change Log

This file documents some notable changes.
However, because this software is primarily intended for a single site,
we have not worked at keeping it up to date.

This Change Log format is suggested by
<https://github.com/olivierlacan/keep-a-changelog/blob/master/CHANGELOG.md>

## 7945407b - 2017-03-09

- Switch project page from tabs to collapisble panels
- An anchor tag in the url will now open the panel containing
  tagged content
- Add a satisfaction level on each panel header

## dcb21c8e - 2017-02-22

- Upgraded to Rails 5
- Upgraded to Ruby 2.4.0
- Increased password complexity rules
  - Minimum length of 8 characters for new passwords
  - Added a password blacklist for commonly used passwords
- Users can once again change their repo_url, but only from http to https
  (or vice versa).
- Fixed redirects on login: If a user clicks login from a page other
  than the front page, they will be redirected back to that page after
  they log in.
- Added na_justification_required option for criteria, where a justification
  can be required for "N/A" selections.
- Added autogeneration script for criteria.md.

## 0.8.0 - 2016-04-19

- When accessing GitHub we now use the logged-in-user's token
  everywhere.  This makes us much less susceptible to rate limit issues.
- The test framework now (finally!) directly invokes a web browser
  and tests the JavaScript code.. and it even works on CircleCI.
  This is important; before, many kinds of errors could slip through,
  and we've had some annoying problems getting it working.
- Various bug fixes, including problems that our new JavaScript testing
  mechanisms will now automatically detect.
- Better data structuring for Criteria - this is an important data structure
  in the application, so it's better to handle that cleanly.
- Users can no longer change the repo_url (Admins still can)

## 0.7.0 - 2016-04-11

- Added criteria, including making site HTTPS a MUST, and adding 'future'
  criteria so we can add criteria later without making everyone
  lose their badge.
- Switched to using PostgreSQL everywhere, even in development;
  it's better to have development and production environments as close
  to the same as reasonably possible.
- Lots of code restructurings/simplifications
- Search in projects

## fdb83380 - 2015-11-26

- Update gem nokogiri 1.6.6.2 -> 1.6.6.4 due to potential vulnerability
  as reported in CVE-2015-1819.
  We indirectly depend on the gem nokogiri, which is a
  HTML, XML, SAX, and Reader parser.  This is turn depends on
  libxml2 and libxslt.  A vulnerability was found (CVE-2015-1819),
  so we immediately upgraded, ran our regression tests, and pushed to
  production.  It's not clear if this program was vulnerable, but
  it's much better to quickly fix the problem and be sure we've taken care
  of it (it would have taken longer to do the analysis!).

## 2015-10-15

### Added

- "Alpha" milestone - End-to-end functionality.  Can sign in/log in,
  enter project data, save and display it, and provide a badge

## [0.1.0] - 2015-09-04

- Improved criteria

## 2015-08-26

### Added

- Added initial version of Ruby on Rails Application

## 2015-08-06

### Added

- Initial check-in of draft criteria and supporting information.

## 2015-07-22

### Added

- Initial commit.
