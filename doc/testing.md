# Testing

## Workflow

Please review documentation on [testing](http://guides.rubyonrails.org/testing.html). Pull requests should endeavor to increase, not decrease test coverage, as monitored in [Codecov](https://codecov.io/gh/linuxfoundation/cii-best-practices-badge).

Running `m test/features/can_access_home_test.rb:4` will execute just the test from line 4. Removing the `:4` will run all tests in that file.

Write regression tests and ensure that they fail without your fix and pass with it. Include a comment in the test with the Github issue # for context.

## Features

Features that don't need Javascript should default to the headless rack-test driver, which is fastest. Features that need Javascript should set `Capybara.current_driver = Capybara.javascript_driver` as described in this [blog post](http://www.rubytutorial.io/how-to-test-an-autocomplete-with-rails/). To debug features in a browser, preface the test with the driver in an environment variable, like:

```bash
DRIVER=firefox rake test
DRIVER=chrome m test/features/can_access_home_test.rb:4
DRIVER=poltergeist m test/features/can_access_home_test.rb
```

Selenium tests for Safari require this [file](http://selenium-release.storage.googleapis.com/2.48/SafariDriver.safariextz) but still do not seem to be working currently.

Write Capybara features to test the happy path of new features. Test the feature both with the default rack-test (or poltergeist, for tests requiring Javascript) and with Selenium `DRIVER=chrome rake test`.

## External API testing

We use Webmock and VCR to record external API responses and test against them without needing to make actual HTTP requests. If the external services (particularly Github) change their API, you need to delete the corresponding VCR cassette and rerun the test to re-record. This would involve (substituting the actual password for the Github account `ciitest`):

```bash
rm test/vcr_cassettes/github_login.yml
GITHUB_PASSWORD=real_password m test/features/github_login_test.rb
```

After completing the VCR recording, `github_login_test.rb` revokes the authorization of the oauth app so that Github doesn't complain about committing a live token to the repo. To manually walk through the login process with Github OAuth authentication, you can run the rails server with

```bash
RAILS_ENV=test rails s -p 31337 -b 0.0.0.0
```

and then go to http://127.0.0.1:31337 in your web browser.

## Troubleshooting

A flapping test is on that fails apparently randomly.
Do your best to avoid creating flapping tests; they slow development and test,
cause unnecessary work (because they typically warn of the wrong things),
and reduce confidence in the entire test suite.

Flapping tests are a challenge, especially with browser automation that requires Javascript. Examine the `while` loop in [can_login_test.rb](https://github.com/linuxfoundation/cii-best-practices-badge/blob/master/test/features/can_login_test.rb) for one approach to make sure that actions are occurring before testing for their impact.

It's quite helpful to debug a flapping test by running it multiple times. If you're using bash shell, you can run `repeat 10 m test/features/can_login_test.rb` by adding the following to your `~/.bash_profile`:

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

### On Linux

You need to install phantomjs with: `npm install phantomjs-prebuilt`

If you're getting a phantomjs error, go to your `cii-best-practices` directory and try uninstalling phantomjs with: `npm uninstall phantomjs-prebuilt`. You may also need to set your PATH to run npm binaries: `PATH="$PATH:node_modules/.bin/" rake`.

### Mac

If you didn't previously run `./install-badge-dev-env`, install phantomjs with `brew install phantomjs`.

### Binding.pry

When debugging tests (or code!), it is very helpful to insert `binding.pry` where results are confusing. This will open the pry byebug debugger and allow you to access local variables in a REPL. `c` continues execution.
