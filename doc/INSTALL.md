# Installation instructions

Here is how to install the "BadgeApp" web application, for either a development environment or for deployment.  On most systems this is a fairly quick and painless process, because we empahsize using widely-used tools designed for the purpose.  Just follow the instructions below.

The web application is implemented with Ruby on Rails.  In development we store data in SQLite; the production system stores the data in Postgres.

Our installation approach installs a specific version of Ruby and specific versions of the Ruby gems that BadgeApp uses (including the ones in Rails).

## Development environment prerequisites

You need a general-purpose Linux distribution (e.g., Ubuntu, Fedora, Debian, and Red Hat Enterprise Linux, or SuSE) or MacOS.   If you're using Windows, install virtual machine software (such as VirtualBox) and install Linux on a virtual machine.  If you use a virtual machine, maximize its memory; it will run in less, but many of the monitoring tools enabled during development consume a lot of memory.

Install the following using your system package management tools (e.g., apt-get, yum, dnf, or brew):

* git, to get some of the programs we use.  Installing git will also install some libraries such as curl, zlib, openssl, expat, and libiconv.
* Ruby (version 1.9.3 or newer), to bootstrap installing the Ruby we'll use
* SQLite3 database system, used in development for data storage
* C compiler and basic libraries for rebuilding ruby. Install a sane C compiler such as gcc or clang.  See the [ruby-build suggested build environment](https://github.com/sstephenson/ruby-build/wiki#suggested-build-environment) for how to do install the other required components.

You also need to install [rbenv](https://github.com/sstephenson/rbenv) to follow the instructions given here.  See the [rbenv basic github checkout](https://github.com/sstephenson/rbenv#basic-github-checkout) instructions for one approach for installing rbenv.  The rbenv tool lets you select a specific version of Ruby, and from there, select specific versions of other libraries.  An alternative way to select specific versions is to use rvm, but that approach is not documented here.


## Development environment install process

First, use 'git' to download BadgeApp, and then "cd" into that directory.  You can do this at the command line (assuming git is installed) with:

~~~~
git clone <https://github.com/linuxfoundation/cii-best-practices-badge.git>
cd cii-best-practices-badge
~~~~

For development we currently fix the version of Ruby at exactly 2.2.2.  We also need to install a number of gems (including the ones in Rails); we will install the versions specified in Gemfile.lock.  We will do completely separate per-project Gem installs, to prevent potential interference issues in the development environment.  Here's a way to do that.  We presume that your current directory is the top directory of the project, aka cii-best-practices-badge.

~~~~
# Force install Ruby 2.2.2 using rbenv:
rbenv install 2.2.2
rbenv local 2.2.2 # In this directory AND BELOW, use Ruby 2.2.2 instead.

# This makes "bundle ..." use rbenv's version of Ruby:
git clone git://github.com/carsomyr/rbenv-bundler.git ~/.rbenv/plugins/bundler

gem sources --add <https://rubygems.org>  # Ensure you're getting gems here
gem install bundler  # Install the "bundler" gem package manager.
rbenv rehash
bundle install       # Install gems we use in Gemfile.lock, including Rails
rake db:setup        # Setup database and seed it with dummy data
~~~~

Some documents about Rails will tell you to execute "bin/rake" instead of "rake" or to use "bundle exec ..." to execute programs.  Using rbenv-bundler (above) eliminates the need for that.  While "bundle exec..." or "bin/..." are widely used, they are also extremely error-prone user interfaces; if you forget the prefixes, then it can *appear* to work yet subtly do the wrong thing.  Using rbev-bundler means that the *easy* way is the *correct* way.  A vitally important way to prevent defects is to make the *easy* way the *correct* way.

You can use "bundle outdated" to show the gems that are outdated; be sure to test after updating any gems.


## Running locally

Once your development environment is ready, you can run the application with:

~~~~
rails s
~~~~

This will automatically set up what it needs to, and then run the web application.  You can press control-C at any time to stop it.  Then point your web browser at "localhost:3000".


## Contributing in general

See [CONTRIBUTING.md](../CONTRIBUTING.md) for information on how to contribute changes.

## Deployment instructions

This is designed to be easily deployed simply by doing a "git push" to an appropriate destination.

At this point, a deployment is automatically done to a staging system once it's checked into the repository on the master branch.


## See also

See the separate "[background](./background.md)" and "[criteria](./criteria.md)" pages for more information.

