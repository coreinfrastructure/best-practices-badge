We have some built-in automation analysis mechanisms
(implemented by a Chief and various detectives),
as well as support for externally-provided anlysis.
These automations are used while editing a project entry.

Here are the intended automation rules:

1. Invariant: The user is *always* shown highlighted
   automation results whenever project data is changed, so that the
   user always stays informed.
   This is highlighted as an automation change or an override.
   If it's not overridden, the user is always in control.
2. On initial edit of a section (`SECTION_saved` is false) the automation
   runs (via the chief),
   changes any current '?' or forced value to its automation-determined
   value, and marks them for display on the updating edit form.
   If the section is ever later saved its `SECTION_saved` will be saved as true.
   (If they never save that session, it'll just re-run automation that time.)
   If there's an override from the chief on this *initial* run,
   mark it as an overridden value (not merely automation), so users will
   be aware even on entry that changing this will require a change to the repo.
   We only run automation on entry to the *initial* edit, because our
   automation can take a while or encounter problems (like API limits).
   We don't want to delay users from running a quick edit after the first time,
   where the initial delay from filling things in is worth it.
3. On any start of a section edit (starting the `edit` method),
   *after* any initial edit of a section automation (if that happens),
   the `edit` method will consume the query string as
   proposed automation edits, set those, and show them as automation changes.
   This must happen *even* when the `SECTION_saved` value is true.
   Note that these can override the initial automation result.
   This provides support for easy *external* automation.
   They'll be marked as automation changes, but any later call of the chief
   won't really distinguish between these values and user-entered values,
   they're just values being proposed for saving.
   The query string will *not* propogate past a "save and continue" nor a
   "save and exit".
4. After any save of any kind, the system runs the chief once,
   but the processing is different depending on the kind of saving.
5. After a "save and continue", it does the same thing as an initial
   section edit: the automation runs, and
   changes any current '?' or forced value to its value,
   and marks them for display on the updating edit form.
6. After a "save and exit", it runs the chief but *only* applies overrides.
   If overrides change a current value, it'll save *those* values instead,
   and bring back a user edit form showing those values were overridden
  (so the user is informed).
7. If there's a crash in the chief run, we'll save everything except that
   which can be overridden.

In the built-in automations, justifications for a criterion are only
changed if the corresponding status is changed, and which point the
justification overwrites (not appends) the old justification.

External automation proposals can propose a change to just a justification
or just a status.

In the edit display, an change to *either* the criterion status *or*
justification from *either* the built-in or external automation
will cause it to be highlighted for review (either as an automation change,
or if it's an override, as an override).
