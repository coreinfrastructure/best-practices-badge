# Testing

This document briefly discusses details involved in testing
(dynamically executing the code with specific inputs to see if expected
behaviors are produced).
We also use other techniques to detect problems ahead-of-time; see
[CONTRIBUTING.md](../CONTRIBUTING.md) for more about the other
analysis tools and processes we use.

## Workflow

Please review the Rails documentation on [testing](http://guides.rubyonrails.org/testing.html). Pull requests should endeavor to increase, not decrease test coverage, as monitored in [Codecov](https://codecov.io/gh/coreinfrastructure/best-practices-badge).

Running `rails t test/features/can_access_home_test.rb:4` will execute just the test from line 4. Removing the `:4` will run all tests in that file.

Write regression tests and ensure that they fail without your fix and pass with it. Include a comment in the test with the Github issue # for context.

## Parallel testing

Our tests should be easily parallelizable *if* you use process
parallelism. Tests will *not* work if you use threading to parallelize tests.

[RailsConf 2018: Keynote: The Future of Rails 6: Scalable by Default by Eileen Uchitelle](https://www.youtube.com/watch?v=8evXWvM4oXM)
discusses the parallel testing capabilities of Rails 6.
Rails 6 is designed to support parallel testing with either processes
or threads, with processes as the default.

This *application* is thread-safe, but our *testing* is currently not.
We use system tests, which are not thread safe (see the talk).
In addition, during testing we sometimes mutate shared global values.
For example, some tests modify Rails.application.config.deny_login
so that they can test different configurations.
That works fine if tests are executed in parallel using processes
(because the mutations are not shared), but does not work if
the tests are in threads.

If you need the tests themselves to be thread-safe, then you'll need to
modify something.  One way is to change some shared configuration values to be
[thread-local](https://www.rubytapas.com/2016/11/20/ruby-thread-local-variables/).
Another is to change some methods to take parameters, so that
you can provide different parameters during testing.

## System Tests

We are in the process of replacing all uses of the class
CapybaraFeatureTest (subclass of Capybara::Rails::TestCase)
with the standard Rails system tests, which use the
class ApplicationSystemTestCase (subclass of ActionDispatch::SystemTestCase).

Warning! By default "rails test" (and thus rake) do *NOT* run system tests.
You must run system tests via "rails test:system". To run *both*
system and non-system tests, say "rails test:system test" (in that order).
This commit modifies our CI pipeline so that it runs BOTH
system and non-system tests. So for most people this detail will be quietly
handled correctly. Rails 6.1 adds "rails test:all", so when we get
to Rails 6.1 it will be easier to ask for all (normal) tests.

Rails system tests normally interact with an actual browser.
In some cases they can be configured to use the `rack_test` backend and
merely simulate a browser; that is faster, but it doesn't support
JavaScript and the tests are not as realistic.
So here we'll discuss the normal, interacting with an actual browser.

For basic information on how to create syystem tests, see the
[Rails guide on testing (system testing section)](https://guides.rubyonrails.org/testing.html#system-testing).

Here's how a Rails system test normally works, as explained in
[Rails 6 System Tests, From Top to Bottom](https://avdi.codes/rails-6-system-tests-from-top-to-bottom/)

* "A MiniTest test case, augmented with...
* Capybara testing helpers, which start and stop an instance of your app,
  and provide an English-like DSL on top of...
* The selenium-webdriver gem, which provides a Ruby API for using the...
* ... WebDriver protocol in order to interact with...
* A WebDriver tool such as chromedriver or geckodriver, which…
* Is automatically downloaded by the webdrivers gem.
 The WebDriver tool automates...
* A browser, such as Chrome."

## Features

Features that don't need JavaScript should default to the headless rack-test driver, which is fastest. Features that need JavaScript should set `Capybara.current_driver = Capybara.javascript_driver` as described in this [blog post](http://www.rubytutorial.io/how-to-test-an-autocomplete-with-rails/). To debug features in a browser, preface the test with the driver in an environment variable, like:

```bash
DRIVER=firefox rails t
DRIVER=chrome rails t test/features/can_access_home_test.rb:4
DRIVER=poltergeist rails s test/features/can_access_home_test.rb
```

Note that adding chrome or firefox as a DRIVER will let you observe the test in real time. This slows down the test but can be very helpful in revealing the cause of test problems.

Selenium tests for Safari require this [file](http://selenium-release.storage.googleapis.com/2.48/SafariDriver.safariextz) but still do not seem to be working currently.

Write Capybara features to test the happy path of new features. Test the feature both with the default rack-test (or poltergeist, for tests requiring Javascript) and with Selenium `DRIVER=chrome rails test`.

## External API testing

We use Webmock and VCR to record external API responses and test against them without needing to make actual HTTP requests. If the external services (particularly Github) change their API, you need to delete the corresponding VCR cassette and rerun the test to re-record. This would involve (substituting the value of `GITHUB_PASSWORD` for the actual password for the Github account `bestpracticestest`):

```bash
rm test/vcr_cassettes/github_login.yml
DRIVER=chrome GITHUB_PASSWORD=real_password rails t test/features/github_login_test.rb
```

When re-recording cassettes involving the GitHub login
you must use DRIVER=chrome (or similar).
Github has an anti-bot mechanism that requires real mouse movement
to authorize an application.

Note: the robots.txt testing won't pass while you're doing this, because
some tests have to be run in different modes.  Just capture the data in
a VCR cassette, and then re-run the tests with the captured data.

After completing the VCR recording, `github_login_test.rb` revokes the
authorization of the oauth app so that Github doesn't complain about
committing a live token to the repo.  As an additional security step you
should redact the token used in the vcr by opening `github_login.yml` and
searching for `access_token`.  Once found you can redact it from all .yml
files by running:

~~~~sh
cd test/vcr_cassettes
sed -i 's/<ACCESS_TOKEN>/REDACTED/' *.yml
cd ../..
~~~~

To manually walk through the login process with Github OAuth authentication,
you can run the rails server with

```bash
RAILS_ENV=test rails s -p 31337 -b 0.0.0.0
```

and then go to <http://127.0.0.1:31337> in your web browser.

If you re-record a cassette using DRIVER=, the cassette may correctly
add the bestpracticestest privilege and record what happened,
but then fail to revoke the `bestpracticestest` privilege.
That's a problem, because future recording efforts will fail
(the recording system presumes it doesn't already have the privileges,
and will fail when it tries to add them).
We'd like to fix that, but have not managed to do so yet
(it only matters when you record a new cassette, which is a rare event).
You can manually force removal by logging in to GitHub as `bestpracticestest`,
going to <https://github.com/settings/applications>, select
Applications / Authorized OAuth Apps, and revoke the privilege.

## VCR files and whitespace

If you re-record the VCR files, the VCR gem may insert extra whitespace
at the end of some YML lines.  That's not allowed by our rake task.

You can remove the unacceptable trailing whitespace in the YML
files created by VCR by running the following:

~~~~sh
cd test/vcr_cassettes
sed -e 's/ $//' -i.bak *.yml
rm *.bak
cd ../..
~~~~

## Security issues

We believe that the test setup does not have a security issue.

We want to test what happens when a user who logs into GitHub
tries to use the system.  In those cases we use a special GitHub user
`bestpracticestest`.  This user controls no real-world projects, just a test project,
and we only grant privileges to user `bestpracticestest` to control the test data
(which we already include in the public distribution).
So even if an attacker can use data in the cassettes to take control of
the `bestpracticestest` user, that user account has no privileges worth taking.

In addition, we create special keys that are recorded in the cassettes,
and those keys are revoked at the end of the test.
Thus, any access key stored in the cassette won't work later anyway.

## Troubleshooting

A flapping test is one that fails apparently randomly.
Do your best to avoid creating flapping tests; they slow development and test,
cause unnecessary work (because they typically warn of the wrong things),
and reduce confidence in the entire test suite.

Flapping tests are a challenge, especially with browser automation that requires JavaScript. Examine the `until` loop in the `ensure_choice` method of [login_test.rb](https://github.com/coreinfrastructure/best-practices-badge/blob/master/test/features/login_test.rb) for one approach to make sure that actions are occurring before testing for their impact.

It's quite helpful to debug a flapping test by running it multiple times. If you're using bash shell, you can run `repeat 10 rails t test/features/can_login_test.rb` by adding the following to your `~/.bash_profile`:

```bash
# http://www.shellhacks.com/en/HowTo-Run-and-Repeat-a-Command-N-Times-in-Bash
function repeat() {
    number=$1
    shift
    for n in $(seq $number); do
      $@
    done
}
```

Sometimes recording a cassette will fail; see the discussion above.

### On Linux

You need to install phantomjs with: `npm install phantomjs-prebuilt`

If you're getting a phantomjs error, go to your `cii-best-practices` directory and try uninstalling phantomjs with: `npm uninstall phantomjs-prebuilt`. You may also need to set your PATH to run npm binaries: `PATH="$PATH:node_modules/.bin/" rake`.

### Mac

If you didn't previously run `./install-badge-dev-env`, install phantomjs with `brew install phantomjs`.

### Binding.pry

When debugging tests (or code!), it is very helpful to insert `binding.pry` where results are confusing. This will open the pry byebug debugger and allow you to access local variables in a REPL. `c` continues execution.

## Fixing pushes to heroku

It's unfortunately possible for the git repo on heroku to get its
state mildly corrupted. You'll see these errors in the deploy step
while it fails:

~~~~
    remote: Verifying deploy... done.
    fatal: protocol error: bad line length character: fata
    error: error in sideband demultiplexer
~~~~

You can re-run the deploy step, but that's absurd.
You can solve this by cleaning out its repo:

~~~~sh
    heroku plugins:install heroku-repo
    heroku repo:reset -a <app-name>
~~~~

Then redeploy (e.g., by going to Heroku and forcibly rerunning a deploy step).

## Updating gem `translation`

Testing the `translation` gem is a little tricky, because it's primarily
a small shim to an external service *and* we hook a shim around it.
Our current process:

1. In the local main branch run `rake translation:sync` to synchronize things
   to a known state. If that changes anything, create a branch and create
   a pull request for that current state.
2. Still in the local branch, update the gem. Now re-run
   `rake translation:sync`. Check to see if anything has changes.
   Nothing should have changed (unless a translator managed to edit something
   at exactly the right time), and it should report no errors connecting
   to the translation system. If all is okay, then updating the translation
   process is fine.

## See also

Project participation and interface:

* [CONTRIBUTING.md](../CONTRIBUTING.md) - How to contribute to this project
* [INSTALL.md](INSTALL.md) - How to install/quick start
* [governance.md](governance.md) - How the project is governed
* [roadmap.md](roadmap.md) - Overall direction of the project
* [background.md](background.md) - Background research
* [api](api.md) - Application Programming Interface (API), inc. data downloads

Criteria:

* [Criteria for passing badge](https://bestpractices.coreinfrastructure.org/criteria/0)
* [Criteria for all badge levels](https://bestpractices.coreinfrastructure.org/criteria)

Development processes and security:

* [requirements.md](requirements.md) - Requirements (what's it supposed to do?)
* [design.md](design.md) - Architectural design information
* [implementation.md](implementation.md) - Implementation notes
* [testing.md](testing.md) - Information on testing
* [assurance-case.md](assurance-case.md) - Why it's adequately secure (assurance case)
