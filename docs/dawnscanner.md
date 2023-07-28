# Dawnscanner

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

We have experimented with the
[dawnscanner](https://github.com/thesp0nge/dawnscanner/)
(aka "dawn") tool.
This tool performs static analysis of the Gemfile* files and Ruby code,
looking for known vulnerable components (something bundle-audit already
does) and for code patterns suggesting vulnerabilities.

Dawnscanner is not a bad tool. However, it adds a huge number of
dependencies to our development environment (if added to the Gemfile),
and it has a number of unfixed bugs that produce false positives.
Neither point prevents its use; in particular, it could be installed
as an independent continuous integration tool to prevent it from
affecting the development environment.
However, our existing tools such as bundle-audit, brakeman,
secureheaders, and our session timeout code
seem to cover basically the same ground.
It also doesn't find any new problems in our program (at least currently).
We tend to prefer using multiple tools (in case one misses something),
but in this case we think we have reached the point of diminishing returns.

We may, in the future, add dawnscanner to our set of tools, particularly
if the bugs are repaired and there is an easy way to disable just the false
positives (without disabling anything else).

On 2016-03-17 we ran dawnscanner version 1.6.2.
Dawnscanner reported 4 vulnerabilities, which were all false positives.
We document here the 4 false positives, and why they are false positives:

* CVE-2016-0751 check failed.
    - "There is a possible object leak which can lead to a denial of service vulnerability in Action Pack. A carefully crafted accept header can cause a global cache of mime types to grow indefinitely which can lead to a possible denial of service attack in Action Pack. Evidence: Vulnerable actionpack gem version found: 4.2.6".
    - This is [dawnscanner bug #196](https://github.com/thesp0nge/dawnscanner/issues/196); actionpack gem version 4.2.6 is not vulnerable, but the version number comparison fails.
* CVE-2016-2098 check failed.
    - "There is a possible remote code execution vulnerability in Action Pack. Applications that pass unverified user input to the render method in a controller or a view may be vulnerable to a code injection.  Evidence: Vulnerable actionpack gem version found: 4.2.6"
    - This is [dawnscanner bug #197](https://github.com/thesp0nge/dawnscanner/issues/197); actionpack gem version 4.2.6 is not vulnerable, but the version number comparison fails.
* Owasp Ror CheatSheet
    - "Session management check failed.  By default Ruby
      on Rails uses a Cookie based session store. What that means is that unless
      you change something the session will not expire on the server. That means
      that some default applications may be vulnerable to replay attacks. It
      also means that sensitive information should never be put in the session.
      Evidence: In your session_store.rb file you are not using ActiveRecord to
      store session data. This will let rails to use a cookie based session
      and it can expose your web application to a session replay attack.
      filename ./cii-best-practices-badge/config/initializers/session_store.rb"
    - Dawnscanner is correct that we use a cookie based store.  However,
      we counter session replay attacks in a different way: we force times
      into the session, and time out old cookies.  Since we do this by hand,
      it's unsurprising that dawnscanner doesn't notice.  So this is a very
      reasonable report by dawnscanner, we've just handled the issue in a
      different way than the dawnscanner developers expected.
* Owasp Ror CheatSheet: Security Related Headers check failed
    - "To set a header value simply access the response.headers object as
       a hash inside your controller often in a before after_filter. Rails
       4 provides the default_headers functionality that will automatically
       apply the values supplied. This works for most headers in almost
       all cases. Evidence: app/controllers/*.rb"
    - This is
      [dawnscanner bug #38](https://github.com/thesp0nge/dawnscanner/issues/38),
      which has been open since Feb 2014.
      Rails 4 by default includes security-related headers, but Dawnscanner
      does not realize that this is a Rails 4 app with the correct
      configuration.  In addition, our application also uses Twitter's
      secure_headers gem, which adds even more security-related headers.
