# Security

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

Security is important and challenging.
This document describes why we think this software (the "BadgeApp")
is adequately secure (i.e., its "assurance case").

Our overall security approach is called
defense-in-breadth, that is, we consider
security (including security countermeasures) in all
our software development processes (including
requirements, design, implementation, verification, and reuse from
external suppliers).
In each software development process we
identify the specific issues that most need to be addressed,
and then address them.

Below are the overall security requirements, followed by how we approach
security in design, implementation,
verification, supply chain (reuse), development environment,
and deployment/operations.

Sadly, perfection is rare; we really want your help.
If you find a vulnerability, please see
[CONTRIBUTING.md](../CONTRIBUTING.md) for how to submit a vulnerability report.
For more technical information on the implementation, see
[implementation.md](implementation.md).

## Security Requirements

Here is what BadgeApp must do to be secure (and a few comments about
how we implement these requirements):

- Confidentiality:
  Project data is considered public, as is
  the users who own the records, so we don't need to keep those confidential.
  The only things we need to keep confidential, really, are
  passwords and user email addresses.  We handle specially, since
  we must not reveal any plaintext passwords used to authenticate users.
  Password proteciton is primarily handled by only centrally storing passwords
  once they are encrypted by bcrypt (so passwords are *only* stored as
  iterated salted cryptographic hashes).
  Passwords may also be stored in encrypted user cookies, but the
  decrypted passwords are not stored on the server's database,
  and users can choose whether or not to store passwords in encrypted cookies
  (using the "remember me" box implemented in commit e79decec67).
  We do store email addresses; we need those for various purposes
  (e.g., contact badge entry owners for clarification).
  We will strive to not reveal user email addresses to others
  (with the exception administrators, who can see them).
  Communications between users and the application must use an encrypted
  (HTTPS) channel.
  There's no need to worry about covert channels.
- Integrity:
    - Data between the client and server must not be altered.
      We use https in the deployed system.
    - Only authorized people should be able to edit the record
      of a given project.  If a project is on GitHub this is easy -
      we can ask people to
      log in, and prove that they can edit that project.
      For other projects, what we can do is ensure that once a project
      record is created, only its creator can edit it... and then projects
      can decide which (if any) to link to as their "official" representation.
    - Only authorized people should be able to edit the BadgeApp source code.
      We use GitHub for managing the source code and issue tracker; it
      has an authentication system for this purpose.
- Availability: We cannot prevent someone with significant
  resources from overwhelming the system.  (This includes DDoS attacks,
  since someone who controls many clients controls a lot of resources.)
  Instead, we will work so that it can return to operation
  once an attack has ended and/or been halted.
  We will also design the system so it can scale up
  (e.g., using multiple processes and a CDNs), to make it harder for
  someone without significant resources to shut it down.
  See the design section below about how we handle scaling up.

BadgeApp must avoid being taken over by other applications, and
must avoid being a conduit for others' attacks
(e.g., not be vulnerable to cross-site scripting).
We do this by focusing on having a secure design and countering the
most common kinds of attacks (as described below).

The application must not have any behaviors or features designed
to allow authorized access, exposure of sensitive information, or allow
bypass of security features or restrictions.
In particular, it must not have backdoors that allow unauthorized control.
We search for this, and since it is open source software, others can
verify that the custom code does not include these problems.

It is difficult to implement truly secure software.
An additional problem for BadgeApp is that it not only must accept,
store, and retrieve data from untrusted users... it must also go out
to untrusted websites with untrusted contents,
using URLs provided by untrusted users,
to gather data about those projects (so it can automatically fill in data).
We have taken a number of steps to reduce the likelihood
of vulnerabilities, and to reduce the impact of vulnerabilities
where they exist.
In particular, retrieval of external information is subject to a timeout,
we use Ruby (a memory-safe language),
and exceptions halt automated processing for that entry (which merely
disables automated data gathering for that entry).

We have a mechanism for downloading (and backing up) the database of projects.
That way, if the project data is corrupted, we can restore the database to
a previous state.

The permissions system is intentionally simple.
Every user has an account, either a 'local' account or an external
system account (currently we support GitHub as an external account).
Anyone can create an account.
A user with role='admin' is an administator;
few users are administrators.
A user can create as many project entries as desired.
Each project entry gets a new unique project id and is
owned by the user who created the project entry.
A project entry can only be edited (and deleted) by the entry creator,
an administrator, or by others who can prove that they
can edit that GitHub repository (if it is on GitHub).
Anyone can see the project entry results once they are saved.
We do require, in the case of a GitHub project entry, that the
entry creator be logged in via GitHub *and* be someone who can edit that
project.
Anyone can create a project entry about a project not on GitHub,
however, nothing makes the project refer to that data...
which makes entering nonsense data have much less value.
We may in the future add support for groups (e.g., where the owner
can designate other users who can edit that entry) and
a way to 'validate' project entries for projects not on GitHub.

## Security in Design

We emphasize security in design by using a simple design,
applying secure design principles,
limiting memory-unsafe language use, and
increasing availability through scaleability.

### Simple design

This web application has a simple design.
It is a standard Ruby on Rails design with models, views, and controllers.
In production it is accessed via a web server (Puma) and
builds on a relational database database system (PostgreSQL).
The software is multi-process and is intended to be multi-threaded
(see the [CONTRIBUTING.md](../CONTRIBUTING.md) file for more about this).
The database system itself is trusted, and the database managed
by the database system is not directly accessible by untrusted users.
The application runs on Linux kernel and uses some standard operating system
facilities and libraries (e.g., to provide TLS).
All interaction between the users and the web application go over
an encrypted channel using TLS.
There is some Javascript served to the client,
but no security decisions depend on code that runs on the client.

From a user's point of view,
users potentially create an id, then log in and enter data
about projects (as new or updated data).
Users can log in using a local account or by using their GitHub account.
Non-admin users are not trusted.
The entry of project data (and potentially periodically) triggers
an evaluation of data about the project, which automatically fills in
data about the project.
Projects that meet certain criteria earn a badge, which is displayed
by requesting a specific URL.
A "Chief" class and "Detective" classes attempt to get data about a project
and analyze that data; this project data is also untrusted
(in particular, filenames, file contents, issue tracker information and
contents, etc., are all untrusted).

### Secure design principles

Here are a number of secure design principles,
including the 8 principles from
[Saltzer and Schroeder](http://web.mit.edu/Saltzer/www/publications/protection/),
showing that we apply many secure design principles including
all of the ones from Saltzer and Schroeder:

- Economy of mechanism (keep the design as simple and small as practical,
  e.g., by adopting sweeping simplifications):
  The custom code has been kept as small as possible, in particular, we've
  tried to keep it DRY (don't repeat yourself).
- Fail-safe defaults (access decisions should deny by default):
  Access decisions are deny by default.
- Complete mediation (every access that might be limited must be
  checked for authority and be non-bypassable):
  Every access that might be limited is checked for authority and
  non-bypassable.  Security checks are in the controllers, not the router,
  because multiple routes can lead to the same controller
  (this is per Rails security guidelines).
  When entering data, Javascript code on the client shows whether or not
  the badge has been achieved, but the client-side code is *not* the
  final authority (it's merely a convenience).  The final arbiter of
  badge acceptance is server-side code, which is not bypassable.
- Open design (security mechanisms should not depend on attacker
  ignorance of its design, but instead on more easily protected and
  changed information like keys and passwords):
  The entire program is open source software and subject to inspection.
  Keys are kept in separate files not included in the public repository.
- Separation of privilege (multi-factor authentication,
  such as requiring both a password and a hardware token,
  is stronger than single-factor authentication):
  We don't use multi-factor authentication because the risks from compromise
  are smaller compared to many other systems
  (it's almost entirely public data, and failures generally can be recovered
  through backups).
- Least privilege (processes should operate with the
  least privilege necesssary): The application runs as a normal user,
  not a privileged user like "root".  It must have read/write access to
  its database, so it has that privilege.
- Least common mechanism (the design should minimize the mechanisms
  common to more than one user and depended on by all users,
  e.g., directories for temporary files):
  No shared temporary directory is used.  Each time a new request is made,
  new objects are instantiated; this makes the program generally thread-safe
  as well as minimizing mechanisms common to more than one user.
  The database is shared, but each table row has access control implemented
  which limits sharing to those authorized to share.
- Psychological acceptability
  (the human interface must be designed for ease of use,
  designing for "least astonishment" can help):
  The application presents a simple login and "fill in the form"
  interface, so it should be acceptable.
- Limited attack surface (the attack surface, the set of the different
  points where an attacker can try to enter or extract data, should be limited):
  The application has a limited attack surface.
  As with all Ruby on Rails applications, all access must go through the
  router to the controllers; the controllers then check for access permission.
  There are few routes, and few controller methods are publicly accessible.
  The underlying database is configured to *not* be publicly accessible.
  Many of the operations use numeric ids (e.g., which project), which are
  simply numbers (limiting the opportunity for attack because numbers are
  trivial to validate).
- Input validation with whitelists
  (inputs should typically be checked to determine if they are valid
  before they are accepted; this validation should use whitelists
  (which only accept known-good values),
  not blacklists (which attempt to list known-bad values)):
  In data provided directly to the web application,
  input validation is done with whitelists through controllers and models.
  Parameters are first checked in the controllers using the Ruby on Rails
  "strong parameter" mechanism, which ensures that only a whitelisted set
  of parameters are accepted at all.
  Once the parameters are accepted, Ruby on Rails'
  [active record validations](http://guides.rubyonrails.org/active_record_validations.html)
  are used.
  All project parameters are checked by the model, in particular,
  status values (the key values used for badges) are checked against
  a whitelist of values allowed for that criterion.
  There are a number of freetext fields
  (name, license, and the justifications);
  each have a maximum length to limit some abuses.
  These checks for maximum length do not by themselves counter certain attacks;
  see the text on security in implementation for the discussion on
  how the application counters SQL injection, XSS, and CSRF attacks.
  URLs are also limited by length and a whitelisted regex, which counters
  some kinds of attacks.
  When project data (new or edited) is provided, all proposed status values
  are checked to ensure they are one of the legal criteria values for
  that criterion.
  Once project data is received, the application tries to get some
  values from the project itself; this data may be malevolent, but the
  application is just looking for the presence or absence of certain
  data patterns, and never executes data from the project.

### Memory-safe languages

All of the custom code is written in memory-safe languages
(Ruby and Javascript), so the vulnerabilities of memory-unsafe
languages (such as C and C++) cannot occur in the custom code.
This also applies to most of the code in the directly depended libraries.
Some lower-level components (e.g., the operating system kernel,
database management system, encryption library, and some of the Ruby gems)
do have C/C++, but these are widely used components where we have
good reason to believe that developers are directly working to mitigate
the problems from memory-unsafe languages.
See the section below on supply chain (reuse) for more.

### Availability through scaleability

Availability is, as always, especially challenging.
Our primary approach is to ensure that the design scales.

As a Ruby on Rails application, it is designed so each request can
be processed separately on separate processes.
We use the 'puma' web server to serve multiple processes
(so at least attackers have to cause multiple requests simultaneously),
and timeouts so recovery is automatic after a request.
The system is designed to be easily scalable (just add more worker
processes), so we can quickly purchase additional computing resources
to handle requests if needed.

The system is currently deployed to Heroku, which imposes a hard
time limit for each request; thus, if a request gets stuck
(say during autofill by a malevolent actor who responds slowly),
eventually the timeout will cause the response to stop and the
system will become ready for another request.

We use a CDN (Fastly) to provide cached values of badges.
These are the most resource-intense kind of request.
As long as the CDN is up, even if the application crashes the
then-current data will stay available until the system recovers.

A determined attacker with significant resources could disable the
system through a distributed denial-of-service (DDoS) attack.
However, this site doesn't have any particular political agenda,
and taking it down is unlikely to provide monitary gain.
Thus, this site doesn't seem as likely a target for a long-term DDoS
attack, and there is not much else we can do to counter DDoS
by an attacker with signficant resources.

## Security in Implementation

To reduce the risk of security vulnerabilities in implementation we
have focused on countering the
[OWASP Top 10 (2013)](https://www.owasp.org/index.php/Top_10_2013-Top_10),
apply the
[Ruby on Rails Security Guide](http://guides.rubyonrails.org/security.html)
to configure the software correctly,
and we have also taken steps to harden the application.
Below is how we've done each, in turn.

### Countering OWASP top 10

The
[OWASP Top 10 (2013)](https://www.owasp.org/index.php/Top_10_2013-Top_10)
([details](https://www.owasp.org/index.php/Category:OWASP_Top_Ten_Project))
represents "a broad consensus about what the most
critical web application security flaws are."
We concentrate on countering them; by focusing on them,
we address all of the most critical and common flaws.
Here are the OWASP top 10
and how we attempt to reduce their risks in BadgeApp.

1. Injection.
   BadgeApp is implemented in Ruby on Rails, which has
   built-in protection against SQL injection.  SQL commands are not used
   directly, instead Rails includes Active Record, which implements an
   Object Relational Mapping (ORM) with parameterized commands.
   SQL commands are never used directly by the custom code.
   The shell is not used to download or process file contents (e.g., from
   repositories), instead, various Ruby APIs acquire and process it directly.
2. Broken Authentication and Session Management.
   Sessions are created and destroyed through a common
   Rails mechanism, including an encrypted and signed cookie session key.
3. Cross-Site Scripting (XSS).
   We use Rails' built-in XSS
   countermeasures, in particular, its "safe" HTML mechanisms.  By default,
   Rails always applies HTML escapes on strings displayed through views
   unless they are marked as safe.
   This greatly reduces the risk of mistakes leading to XSS vulnerabilities.
   In addition, we use a restrictive Content Security Policy (CSP),
   which makes damage more difficult even if an attacker gets something in.
4. Insecure Direct Object References.
   The only supported direct object references are for publicly available
   objects (stylesheets, etc.).
   All other requests go through routers and controllers,
   which determine what may be accessed.
5. Security Misconfiguration.
   We have strived to enable secure defaults from the start.
   We use a number of external scanning programs to detect common
   HTTPS misconfiguration problems (see below).
   In addition, we use brakeman, which can detect
   some misconfigurations in Rails applications.
   This is invoked by the default 'rake' task.
   In addition, our continuous integrattion task reruns brakeman.
6. Sensitive Data Exposure.
   We generally do not store sensitive data; the data about projects
   is intended to be public.  The only sensitive data we centrally store are
   local passwords, and those are encrypted and hashed with bcrypt
   (this is a well-known iterated salted hash algorithm).
   We use HTTPS to establish an encrypted link between the server and users.
7. Missing Function Level Access Control.
   The system depends on server-side routers and controllers for
   access control.  There is some client-side Javascript, but no
   access control depends on it.
8. Cross-Site Request Forgery (CSRF).
   We use the built-in Rails CSRF countermeasure, where csrf tokens
   are included in replies and checked on POST inputs.
   Our restrictive Content Security Policy (CSP) helps here, too.
   For more information, see the page on
   [request forgery protection](http://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection.html).
9. Using Components with Known Vulnerabilities.
   We use bundle-audit, which compares our gem libraries to a database
   of versions with known vulnerabilities.
   The default 'rake' task invokes bundle-audit.
   This is known to work; commit fdb83380aa71352
   on 2015-11-26 updated nokogiri, in response to a bundle-audit
   report on advisory CVE-2015-1819, "Nokogiri gem contains
   several vulnerabilities in libxml2 and libxslt".
   We also use a gemnasium-based badge that warns us when there is an
   out-of-date dependency; see
   [it](https://gemnasium.com/linuxfoundation/cii-best-practices-badge)
   for more information.
   We have also optimized the component update process through
   high test coverage.  The files Gemfile and Gemfile.lock
   identify the current versions of Ruby gems (Gemfile identifies direct
   dependencies; Gemfile.lock includes all transitive dependencies and
   the exact version numbers).  We can update libraries by
   updating those files, running "bundle install", and then using "rake"
   to run various checks including a robust test suite.
10. Unvalidated Redirects and Forwards.
   Redirects and forwards are not used significantly, and they are validated.

### Ruby on Rails Security Guide

This application uses Ruby on Rails.
The Ruby on Rails developers provide a
[Ruby on Rails Security Guide](http://guides.rubyonrails.org/security.html),
which identifies what they believe are the most important areas to
check for securing such applications.
Since this is focused on the infrastructure we use, we think this is
the most important guide for us to focus on.
Here are comments on how we apply the guide, per its chapters
as of 2015-12-14:

1. *Introduction.* N/A.
2. *Sessions.*
   We use sessions, and use session cookies to store them
   because of their wide support and efficiency.
   We use the default Rails CookieStore mechanism to store sessions;
   it is both simple and much faster than alternatives.
   Rails implements an automatic authentication mechanism (using a
   secret key) to ensure that clients cannot undetectably change
   these cookies; a changed value is thrown away.
   Logged-in users have their user id stored in this authenticated cookie
   (There is also a session_id, not currently used.)
   Session data is intentionally kept small, because of the limited
   amount of data available in a cookie.
   To counteract session hijacking, we configure the production
   environment to always communicate over an enrypted channel using TLS
   (see file config/environments/production.rb which sets
   "config.force_ssl" to true).
   The design allows users to drop cookies at any time
   (at worse they may have to re-login to get another session cookie).
   Passwords may be stored in a cookie, but this is encrypted and the
   password is *not* retained on the server (it stays on the web browser).
   One complaint about Rails' traditional CookieStore is that if someone
   gets a copy of a session cookie, they can log in as that user, even
   if the cookie is years old and the user logged out.
   (e.g., because someone got a backup copied).
   Our countermeasure is to time out inactive sessions, by
   also storing a time_last_used in the session
   cookie (the UTC time the cookie was last used).
   Once the time expires, then even if someone else later gets an old
   cookie value, it cannot be used to log into the system.
3. *Cross-Site Request Forgery (CSRF).*
   We use the standard REST operations with their standard meanings
   (GET, POST, etc., with the standard Rails method workaround).
   We have a CSRF required security token implemented using
   protect_from_forgery built into the application-wide controller
   app/controllers/application_controller.rb
   (we do not use cookies.permanent or similar, a contra-indicator).
4. *Redirection and Files.*
   The application uses relatively few redirects; those that do involve
   the "id", which only works if it can find the value corresponding to
   the id first (which is a whitelist).
   File uploads aren't directly supported; the application does
   temporarily load some files (as part of autofill), but those filenames
   and contents are not directly made available to any other user
   (indeed, they're thrown away once autofill completes; caching may
   keep them, but that simply allows re-reading of data already acquired).
   The files aren't put into a filesystem, so there's no
   opportunity for executable code to be put into the filesystem this way.
   There is no arbitrary file downloading capability, and private files
   (e.g., with keys) are not in the docroot.
5. *Intranet and Admin Security.*
   Some users have 'admin' privileges, but these additional privileges
   simply let them edit other project records.
   Any other direct access requires logging in to the production system
   through a separate log in (e.g., to use 'rails console').
   Indirect access (e.g., to update the code the site runs)
   requires separately logging into
   GitHub and performing a valid git push (this must also pass through the
   continuous integration test suite).
   It's possible to directly push to the Heroku sites to deploy software,
   but this requires the credentials for directly logging into the
   relevant tier (e.g., production), and only authorized system administrators
   have those credentials.
6. *User management.*
   Local passwords have a minimum length, and we expect users to
   protect their own passwords; we do not try to protect users from themselves.
   The system is not fast enough for a naive password-guesser to succeed
   guessing local passwords via network access (unless the password
   is really bad).
   The forgotten-password system for local accounts
   uses email; that has its weaknesses,
   but the data is sufficiently low value, and there aren't
   good alternatives for low value data like this.
   If users don't like that, they can log in via GitHub and use GitHub's
   forgotten password system.
   The file config/initializers/filter_parameter_logging.rb
   intentionally filters passwords so that they are not included in the log.
   We require that local user passwords have a minimum length
   (see the User model), and this is validated by the server
   (in some cases the minimum length is also checked by the web client,
   but this is not depended on).
   Ruby's regular expression (regex) language oddly interprets "^" and "$",
   which can lead to defects (you're supposed to use \A and \Z instead).
   However, Ruby's format validator and the "brakeman" tool both detect
   this common mistake with regexes, so this should be unlikely.
   Since the project data is public, manipulating the 'id' cannot reveal
   private public data.  We don't consider the list of valid users
   private either, so again, manipulating 'id' cannot reveal anything private.
7. *Injection.*
   We use whitelists to validate project data entered into the system.
   When acquiring data from projects during autofill, we do only for the
   presence or absence of patterns; the data is not stored (other than caching)
   and the data is not used in command interpreters (such as SQL or shell).
   SQL injection is countered by Rails' built-in database query mechanisms,
   we primarily use specialized routines like find() that counter
   SQL injection, but parameterized queries are also allowed
   (and also counter SQL injection).
   XSS, CSS injection, and Ajax injection are
   countered using Rails' HTML sanitization
   (by default strings are escaped when generating HTML).
   The program doesn't call out ot the command line or use a routine
   that directly does so, e.g., there's no call
   to system()... so command injection won't work either.
   The software resists header injection including response splitting;
   headers are typically not dynamicaly generated, most redirections
   (using redirect_to) are to static locations, and the rest are based
   on filtered locations.
   We use a restrictive CSP setting to limit damage if all those fail.
8. *Unsafe Query Generation.*
   We use the default Rails behavior, in particular, we leave
   deep_munge at its default value (which counters a number of vulnerabilities).
9. *Default Headers.*
   We use at least the default security HTTP headers,
   which help counter some attacks.
   In many cases we harden the headers further.

### Hardening

We also use various mechanisms to harden the system against attack;
these attempt to thwart or slow attack even if the system has a vulnerability.
We use the [secure_headers](https://github.com/twitter/secureheaders) gem
(developed by Twitter) to enable
a number of HTTP headers for hardening.
This includes a Content Security Policy (CSP) header with just
"normal sources" (normal_src).

In addition, in production "config.force_ssl" is set to true.
This enables a number of hardening mechanisms in Rails, including
HTTP Strict Transport Security (HSTS),
TLS redirection, and secure cookies.
See
["Rails, Secure Cookies, HSTS and friends" by Ilija Eftimov (2015-12-14)](http://eftimov.net/rails-tls-hsts-cookies)
for more about the impact of force_ssl.

We separately configure our CDN (Fastly) to redirect HTTP to HTTPS
(this has to be done by the CDN, since it intercepts the requests first).
This means that users who use HTTP will be redirected to HTTPS, and
once there they will receive the
HTTP Strict Transport Security (HSTS) information that will tell their
web browser to always use HTTPS in the future.
If that is misconfigured or omitted for some reason, the application
will also redirect the user from HTTP to HTTPS.

We send reminder emails to projects that have not updated their
badge entry in a long time. The detailed algorithm that prioritizes projects
is in "app/models/project.rb" class method "self.projects_to_remind".
It sorts by reminder date, so we always cycle through before returning to
a previously-reminded project.  We have a hard rate limit on the number
of emails we will send out each time; this keeps us from looking like
a spammer.

## Security in Verification

When software is modified, it is reviewed by the
'rake' process, which performs a number of checks and tests.
Modifications integrated into the master branch
are further automatically checked.
See [CONTRIBUTING.md](../CONTRIBUTING.md) for more information;
the following is a brief summary of how our verification process
helps make the software more secure.

We intentionally make the code relatively short and clean to ease review.
We use rubocop (Ruby code style checker) and rails_best_practices
and work to have no warnings in the code
(typically by fixing the problem, though in some cases we will annotate
in the code that we're allowing an exception).
These style tools help us avoid more problematic constructs (in some cases
avoiding defects that might lead to vulnerabilities), and
also make the code easier to review
(by both humans and other programs).
Our style checking tools detect misleading indentation;
<a href="http://www.dwheeler.com/essays/apple-goto-fail.html#indentation">this
counters the mistake in the Apple goto fail vulnerability</a>.

The 'rake' process also uses brakeman,
a static source code analysis that focuses
on finding security issues in Ruby on Rails applications.

The software has a strong test suite, with over 90% statement coverage.
This makes it easier to update components (e.g., if a third-party component
has a publicly disclosed vulnerability).
The test suite also makes it easier to make other fixes (e.g., to harden
something) and have fairly high
confidence that the change did not break functionality.
It can also counter some vulnerabilities, e.g.,
<a href="http://www.dwheeler.com/essays/apple-goto-fail.html#coverage">Apple's
goto fail vulnerability would have been detected has they
checked statement coverage</a>.

We work to enable third-party review.
We release the custom software as Free/Libre and open source software (FLOSS),
using a well-known FLOSS license (MIT).

We have briefly experimented with using the "dawnscanner" security scanner.
We have decided to not add dawnscanner to the set of scanners that we
routinely use.
See the [dawnscanner.md](./dawnscanner.md) file for more information.

These steps cannot *guarantee* that there are no vulnerabilities,
but we think they greatly reduce the risks.

## Supply chain (reuse)

We consider the code we reuse
(e.g., libraries and frameworks) before adding them, to reduce
the risk of unintentional and intentional vulnerabilities from them.
In particular, we prefer the use of popular components (where problems
are more likely to be identified and addressed) and common FLOSS licenses.
(A FLOSS component with a rarely-used license, particularly a
GPL-incompatible one, is less likely to be reviewed by others because
in most cases fewer people will contribute to it.)
These steps reduce the risk of malicious components
(e.g., malicious gems).

We also have a process for detecting when the components we use
have known vulnerabilities (using bundle-audit)
or are out-of-date.
This check is run by the default 'rake' process, so once a vulnerability
is found in a gem we use and is added to the public database, we
are notified that we need to update it.
The list of libraries used (transitively) is managed by bundler, so
updating libraries or sets of libraries can be done quickly.
As noted earlier, our strong automated test suite makes it easy to test this
updated set, so we can rapidly update libraries, test the result, and
deploy it.

We counter man-in-the-middle (MITM) attacks when downloading gems
because the Gemfile configuration uses an HTTPS source to the
standard place for loading gems (<https://rubygems.org>).

We can't eliminate all risks, and
if we rewrote all the software (instead of reusing software)
we would risk creating vulnerabilities in own code.
See [CONTRIBUTING.md](../CONTRIBUTING.md) for more about how we
reduce the risks of reused code.

## Security of the development environment

Subversion of the development environment can easily lead to
a compromise of the resulting system.
The key developers use development environments
specifically configured to be secure.

As noted earlier, we are cautious about the components we use.
The source code is managed on GitHub;
[GitHub takes steps to keep itself secure](https://help.github.com/articles/github-security/).

The installation process, as described in the INSTALL.md file,
includes a few steps to counter some attacks.
In particular,
we use the git integrity recommendations from Eric Myhre that check all
git objects transferred from an external site into our development environment.
This sets "fsckObjects = true" for transfer (thus also for fetch and receive).

## Deployment and operations

Of course, it has to be secure as actually deployed.
We currently use Heroku for deployment; see the
[Heroku security policy](https://www.heroku.com/policy/security)
for some information on how they manage security
(including physical security and environmental safeguards).
Normal users cannot directly access the database management system (DBMS),
which on the production system is Postgres.
Anyone can create a Heroku application and run it on Heroku, however,
at that point we trust the Postgres developers and the Heroku administrators
to keep the databases separate.

Various online checkers give us a clean bill of health.
For the main bestpractices.coreinfrastructure.org site we have:

* An "A+" rating from the
  <a href="https://www.ssllabs.com/ssltest/analyze.html?d=bestpractices.coreinfrastructure.org">Qualys SSL labs check of our TLS configuration</a>.
* An "A+" rating from the
  <a href="https://securityheaders.io/?q=bestpractices.coreinfrastructure.org">securityheaders.io check of our HTTP security headers</a>.
* An all-pass report from the
  <a href="https://www.sslshopper.com/ssl-checker.html#hostname=bestpractices.coreinfrastructure.org">SSLShopper SSL checker</a>.
* An "A+" rating from the [Mozilla Observatory](https://observatory.mozilla.org/analyze.html?host=master.bestpractices.coreinfrastructure.org) (This link is actually for the master branch.)
* A 96% result from <a href="https://www.wormly.com/test_ssl/h/bestpractices.coreinfrastructure.org/i/157.52.75.7/p/443">Wormly</a>.
  The only item not passed was the "SSL Handshake Size" test; the live site
  provides 5667 bytes, and they consider values beyond 4K (with unclear
  units) to be large. This is not a security issue, at most this will
  result in a slower initial connection.  Thus, we don't plan to worry
  about the missing test.

## People

Of course, it's important to have developers who know how to develop software,
with at least someone in the group who knows how to develop secure software.

The lead software developer,
[David A. Wheeler](http://www.dwheeler.com/), is an expert in the area
of developing secure software.
He has a PhD in Information Technology, a Master's degree in Computer Science,
a certificate in Software Engineering, a certificate in
Information Systems Security, and a BS in Electronics Engineering,
all from George Mason University (GMU).
He wrote the book
[Secure Programming HOWTO](http://www.dwheeler.com/secure-programs/)
and teaches a graduate course at George Mason University (GMU) on
how to design and implement secure software.
Dr. Wheeler's doctoral dissertation,
[Fully Countering Trusting Trust through Diverse Double-Compiling](http://www.dwheeler.com/trusting-trust/),
discusses how to counter malicious compilers.

Sam Khakimov has been developing software for a number of years,
in a variety of languages.
He has a Bachelor of Business Admin in Finance and Mathematics
(CUNY Baruch College Summa Cum Laude Double Major) and a
Master of Science in Mathematics (New York University) with
additional coursework in Cyber Security.

[Dan Kohn](http://www.dankohn.com/bio.html)
received a bachelor's degree in Economics and Computer Science
from the Honors program of Swarthmore College.
He has long expertise in Ruby on Rails.

## Your help is welcome!

Security is hard; we welcome your help.
We welcome hardening in general, particularly pull requests
that actually do the work of hardening.

Please report potential vulnerabilities you find.
See [CONTRIBUTING.md](../CONTRIBUTING.md) for how to submit
a vulnerability report.

