# Contributing

Feedback is very welcome!
For specific proposals, please provide them as issues or pull requests via our
[GitHub site](https://github.com/linuxfoundation/cii-best-practices-badge).
Pull requests are especially appreciated!
For general dicussion, feel free to use the [mailing list](https://lists.coreinfrastructure.org/mailman/listinfo/cii-badges).

If you just want to propose or discuss changes to the criteria, the
first step is proposing changes to the criteria text,
which is in the file doc/criteria.md.

To make changes to the web application that implements the criteria,
see the installation information in [INSTALL.md](docs/INSTALL.md)
and the implementation information in
[implementation.md](docs/implementation.md)
The file [background.md](docs/background.md) has more information.

The web application is written in Ruby on Rails.
Please follow the
[community Ruby style guide](https://github.com/bbatsov/ruby-style-guide).
when writing code.
When adding or changing functionality, please include new tests to
cover them.  The system uses minitest.

Before submitting changes, please run "rake".
This will run a set of tools to change the software, including:

* "rake rubocop" - runs Rubocop, which checks code style
* "rake brakeman" - runs Brakeman, which is a static source code analyzer
  to look for Ruby on Rails security vulnerabilities.
* "rake test" - runs the test suite.


