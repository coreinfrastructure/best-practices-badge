# Baseline plan

This document explains what the OpenSSF Baseline is, and how the
OpenSSF Best Practices badge project plans to add support for it
(without losing support for its existing set of criteria).

## What is baseline?

The [OpenSSF Open Source Project Security Baseline (OSPS Baseline)](https://baseline.openssf.org/), aka "baseline", is a set of requirements
for open source software projects maintained by the
OpenSSF Security Baseline SIG for improving security.
The baseline criteria different from the original "metal series" of
criteria currently supported by the OpenSSF Best Practices badge as follows:

* The "baseline" criteria focus on only having MUST criteria
  (no SHOULD or SUGGESTED criteria), are primarily derived from
  regulations and standards, and focus on being a shorter list.
* The original "metal series" of criteria in the Best Practices badge
  (passing, silver, gold) include criteria that are widely but not universally
  applicable (SHOULD and SUGGESTED), are primarily derived from
  successful secure OSS projects, and are more willing to accept more criteria
  (including those for quality as long as they also aid security).

## Why support both sets of criteria?

We don't want projects to lose their investment of time in the "metal series",
many may find its more detailed criteria valuable, and baseline is new.
Others may want to use the baseline set of criteria because of its mappings
to regulations or because it's shorter.
Some projects may want to use both - neither one obviously replaces the other.

Therefore, we plan to make some changes to support *both* sets of criteria.
A given project can use one set of criteria, or the other, or both, at
their choosing.

No set of criteria can fully capture good practices for projects, so being
able to use both lists has its advantages.

## Expected result

Currently each project has a page for each criterion set
(e.g., one each for passing, silver, and gold). The plan would be to add
more such pages (one each for baseline-1, baseline-2, and baseline-3).
The plan would be to work incrementally.
We would eventually add more automation, including automation to reuse
any existing data.

## Resource URLs

URLs for the production site always begin with
`https://www.bestpractices.dev`.
In "normal" URLs this is followed by `/{LOCALE}`, and if
the locale is omitted, it's automatically redirected
as set in the user's browser settings.
There are a few locale-independent URLs; in those cases the locale must
be omitted.

A URL `criteria_level` will no longer be `0` (passing), `1` (silver), or `2`
(gold), as that will be confusing. The value values will be
`passing`, `silver`, `gold`, `baseline-1`, `baseline-2`, `baseline-3`,
and `permissions`. The last one isn't really a criteria level, but a way
for users to enter changes to permissions on the project
(these are currently handled when editing passing, and we want baseline
users to have the same access).

Given that, we'll have support for:

* `/projects/{id}`: Temporary redirect to the "preferred" criteria level.
* `/projects/{id}/{criteria_level}`:
   Show the form for that criteria level (append `/edit` to edit them).
* `/projects/{id}.{format}`: Show data for project in that format
  (.json, .md).
* `/projects/{id}/badge`: Show the small badge image for the metal series.
   This is locale-independent, to maximize caching.
* `/projects/{id}/baseline`: Show the small badge image for the baseline series
   This is locale-independent, to maximize caching.

## High-level implementation plan

The plan is to do some reorganizing to make it easier to add support
for baseline, then implement baseline.

1. Change URL `criteria_level` so 0,1,2 get permanently redirected
   to passing, silver, gold, and support those new names.
   Ensure that there's only 1 canonical name for data, to reduce spider load.
   Move the permissions changes to a new form `permissions`, so that
   people don't need to view/edit "passing" to see/edit permissions.
2. Add support for `baseline-1` criteria level and at least stub views
   for two baseline-1 criteria, along with their database support.
3. Add full support for `baseline-1` criteria level
   so it can be manually viewed and edited.  Test.
4. Add support for `/baseline` small badge image.
5. Add full support data entry of `baseline-2` and `baseline-3`.
6. Add basic automation, at least build on existing automation
   (in the longer term we want to use more tools and automation).
7. Discuss with natural language translators. This is a lot of translation work.
   Currently the plan is to add mechanism so automated translations
   are used (using existing translations as templates)
   but *only* when there isn't a human translation. Human translation
   will always be better, but showing English isn't great for those
   who don't speak English.
