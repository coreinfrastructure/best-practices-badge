# Installation instructions

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

Here is how to install the "BadgeApp" web application, for either a development
environment or for deployment.
On most systems this is a fairly quick and painless process.

We provide a simple script that does the work, and we emphasize using
widely-used tools designed for the purpose.
Our installation approach installs a specific version of Ruby and specific
versions of the Ruby gems that BadgeApp uses (including the ones in Rails).
The web application is implemented with Ruby on Rails.
In development we store data in SQLite;
the production system stores the data in Postgres.

## Development environment prerequisites

You need a Unix-like system.
This includes a general-purpose Linux distribution
(e.g., Ubuntu, Fedora, Debian, Red Hat Enterprise Linux, or SuSE) or MacOS.
If you're using Windows, install virtual machine software (such as VirtualBox)
and install Linux on a virtual machine.
We do not expect Windows to work directly.

If you use a virtual machine for development, maximize its memory.
It will run in less memory, and in particular the production version uses less.
However, we enable many monitoring tools during development and they consume a
lot of memory.

You need a working Internet connection.
Some organizations use an SSL/TLS interception proxy, which intercepts all
SSL/TLS traffic.
If you must work with those, and you are willing to completely trust that proxy,
then you need to download and install that proxy's certificates.
E.G., to install them on Ubuntu, when your current directorty has the
certificates as .crt files, run this:

~~~~sh
# ONLY do this if you have an SSL/TLS interception proxy and are using Ubuntu
sudo bash
ca=/usr/share/ca-certificates
tip=tls-interception-proxy
mkdir -p $ca/$tip
cp *.crt $ca/$tip
cd $ca
ls $tip/* >> /etc/ca-certificates.conf
update-ca-certificates
exit # End "sudo bash"
~~~~

If you're using MacOS, you need to install Homebrew
(it provides the package manager command <tt>brew</tt>).
See <http://brew.sh/> for installation instructions. As reported by
<tt>brew doctor</tt>, you should also do the following
(if it isn't already there) so that updated programs from brew take precedence:

~~~~sh
echo "export PATH=/usr/local/bin:$PATH" >> ~/.bash_profile  # MacOS brew
~~~~

You also need a version of git installed.
If you don't already have it set up, install it using your system installation
tools, e.g., at the command line:

- <kbd>sudo apt-get install git</kbd> (Debian, Ubuntu)
- <kbd>yum install git</kbd> (Red Hat Enterprise Linux, CentOS, older Fedora)
- <kbd>dnf install git</kbd> (newer Fedora)
- <kbd>emerge install git</kbd> (Gentoo)
- <kbd>brew install git</kbd> (MacOS)

Also, [set up Git](https://help.github.com/articles/set-up-git/)
so it will correctly record who you are; here are the key commands
(please use your own name and email address):

~~~~sh
git config --global user.name "YOUR NAME"
git config --global user.email "YOUR EMAIL ADDRESS"
~~~~

We also recommend adding these lines to your $HOME/.gitconf file
(per a recommendation about git integrity by Eric Myhre;
the [fetch] and [receive] options default to whatever [transfer] is):

~~~~
# check that anything we're getting is complete and sane on a regular basis
[transfer]
fsckObjects = true
~~~~


## Forking the repo

You'll now need to fork the repo on GitHub.
[GitHub's instructions on forking a repo](https://help.github.com/articles/fork-a-repo/)
describe this in general.

In our case, use your web browser to view
<https://github.com/linuxfoundation/cii-best-practices-badge>,
log in to your account (or create one), and click on the "Fork" button on the
top right.  On In the right sidebar of your new fork's repository page,
click on the "to clipboard" symbol to copy the clone URL for your fork.

Now go back to your system, type <tt>git clone</tt>, a space, paste the clone
URL for your fork, and press <kbd>Enter</kbd> to download the fork.
Once it's done, change into the newly-created directory:

~~~~sh
cd cii-best-practices-badge
~~~~

Now add an "upstream" remote so that you can easily track the master version:

~~~~sh
git remote add upstream https://github.com/linuxfoundation/cii-best-practices-badge
~~~~

<!-- If you have edit rights, do this instead:
git clone <https://github.com/linuxfoundation/cii-best-practices-badge.git>
cd cii-best-practices-badge
-->

## Installing the development environment

We provide a simple shell script that should install all the necessary
tools and libraries.
So at the command line just run:

~~~~sh
./install-badge-dev-env
~~~~

If that fails, see the section later on "What does install-badge-dev-env do?"
to manually do what it's trying to do.
If it doesn't work, patches welcome.

## Running locally

Once your development environment is ready, you can run the application with:

~~~~
rails s
~~~~

This will automatically set up what it needs to, and then run the
web application.  You can press control-C at any time to stop it.
Then point your web browser at "localhost:3000".


## Contributing in general

See [CONTRIBUTING.md](../CONTRIBUTING.md) for information on how to contribute
changes.

## Deployment instructions

This is designed to be easily deployed simply by doing a "git push"
to an appropriate destination.

At this point, a deployment is automatically done to a staging system once
it's checked into the repository on the master branch.


## See also

See the separate "[background](./background.md)" and "[criteria](./criteria.md)"
pages for more information.


## What does install-badge-dev-env do?

The install-badge-dev-env script tries to install all (missing) tools and
libraries.  You can re-run it again if something got corrupted.


### Installing system tools

First, it tries to automatically detect your system package management tool
(e.g., apt-get, yum, dnf, or brew),
and then tries to install some key tools if they're not already there:

* git, to get some of the programs we use.
Installing git will also install some libraries such as
curl, zlib, openssl, expat, and libiconv.
* Ruby (version 1.9.3 or newer), to bootstrap installing the Ruby we'll use
* SQLite3 database system, used in development for data storage
* C compiler and basic libraries for rebuilding ruby.
Install a sane C compiler such as gcc or clang.
See the [ruby-build suggested build environment](https://github.com/sstephenson/ruby-build/wiki#suggested-build-environment)
for how to do install the other required components.
The script installs gcc.

You also need to install [rbenv](https://github.com/sstephenson/rbenv)
to follow the instructions given here.  See the
[rbenv basic github checkout](https://github.com/sstephenson/rbenv#basic-github-checkout)
instructions for one approach for installing rbenv.
The rbenv tool lets you select a specific version of Ruby, and from there,
select specific versions of other libraries.
An alternative way to select specific versions is to use rvm,
but that approach is not documented here.


### Installing the project environment

For development we fix the version of Ruby at the version specified in `.ruby-version`. Please check that file and use that version in the steps below.
We also need to install a number of gems (including the ones in Rails);
we will install the versions specified in Gemfile.lock.
We will do completely separate per-project Gem installs,
to prevent potential interference issues in the development environment.
Here's a way to do that.
We presume that your current directory is the top directory of the project,
aka cii-best-practices-badge.

~~~~
# Force install Ruby 2.3.1 using rbenv:
rbenv install 2.3.1
rbenv local 2.3.1 # In this directory AND BELOW, use Ruby 2.3.1 instead.

# This makes "bundle ..." use rbenv's version of Ruby:
git clone git://github.com/carsomyr/rbenv-bundler.git ~/.rbenv/plugins/bundler

gem sources --add https://rubygems.org  # Ensure you're getting gems here
gem install bundler  # Install the "bundler" gem package manager.
rbenv rehash
bundle install       # Install gems we use in Gemfile.lock, including Rails
rake db:setup        # Setup database and seed it with dummy data
~~~~

### Consequences of our install approach

Some documents about Rails will tell you to execute "bin/rake" instead of
"rake" or to use "bundle exec ..." to execute programs.
Using rbenv-bundler (above) eliminates the need for that.
While "bundle exec..." or "bin/..." are widely used, they are also
extremely error-prone user interfaces; if you forget the prefixes,
then it can *appear* to work yet subtly do the wrong thing.
Using rbev-bundler means that the *easy* way is the *correct* way.
A vitally important way to prevent defects is to make the *easy* way
the *correct* way.

You can use "bundle outdated" to show the gems that are outdated;
be sure to test after updating any gems.
