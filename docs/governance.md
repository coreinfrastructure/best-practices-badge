# Governance

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

This document briefly describes "how we make decisions" in the
OpenSSF Best Practices Badge Project.

## Overall

This project is a Linux Foundation (LF)
[Open Source Security Foundation (OpenSSF)](https://openssf.org/) project.
The OpenSSF is essentially the successor of the
Core Infrastructure Initiative (CII) project.

In terms of
["Governance models" (Gardler and Hanganu)](http://oss-watch.ac.uk/resources/governancemodels) the badging project is a bazaar -
contributions are gladly welcomed from anyone.
The project is led by a single technical lead designated by the OpenSSF.
The technical lead has final say on decisions (and thus is
something of a "benevolent dictator"), but the technical
lead is subject to being overruled or replaced by the OpenSSF.
Also, since the project is FLOSS, the project can be forked;
this ability to fork also provides a check against despotism.
The technical lead's job is focus on doing what's best
for this project, and the project's goal is to help
the FLOSS community overall.

The technical lead has commit rights on the software, and administrative
rights to the production site, and can add or remove those rights to others.
Those with commit rights can make changes
(subject to caveats described below) and accept changes
(typically pull requests) submitted by others.
These changes include changes to the process and contribution requirements.

## Process

We generally use the GitHub issue tracker and pull requests for managing
changes.
For details, including contribution requirements, see
[CONTRIBUTING.md](../CONTRIBUTING.md).
Note that we emphasize two-person review for anything other than
low-risk contributions.

This project requires two-factor authentication (2FA).
In addition, this project does not accept SMS as the second factor.

Issues that we have determined are especially important, particularly
if they will take a while, are added to the "next" milestone
(which identifies "what should be prioritized next").

We expect people to focus on improving the project, not attacking other
people.  Please strive to "Be excellent to each other."
For more information, see our [Code of Conduct](../CODE_OF_CONDUCT.md).

## Criteria changes

Changing *criteria* can have a much larger impact on participating
projects than simply changing the supporting software, so we have special
rules about them.  Fundamentally, any project that has honestly achieved
a badge has a right to *not* have it revoked without notice.

Criteria may be immediately changed if the change will
not change the *meaning* of the criteria, e.g.,
spelling corrections, grammar corrections, trivial reorderings,
and trivial clarifications.

Criteria may have clarifications and minor exceptions added, but there
must be an opportunity for discussion.
Our usual approach is to create an issue and mark it with
"criteria-clarification", and in most cases there should also be a notice
posted to the mailing list.

We expect that the set of criteria will need to be changed in more significant
ways over time.
However, if these changes could cause any existing badge-holders to lose
their badges, these are significant changes.
These significant changes *MUST* happen much
less often and projects *MUST* be given much more time to either (1) object
or (2) modify their project to comply *and* record that in the BadgeApp
(so that they retain their badges).
We currently expect that badge criteria will change at most 1/year,
and that projects will have at *least* 2 months' warning before the change.
In that 2-month time, the BadgeApp must provide the necessary mechanisms
(e.g., using "future" criteria) so that projects can record their new answers
and thus have ample time to prevent losing their badge.

If adding a new criteria will *not* cause any existing badge holder
to lose their badge (e.g., because it is "Met" by default),
at a *minimum*
the proposed criterion *MUST* be discussed on the mailing list *AND*
must have an issue where at *least* two weeks is allowed for discussion
and improvement before putting on the live site.
In addition, there must be a rough consensus that "speedy adding"
of this criterion is appropriate.
Speeding adding of a criterion is expected to be extremely unusual.

## Current people

The current Badge Project technical lead is David A. Wheeler.
Others with commit rights include Jason Dossett.

## See also

Project participation and interface:

* [CONTRIBUTING.md](../CONTRIBUTING.md) - How to contribute to this project
* [INSTALL.md](INSTALL.md) - How to install/quick start
* [governance.md](governance.md) - How the project is governed
* [roadmap.md](roadmap.md) - Overall direction of the project
* [background.md](background.md) - Background research
* [api](api.md) - Application Programming Interface (API), inc. data downloads

Criteria:

* [Criteria for passing badge](https://bestpractices.coreinfrastructure.org/criteria/0)
* [Criteria for all badge levels](https://bestpractices.coreinfrastructure.org/criteria)

Development processes and security:

* [requirements.md](requirements.md) - Requirements (what's it supposed to do?)
* [design.md](design.md) - Architectural design information
* [implementation.md](implementation.md) - Implementation notes
* [testing.md](testing.md) - Information on testing
* [assurance-case.md](assurance-case.md) - Why it's adequately secure (assurance case)
