# Automation thoughts

The best practices badge system has long had an automation system,
where a "Chief" coordinates various "Detectives".
However, now that we have two series of badges, where users might never
see one series or the other, it's time to improve how we handle automation.

There are two purposes for automation:

1. Help the human fill in the form of a given section.
2. Counter clearly-false information by refusing to save it.

We want humans to always have a chance to review the results of automation,
in case the automation got it wrong. The current system doesn't do that,
indeed, it may modify values the user has never seen.
Nor does it make clear what it's proposed.

So I'd like to make changes to the UI and the database to better
serve these needs. In addition, the user should *ask* the system
to help fill in the form for a given section after the first time - and
be able to do that. Here is my thinking on how to do that.

First, let's add a boolean value in the database, one for each section
named `SECTION_NAME_saved` (e.g., `passing_saved`).
Its default value is false; its value becomes
"true" if the user has ever saved this section before.

When the user starts to edit a section, including the first time editing
anything in the project, the system checks
the section's corresponding `_saved` value.
If the `_saved` value is false, it runs an
automated analysis process to get initial values, and displays
something noting to the user that it's performing an analysis.
Whenever a section is saved, its corresponding `SECTION_NAME__saved`
is set to true, so this automation on edit start doesn't happen every time
the section is edited. That'll make it faster to start a new edit session.

After this automation *may* have run, the edit form is shown as it is now.
However, I want to add something new. Each of the "Met|Unmet|N/A|?" parts
that were set/changed by the automation that ran before we started
should be specially highlighted
(maybe in yellow?). That way, the user can easily see what was set
by the automation. "What was automated" is *NOT* stored in a database, since
that is ephemeral info, it's just passed in via the HTML somehow.
That way, the human can easily review the proposed changes
(as they are highlighted).
If an automation session wasn't run, naturally nothing will be highlighted.

I'd also like to change what automation can change.
From now on,
automation will ONLY change the values that are displayed by a given section,
and won't impact criteria that aren't displayed. That way, users will have
a chance to review the results of automation.
Ideally we don't even do an analysis if it can't impact the section
we are editing.

After saving, the system will always do a re-analysis, but its impact
will be different.

"Save and Continue" does a re-analysis, and make proposed changes even if
they aren't a 4 or 5. When the edit re-opens, all changes in the section
will be highlighted.
Make sure the panels that include a change are open, even if
they normally would start closed.

A "Save and exit" does a re-analysis, but only forces changes with confidence
of 4 or 5, and only criteria displayed in the section we are editing.
If we *DO* make a forced change, we'll force the change, save,
and go back to the edit screen with a flash statement explaining what was
forced and why, and highlighting the values we forced.
That way, we will force the results we believe are correct, but we'll
also notify the user exactly what we did and why.

We also want to periodically run a slow cron job that re-analyzes
badge entries and forces false claims to be correct. That way, if a
project used to meet some criteria but doesn't any more, they could
lose their badge. If they lose badge(s), the owner must be notified via email.
We might want to check a few times and *not* do it, then do it, in case
a website is temporarily down but comes back up.
