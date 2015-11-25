# Contributing

## General

Feedback and contributions are very welcome!
For specific proposals, please provide them as issues or pull requests via our 
[GitHub site](https://github.com/linuxfoundation/cii-best-practices-badge).
Pull requests are especially appreciated!  We use git to track all changes.
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

## Documentation changes

Most of the documentation is in "markdown" format.
All markdown files use the .md filename extension and use
[GitHub-flavored markdown](https://help.github.com/articles/github-flavored-markdown/),
*not* CommonMark or the original Markdown.
In particular,
[newlines in paragraph-like content are considered as real line breaks](https://help.github.com/articles/writing-on-github/)
unlike the original Markdown and CommonMark formats.

Using the "rake" command (described below) implemented in the development
environment can detect some problems in the markdown.
That said, if you don't know how to install the development environment,
don't worry - we'd rather have your proposals, even if you don't know how to
check them that way.

## Code changes

To make changes to the "BadgeApp" web application that implements the criteria,
you may find the following helpful; [INSTALL.md](doc/INSTALL.md) 
(installation information) and [implementation.md](doc/implementation.md)
(implementation information).

The code should strive to be DRY (don't repeat yourself),
clear, and obviously correct.
Some technical debt is inevitable, just don't bankrupt us with it.
Improved refactorizations are welcome.

The web application is primarily written in Ruby on Rails.
Please generally follow the
[community Ruby style guide](https://github.com/bbatsov/ruby-style-guide)
and the complementary
[community Rails style guide](https://github.com/bbatsov/rails-style-guide).
For example, use two-space indents in Ruby.
We don't follow them slavishly, but we do generally try to follow them.

In the Ruby and Rails code, generally prefer symbols over strings when they do
not potentially come from the user.
Symbols are typically faster, with no loss of readability.
There is one big exception:
Data from JSON should normally be accessed with strings, since that's how
Ruby normally reads it.
Rails normally uses the type HashWithIndifferentAccess,
where the difference between symbols and strings is ignored,
but JSON results use standard Ruby hashes where symbols and strings are
considered different; be careful to use the correct type in these cases.

In Ruby please prefer the String operations that do not have side-effects
(e.g., "+", "sub", or "gsub"), and consider freezing strings.
Do *not* modify a String in-place (e.g., using "<<", "sub!", or "gsub!")
until you have applied ".dup" to it.
There are current plans that
[Ruby 3's strings will be immutable](https://twitter.com/yukihiro_matz/status/634386185507311616).
See [issue 11473](https://bugs.ruby-lang.org/issues/11473) for more.
One proposal is to allow "dup" to produce a slightly different object
(a mutable version of String), and since "dup" is already permitted in the
language, this provides a simple backwards-compatible way for us to indicate
that String is mutable in this case.
If you want to build a string using append, do this:

~~~~ruby
"".dup << 'Hello, ' << 'World'
~~~~

There is a small amount of application-specific Javascript.
This is written in Javascript, not CoffeeScript;
it's only a small amount of Javascript, so the advantages of CoffeeScript aren't
 obvious, and far more people know basic Javascript than CoffeeScript.
 For Javascript we are using the
 [Node.js style guide](https://github.com/felixge/node-style-guide).

When adding or changing functionality, please include new tests for them as
part of your contribution.
We are using minitest.

## How to check proposed changes before submitting them

Before submitting changes, please run "rake" (no options) to look for problems,
and fix the problems found.
In some cases it's okay to fix them by disabling the warning in that particular
place, but be careful; it's often better to make a real change,
even if it doesn't matter in that particular case.
The specific list of tools run by default is listed in
[default.rake](lib/tasks/default.rake).
Currently these include at least the following:

* bundle - use bundle to check dependencies ("bundle check || bundle install")
* "rake bundle_audit" - check for vulnerable dependencies
* "rake test" - runs the test suite
* "rake markdownlint" - runs markdownlint, also known as mdl
  (check for errors in markdown text)
* "rake rubocop" - runs Rubocop, which checks code style against the
  [community Ruby style guide](https://github.com/bbatsov/ruby-style-guide)
* "rake rails_best_practices" - check against rails best practices using the gem
  [rails_best_practices](http://rails-bestpractices.com/)
* "rake brakeman" - runs Brakeman, which is a static source code analyzer
  to look for Ruby on Rails security vulnerabilities

Here are some other tools we use, though they are not currently integrated into
the default "rake" checking task:

* OWASP ZAP web application security scanner.
  You are encouraged to use this and other web application scanners to find and
  fix problems.
* JSCS (Javascript style checker) using the Node.js format.
* JSHint (Javascript error detector)

Note that we also use some other continuous integration tools that check changes
 after they are checked into GitHub; if they find problems, please fix them.

## Updating components

For stability we set fixed version numbers of components
(which are primarily gems).
This means that we need to occasionally update our dependencies.
The 'bundle_audit' task will note vulnerable components,
which may need to be updated quickly.
Updates should be handled as a separate commit from functional improvements.
It's okay if the commit includes both a component update and code changes to
make it work.

The "bundle outdated" command lists outdated Ruby gems.
If things look reasonable, run "bundle update" to update all Ruby gems
(or "bundle update GEM" to update a specific gem).
Be *sure* to rerun the tests with "rake".

Ruby itself can be updated.  Use 'cd' to go the top directory of this project,
edit 'Gemfile' to edit the "ruby ..." line so it has the new version number,
then run:

~~~~sh
rbenv install NEW_VERSION_NUMBER
rbenv local NEW_VERSION_NUMBER
rbenv rehash
bundle install
rbenv rehash
~~~~

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
