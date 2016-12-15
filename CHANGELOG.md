# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

This Change Log format is suggested by
<https://github.com/olivierlacan/keep-a-changelog/blob/master/CHANGELOG.md>

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


