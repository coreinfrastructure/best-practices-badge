# Contributing

## General

Feedback and contributions are very welcome!
For specific proposals, please provide them as issues or pull requests via our
[GitHub site](https://github.com/linuxfoundation/cii-best-practices-badge).
Pull requests are especially appreciated!
For general dicussion, feel free to use the
[cii-badges mailing list](https://lists.coreinfrastructure.org/mailman/listinfo/cii-badges).

If you just want to propose or discuss changes to the criteria,
the first step is proposing changes to the criteria text,
which is in the file [criteria.md](doc/criteria.md).
The "doc/" directory has information you may find helpful,
including [other.md](doc/other.md) and [background.md](doc/background.md).

Submitting pull requests is especially helpful.
We strongly recommend creating different branches for different (logical)
changes, and creating a pull request when you're done into the master branch.
See the GitHub documentation on
[creating branches](https://help.github.com/articles/creating-and-deleting-branches-within-your-repository/)
and
[using pull requests](https://help.github.com/articles/using-pull-requests/).

We use GitHub to track all changes via its
[issue tracker](https://github.com/linuxfoundation/cii-best-practices-badge/issues) and
[pull requests](https://github.com/linuxfoundation/cii-best-practices-badge/pulls).
Specific changes are proposed using those mechanisms.
Issues are assigned to an individual, who works it and then marks it complete.
If there are questions or objections, the conversation area of that
issue or pull request is used to resolve it.

All contributions (including pull requests) must agree to
the [Developer Certificate of Origin (DCO) version 1.1](doc/dco.txt).
This is exactly the same one created and used by the Linux kernel developers
and posted on <http://developercertificate.org/>.
This is a developer's certification that he or she has the right to
submit the patch for inclusion into the project.
Simply submitting a contribution implies this agreement, however,
please include a "Signed-off-by" tag in every patch
(this tag is a conventional way to confirm that you agree to the DCO).
You can do this with <tt>git commit --signoff</tt>.
Another way to do this is to write the following at the end of the commit
message, on a line by itself separated by a blank line from the body of
the commit:

    Signed-off-by: Your Name <your.email@example.com>

You can signoff by default in this project by creating a file
(say "git-template") that contains
some blank lines and the signed-off-by text above;
then configure git to use that as a commit template.  For example:

    git config commit.template ~/cii-best-practices-badge/git-template

Please do not use or include trailing whitespace.
Since they are often not visible, they can cause silent problems
and misleading unexpected changes.
Some editors (e.g., Atom) quietly delete them by default.

## Vulnerability reporting (security issues)

If you find a significant vulnerability, or evidence of one,
please send an email to the security contacts that you have such
information, and we'll tell you the next steps.
For now, the security contacts are:
David A. Wheeler <dwheeler-NOSPAM@ida.org>,
Dan Kohn <dankohn-NOSPAM@linux.com>,
Emily Ratliff <eratliff-NOSPAM@linuxfoundation.org>,
and Sam Khakimov <skhakimo-NOSPAM@ida.org>
(remove the -NOSPAM markers).


## Documentation changes

Most of the documentation is in "markdown" format.
All markdown files use the .md filename extension.
Where reasonable, limit yourself to Markdown
that will be accepted by different markdown processors
(e.g., what is specified by CommonMark or the original Markdown)
In practice we use
the version of Markdown implemented by GitHub when it renders .md files,
and you can use its extensions
(in particular, mark code snippets with the programming language used).
This version of markdown is sometimes called
[GitHub-flavored markdown](https://help.github.com/articles/github-flavored-markdown/).
In particular, blank lines separate paragraphs; newlines inside a paragraph
do *not* force a line break.
Beware - this is *not*
the same markdown algorithm used by GitHub when it renders
issue or pull comments; in those cases
[newlines in paragraph-like content are considered as real line breaks](https://help.github.com/articles/writing-on-github/);
unfortunately this other algorithm is *also* called
GitHub rendered markdown.
(Yes, it'd be better if there were standard different names
for different things.)

The style is basically that enforced by the "markdownlint" tool.
Don't use tab characters, avoid "bare" URLs (in a hypertext link, the
link text and URL should be on the same line), and try to limit
lines to 80 characters (but ignore the 80-character limit if that would
create bare URLs).
Using the "rake markdownlint" or "rake" command
(described below) implemented in the development
environment can detect some problems in the markdown.
That said, if you don't know how to install the development environment,
don't worry - we'd rather have your proposals, even if you don't know how to
check them that way.

Do not use trailing two spaces for line breaks, since these cannot be
seen and may be silently removed by some tools.
Instead, use <tt>&lt;br&nbsp;&gt;</tt> (an HTML break).

## Code changes

To make changes to the "BadgeApp" web application that implements the criteria,
you may find the following helpful; [INSTALL.md](doc/INSTALL.md)
(installation information) and [implementation.md](doc/implementation.md)
(implementation information).

The code should strive to be DRY (don't repeat yourself),
clear, and obviously correct.
Some technical debt is inevitable, just don't bankrupt us with it.
Improved refactorizations are welcome.

### Ruby

The web application is primarily written in Ruby on Rails.
Please generally follow the
[community Ruby style guide](https://github.com/bbatsov/ruby-style-guide)
and the complementary
[community Rails style guide](https://github.com/bbatsov/rails-style-guide).
We don't follow them slavishly, but we do generally try to follow them.
For example, in Ruby:

* [use two-space indents](https://github.com/bbatsov/ruby-style-guide#spaces-indentation)
* [use Unix line-endings](https://github.com/bbatsov/ruby-style-guide#crlf)
* [use single-quoted strings when you don't need string interpolation or special symbols](https://github.com/bbatsov/ruby-style-guide#consistent-string-literals)
* [Use the Ruby 1.9 hash literal syntax when your hash keys are symbols.](https://github.com/bbatsov/ruby-style-guide#hash-literals)
* [Prefer symbols instead of strings as hash keys](https://github.com/bbatsov/ruby-style-guide#hash-literals)

In Ruby,
[prefer symbols over strings (especially as hash keys)](https://github.com/bbatsov/ruby-style-guide#symbols-as-keys)
when they do not potentially come from the user.
Symbols are typically faster, with no loss of readability.
There is one big exception:
Data from JSON should normally be accessed with strings, since that's how
Ruby normally reads it.
Rails normally uses the type HashWithIndifferentAccess,
where the difference between symbols and strings is ignored,
but JSON results use standard Ruby hashes where symbols and strings are
considered different; be careful to use the correct type in these cases.

Our goal is for the application to be thread-safe, so please
follow the guidelines in
[How Do I Know Whether My Rails App Is Thread-safe or Not?](https://bearmetal.eu/theden/how-do-i-know-whether-my-rails-app-is-thread-safe-or-not/);
see also
[How to test multithreaded code](http://www.mikeperham.com/2015/12/14/how-to-test-multithreaded-code/).
It's challenging to be certain an application is thread-safe,
so we aren't currently running it with multiple threads,
but we intend for it to be thread-safe and use that in the future.

In Ruby please prefer the String operations that do not have side-effects
(e.g., "+", "sub", or "gsub"), and consider freezing strings.
Do *not* modify a String literal in-place
(e.g., using "<<", "sub!", or "gsub!") until you have applied ".dup" to it.
There are current plans that
[Ruby 3's string literals will be immutable](https://twitter.com/yukihiro_matz/status/634386185507311616).
See [issue 11473](https://bugs.ruby-lang.org/issues/11473) for more.
One proposal is to allow "dup" to produce a mutable string;
since "dup" is already permitted in the language,
this provides a simple backwards-compatible way for us to indicate
that the String is mutable in this case.
If you want to build a string using append, do this:

~~~~ruby
"".dup << 'Hello, ' << 'World'
~~~~

We encourage using
[# frozen_string_literal: true](https://bugs.ruby-lang.org/issues/8976)
near the beginning of each file.
This 'magic comment' (added in Ruby 2.3.0) automatically freezes
string literals, increasing speed, preventing accidental changes, and
will help us get ready for the planned Ruby transition
to immutable string literals.

We use
[Ruby version 2.3.0](https://www.ruby-lang.org/en/news/2015/12/25/ruby-2-3-0-released/),
but do not use the safe navigation operator '&amp;.' quite yet.
Our static analysis tools' parsers cannot yet handle syntax new to 2.3.0
(it *is* in [upstream](https://github.com/whitequark/parser/issues/209)).
This is different from the frozen_string_literal magic comment, because
a parser that ignores comments will still work.

### Javascript

There is a small amount of application-specific Javascript.
This is written in Javascript, not CoffeeScript;
it's only a small amount of Javascript, so the advantages of
CoffeeScript aren't
obvious, and far more people know basic Javascript than CoffeeScript.
For Javascript we are using the
[Node.js style guide](https://github.com/felixge/node-style-guide).
Please ensure changes pass JSCS (Javascript style checker)
using the Node.js format.

If you edit the Javascript, beware of ready events.
Rails' turbolinks gem claims that it
["works great with the jQuery framework"](https://github.com/rails/turbolinks),
but this is misleading.
[Turbolinks breaks <tt>"$(document).ready"</tt>](http://guides.rubyonrails.org/working_with_javascript_in_rails.html#page-change-events)
(an extremely common construct)
and by default requires you to use a nonstandard on..."page:change".
To solve this botch in turbolinks we use
[jquery-turbolinks](https://github.com/kossnocorp/jquery.turbolinks),
which makes "ready" work correctly.
Please do *not* use <tt>$(document).on('ready', function)</tt>,
because jquery-turbolinks doesn't fix those;
instead, use <tt>$(document).ready(function)</tt> or <tt>$(function)</tt>.

### Shell

There's a small amount of Bourne shell code
(the script that sets up a new development install).
If you modify it, make sure it passes shellcheck
(a static analysis tool for shell).

### Automated tests

When adding or changing functionality, please include new tests for them as
part of your contribution.

We require the Ruby code to have at least 90% statement coverage;
please ensure your contributions do not lower the coverage below that minimum.
The Ruby code uses minitest as the test framework, and we use
'vcr' to record live data for replaying later.
Additional tests are very welcome.

We encourage tests to be created first, run to ensure they fail, and
then add code to implement the test (aka test driven development).
However, each git commit should have both
the test and improvement in the *same* commit,
because 'git bisect' will then work well.

## How to check proposed changes before submitting them

Before submitting changes, you *must*
run 'rake' (no options) to look for problems,
and fix the problems found.
In some cases it's okay to fix them by disabling the warning in that particular
place, but be careful; it's often better to make a real change,
even if it doesn't matter in that particular case.
The specific list of tools run by default is listed in
[default.rake](lib/tasks/default.rake).
Currently these include at least the following:

* bundle - use bundle to check dependencies ("bundle check || bundle install")
* "rake bundle_audit" - check for vulnerable dependencies
* "rake test" - runs the automated test suite
* "rake markdownlint" - runs markdownlint, also known as mdl
  (check for errors in markdown text)
* "rake rubocop" - runs Rubocop, which checks code style against the
  [community Ruby style guide](https://github.com/bbatsov/ruby-style-guide)
* "rake rails_best_practices" - check against rails best practices using the gem
  [rails_best_practices](http://rails-bestpractices.com/)
* "rake brakeman" - runs Brakeman, which is a static source code analyzer
  to look for Ruby on Rails security vulnerabilities
* "license_finder" - checks OSS licenses of dependencies (transitively).
* "git diff --check" - detect trailing whitespace in latest diff

Here are some other tools we use, though they are not currently integrated into
the default "rake" checking task:

* OWASP ZAP web application security scanner.
  You are encouraged to use this and other web application scanners to find and
  fix problems.
* JSCS (Javascript style checker) using the Node.js format.
* JSHint (Javascript error detector)
* W3C link checker <https://validator.w3.org/checklink>
* W3C markup validation service <https://validator.w3.org/>

Note that we also use
[CicleCI](https://circleci.com/gh/linuxfoundation/cii-best-practices-badge)
for continuous integration tools to check changes
after they are checked into GitHub; if they find problems, please fix them.

When running the static analysis tools (e.g., via 'rake')
there will be some spurious warnings.
These warnings occur because we have updated to Ruby version 2.3.0,
but the Ruby parsers have not updated yet.
These warnings you should ignore are:

    warning: parser/current is loading parser/ruby22, which recognizes
    warning: 2.2.x-compliant syntax, but you are running 2.3.0.
    warning: please see https://github.com/whitequark/parser#compatibility-with-ruby-mri.


## Supply chain (reuse)

We like reusing components, but please evaluate all new components
before adding them.
In particular:

* Before adding a Ruby gem, check its popularity on
  <https://www.ruby-toolbox.com/>, and prefer "more popular" gems.
  A popular gem may have unintentional or intentional vulnerabilities,
  but they are less likely, and are more likely to be noticed.
* For Ruby gems, look at its data at <https://rubygems.org/> to learn
  more about it. E.G., is it still actively maintained?
* All required reused components MUST be open source software (OSS).
  It is *not* acceptable to insert a dependency
  that *requires* proprietary software; making it portable so it *can* use
  some proprietary software is gratefully welcome.
  Obviously, we also have to combine them legally in the way they are used.

We use 'license_finder' to help ensure that we're using OSS legally.
In general we want to use GPL-compatible OSS licenses.
Acceptable licenses include MIT,
BSD 2-Clause "Simplified" or "FreeBSD" License (BSD-2-Clause),
BSD 3-Clause "New" or "Revised" License (BSD-3-Clause), the
[original Ruby license](https://spdx.org/licenses/Ruby.html) (Ruby) or the
[current Ruby license](https://www.ruby-lang.org/en/about/license.txt)
(the latter includes BSD-2-Clause as an option),
GNU Library or "Lesser" General Public License (any version),
GNU General Public License version 2.0 or later (GPL-2.0+), and the
GNU General Public License version 3.0 ("or later" or not)
(GPL-3.0 or GPL-3.0+).
We can use Apache License 2.0 (Apache-2.0)
and GPL-2.0 exactly (GNU GPL version 2.0 only),
but the Apache-2.0 and GPL-2.0 only have potential compatibility issues.
First check if that Apache-2.0 and GPL-2.0 only components are
in separate executables (if so, no problem).
Most software licensed using the GPL version 2.0 is actually
GPL-2.0+ (GPL version 2 or later), and GPL version 3 is known to be
compatible with the Apache 2.0 license, so this is not a common problem.
For more on license decisions see doc/dependency_decisions.yml;
you can also run 'rake' and see the generated report
license_finder_report.html.

For any reused software, prefer software that
appears to be currently maintained (e.g., has recent updates),
has more than one developer, and appears to be applying good practices
(e.g., it uses semantic versioning and have a ChangeLog).
Someday we hope to add "have one of our badges" as a preference.

In general, prefer a Rails-specific gem over a generic Ruby gem, and
for Javascript Node.js packages prefer a Ruby gem that repackages it.
The repackage will often help make it work more cleanly
with the Rails application, and it also suggests that the package is
a more common one (and thus more likely to be maintained).

If you add a Ruby gem, put its *fixed* version number in the Gemfile file,
and please add a brief comment to explain what it is and/or why it's there.

Our default 'rake' process includes bundle_audit, which
checks for dependencies with known vulnerabilities.
See the next section for how to detect obsolete reused components, and
how we update them.

## Updating reused components

For stability we set fixed version numbers of reused components,
which are primarily gems.
We use the bundler Ruby gem package management system (<http://bundler.io>);
file 'Gemfile' lists direct gem dependencies; 'Gemfile.lock' lists them
transitively.
This means that we need to occasionally update our dependencies.

Two commands can help detect outdated components:

- The 'bundle_audit' task will note vulnerable components,
  which may need to be updated quickly.
  This task is run as part of the default 'rake' checking task.
- The 'bundle outdated' command lists all outdated Ruby gems.
  Our continuous integration suite (linked to from the README) also uses
  [Gemnasium](https://gemnasium.com/linuxfoundation/cii-best-practices-badge)
  to identify all outdated dependencies.

Use 'bundle update GEM' to update a specific gem
('bundle update' will update all Ruby gems - that may be too much at once).
You *must* run 'rake' after updating; this will run the regression tests,
check the licenses (transitively, which is important because
sometimes library updates add new dependencies), and so on.
Updates should be handled as a separate commit from functional improvements.
One exception: it's okay if the commit includes
both a component update and the minimum set of code changes to
make the update work.

Ruby itself can be updated.  Use 'cd' to go the top directory of this project,
use 'git pull' to ensure this branch is up-to-date,
edit 'Gemfile' to edit the "ruby ..." line so it has the new version number
(if it's not already different), then run:

~~~~sh
(cd $HOME/.rbenv/plugins/ruby-build && git pull) # Update ruby-build list
rbenv install NEW_VERSION_NUMBER                 # Install with ruby-build
rbenv local NEW_VERSION_NUMBER                   # Use new Ruby version
gem install bundler                              # Reinstall bundler for it
rbenv rehash                                     # Tell rbenv about bundler
bundle install                                   # Reinstall gems
rbenv rehash                                     # Update rbenv commands
~~~~

For more details about updating Ruby versions with rbenv, see
<https://github.com/rbenv/ruby-build> and
<http://dan.carley.co/blog/2012/02/07/rbenv-and-bundler/>.
Note that 'rbenv install 2.3.0' is equivalent to the longer
<tt>ruby-build 2.3.0 $HOME/.rbenv/versions/2.3.0</tt>.

Once the component update has been verified,
it can be checked in as a new commit.

## Keeping up with external changes

If you've already set your git remote 'upstream' per our previous instructions:

~~~~sh
git remote add upstream \
    https://github.com/linuxfoundation/cii-best-practices-badge
~~~~

Then running 'git pull master upstream' will pull the current version.
If the version of Ruby has changed (in the Gemfile),
use the 'Ruby itself can be updated' instructions.
If gems have been added, run "bundle install" to install the new ones.


## Creating pull requests

To submit a specific already-created change, submit a pull request.
See: <https://help.github.com/articles/using-pull-requests/>
