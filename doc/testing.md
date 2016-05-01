# Testing

## Workflow

Please review documentation on [testing](http://guides.rubyonrails.org/testing.html). Pull requests should endeavor to increase, not decrease test coverage, as monitored in [Coveralls](https://coveralls.io/github/linuxfoundation/cii-best-practices-badge).

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

## Troubleshooting

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
