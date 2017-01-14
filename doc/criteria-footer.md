## A note on good cryptographic practices

*Note*: These criteria do not always apply because some software has no
need to directly use cryptographic capabilities.
A "project security mechanism" is a security mechanism provided
by the delivered project's software.

## Non-criteria

We plan to *not* require any specific products or services.
In particular, we plan to *not* require
proprietary tools or services,
since many [free software](https://www.gnu.org/philosophy/free-sw.en.html)
developers would reject such criteria.
Therefore, we will intentionally *not* require git or GitHub.
We will also not require or forbid any particular programming language
(though for some programming languages we may be able to make
some recommendations).
This also means that as new tools and capabilities become available,
projects can quickly switch to them without failing to meet any criteria.
However, the criteria will sometimes identify
common methods or ways of doing something
(especially if they are FLOSS) since that information
can help people understand and meet the criteria.
We do plan to create an "easy on-ramp" for projects using git on GitHub,
since that is a common case.
We would welcome good patches that help provide an "easy on-ramp" for
projects on other repository platforms.

We do not plan to require active user discussion within a project.
Some highly mature projects rarely change and thus may have little activity.
We *do*, however, require that the project be responsive
if vulnerabilities are reported to the project (see above).

## Uniquely identifying a project

One challenge is uniquely identifying a project.
Our rails application gives a unique id to each new project, so
we can certainly use that id to identify projects.
However, that doesn't help people who searching for the project
and do not already know that id.

The *real* name of a project, for our purposes, is the
project "front page" URL and/or the URL for its repository.
Most projects have a human-readable name, but these names are not enough.
The same human-readable name can be used for many different projects
(including project forks), and the same project may go by many different names.
In many cases it will be useful to point to other names for the project
(e.g., the source package name in Debian, the package name in some
language-specific repository, or its name in OpenHub).

In the future we may try to check more carefully that a user can
legitimately represent a project.
For the moment, we primarily focus on checking if GitHub repositories
are involved; there are ways to do this for other situations if that
becomes important.
We expect that users will *not* be able to edit the URL in most cases,
since if they could, they might fool people into thinking they controlled
a project that they did not.
That said, creating a bogus row entry does not really help someone very
much; what matters is the id used by the project when it refers to its
badge, and the project determines that.

Thus, a badge would have its URL as its name, year range, and level/name
(once there is more than one).

We will probably implement some search mechanisms so that people can
enter common names and find projects.


## Why have criteria?

The paper [Open badges for education: what are the implications at the
intersection of open systems and badging?](http://www.researchinlearningtechnology.net/index.php/rlt/article/view/23563)
identifies three general reasons for badging systems (all are valid for this):

1. Badges as a motivator of behavior.  We hope that by identifying
   best practices, we'll encourage projects to implement those
   best practices if they do not do them already.
2. Badges as a pedagogical tool.  Some projects may not be aware
   of some of the best practices applied by others,
   or how they can be practically applied.
   The badge will help them become aware of them and ways to implement them.
3. Badges as a signifier or credential.
   Potential users want to use projects that are applying best
   practices to consistently produce good results; badges make it easy
   for projects to signify that they are following best practices,
   and make it easy for users to see which projects are doing so.

We have chosen to use self-certification, because this makes it
possible for a large number of projects (even small ones) to
participate.  There's a risk that projects may make false claims,
but we think the risk is small, and users can check the claims for themselves.


## Improving the criteria

We are hoping to get good suggestions and feedback from the public;
please contribute!

We currently plan to launch with a single badge level (once it is ready).
There may eventually be multiple levels (bronze, silver, gold) or
other badges (with a prerequisite) later.
One area we have often discussed is whether or not to require
continuous integration in this set of criteria;
if it is not, it is expected to be required at higher levels.
See [other](./other.md) for more information.

You may also want to see the "[background](./background.md)" file
for more information about these criteria,
and the "[implementation](./implementation.md)" notes
about the BadgeApp application.
