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
However, we need to review external contributions to maintain quality.

### Technical Steering Committee (TSC)

This project is led by the OpenSSF Best Practices Badge
Technical Steering Committee (TSC).
For current members, see [TSC.md](./TSC.md).

TSC decisions are by majority vote.
Decisions can be asynchronous/electronic (e.g., a mailing list or
electronic voting system) or synchronous/meeting (e.g., in an
in-person meeting or a teleconference),
at the choice of the TSC members.
A synchronous meeting requires a quorum of a majority of TSC members.
In case of a tie, the OpenSSF Best Practices Badge
technical lead can break the tie.

This TSC reports to the OpenSSF Best Practices Working Group, who in
turn report to the OpenSSF Technical Advisory Council (TAC).

The TSC can add or remove members to itself (again, by majority vote).

The OpenSSF TAC can add or remove members in the OpenSSF Best
Practices Badge TSC by TAC majority vote. This is not intended to
be a common practice, but this mechanism prevents the TSC from being
overly insular.

TSC members represent themselves, not their employers.
We note TSC employers because we want to ensure that no single organization
controls this project.

## TSC Powers

The TSC may (1) establish work flow procedures for the submission,
approval, and closure/archiving of projects, (2) set requirements
for the promotion of Contributors to Committer status, as applicable,
and (3) amend, adjust, refine and/or eliminate the roles of
Contributors, and Committers, and create new roles, and publicly
document any TSC roles, as it sees fit.

The TSC may elect a TSC Chair, who will preside over meetings of
the TSC and will serve until their resignation or replacement by
the TSC.  The TSC Chair, or any other TSC member so designated by
the TSC, will serve as the primary communication contact between
the Project and OpenSSF, a directed fund of The Linux Foundation.

The TSC will be responsible for all aspects of oversight relating
to the Project, which may include:

1. coordinating the technical direction of the Project; approving
   project or system proposals (including, but not limited to, incubation,
2. deprecation, and changes to a sub-project’s scope);
3. organizing sub-projects and removing sub-projects;
4. creating sub-committees or working groups to focus on cross-project
   technical issues and requirements;
5. appointing representatives to work with other open source or
   open standards communities;
6. establishing community norms, workflows, issuing releases,
   and security issue reporting policies;
7. approving and implementing policies and processes for contributing
   and coordinating with
   the series manager of the Project (as provided for in the Series
   Agreement, the “Series Manager”) to resolve matters or concerns
   that may arise;
8. discussions, seeking consensus, and where necessary, voting on
   technical matters relating to the code base that affect multiple
   projects; and
   coordinating any marketing, events, or communications regarding the Project.

In practice, the TSC delegates many tasks to the technical lead, who
serves the TSC.

## TSC Voting

1. While the Project aims to operate as a consensus-based community,
   if any TSC decision requires a vote to move the Project forward,
   the voting members of the TSC will vote on a one vote per voting
   member basis.
2. Quorum for TSC meetings requires at least fifty percent of all
   voting members of the TSC to be present. The TSC may continue to
   meet if quorum is not met but will be prevented from making any
   decisions at the meeting.
3. Except as provided in Technical Charter Section 7.c. and 8.a, decisions
   by vote at a meeting require a majority vote of those in attendance,
   provided quorum is met. Decisions made by electronic vote without
   a meeting require a majority vote of all voting members of the TSC.
4. In the event a vote cannot be resolved by the TSC, any voting
   member of the TSC may refer the matter to the Series Manager for
   assistance in reaching a resolution.
   They may also contact the OpenSSF Best Practices WG.

Technical Charter sections 7.c and 8.a identify the licensing requirements,
e.g., MIT license for the source code.

## Technical Lead

Many of the day-to-day maintenance tasks of the OpenSSF Best Practices Badge
are managed by the OpenSSF Best Practices Badge technical lead.

The technical lead reports to the OpenSSF TSC, including on significant
work or decisions to be made.
The technical lead's decisions can be
overruled by the OpenSSF TSC at any time.
In addition, the OpenSSF TSC can replace the technical lead at any time
(as always, by majority vote).

Also, since the project is FLOSS, the project can be forked;
this ability to fork also provides a check against despotism.
The technical lead's job is focus on doing what's best
for this project, and the project's goal is to help
the FLOSS community overall.

The technical lead has commit rights on the software, and administrative
rights to the production site, and can add or remove those rights to others
to further the goals of the project
(subject to being overruled by the TSC).
Those with commit rights can make changes
(subject to caveats described below) and accept changes
(typically pull requests) submitted by others.
These changes include changes to the process and contribution requirements.

## Committers

Committers are those with authority to directly make changes
to the main branch of the code.
The TSC and technical lead can add or revoke commit privilege
(the TSC overrides the technical lead in case of a conflict).
Committers can accept contributions from contributors.

## Contributors

Contributors are those who choose to contribute to the project.
See [CONTRIBUTING](../CONTRIBUTING.md).

## Process

We generally use the GitHub issue tracker and pull requests for managing
changes.
For details, including contribution requirements, see
[CONTRIBUTING.md](../CONTRIBUTING.md).
Note that we emphasize two-person review for anything other than
low-risk contributions.

This project requires two-factor authentication (2FA) for direct commit rights.
In addition, this project does not accept SMS as the second factor.

Issues that we have determined are especially important, particularly
if they will take a while, are added to the "next" milestone
(which identifies "what should be prioritized next").

We expect people to focus on improving the project, not attacking other
people. Please strive to "Be excellent to each other."
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

To see the current list of TSC members, see [TSC.md](./TSC.md).

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
