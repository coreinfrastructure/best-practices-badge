# Route consolidation

Let's work out a potential consolidation plan for routes.

## New plan

I generated all the routes with `/projects` in them and stored them in the
file ,projects-routes and I think the GET versions are a mess.
I think a lot of work has to occur simply to reparse the route multiple times.

This is fine:
GET       /projects/:id/badge(.:format)                                                                     projects#badge {format: "svg", id: /[1-9][0-9]*/}

However, please consider consolidating the other GET
routes involving /projects to one of these forms, where in all cases, if
:locale is omitted, it redirects temporarily to a locale depending on the
web browser (as we currently do). Note that :id must be a positive integer.

* GET (/:locale)/projects/:id/:section/edit
  where :section must be valid section (e.g., gold or baseline-1).
  We don't need to handle obsolete "edit" routes with :section values of
  "0", "1", "2", or "bronze".

* GET (/:locale)/projects/:id/:section(.:format)
  Consider using a single routine that further handles this,
  instead of having the router constantly try to re-match on many patterns.

  If :section is bronze, 0, 1, or 2, it permanently redirects to its
  current name (passing, passing, silver, gold) with the rest the same.

  If :section is "permissions" or a criteria level, it'll depend on the format:
  * md = markdown display (which then becomes only for that section)
  * html or unspecified = html display

   We end up with projects#show

* GET (/:locale)/projects/:id(.:format)

  This temporarily redirects to the "passing" section for now,
  including the "format" if it's given.
  In the future, this might redirect to a section depending on the
  specific project instead of always to "passing".

* GET (/:locale)/projects/new(.:format)

  projects#new

* GET  (/:locale)/projects(.:format)

  Calls projects#index, as it does now.

* delete_form_project GET (/:locale)/projects/:id/delete_form(.:format)

  projects#delete_form , as it does now.



Note: This means that this goes away, and markdown will be per-section:

GET       (/:locale)/projects/:id(.:format)                                                                 projects#show_markdown {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}


This also goes away, as editing will also be per-section:

edit_project GET       (/:locale)/projects/:id/edit(.:format)                                                            projects#edit


## Current routes

Here are the current routes:


                                         GET       /projects/:id/badge(.:format)                                                                     projects#badge {format: "svg", id: /[1-9][0-9]*/}
                                         GET       (/:locale)/:locale/projects/:id/0(.:format)                                                       redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/projects/:id/0(.:format)                                                               redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/:locale/projects/:id/0/edit(.:format)                                                  redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/projects/:id/0/edit(.:format)                                                          redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/:locale/projects/:id/1(.:format)                                                       redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/projects/:id/1(.:format)                                                               redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/:locale/projects/:id/1/edit(.:format)                                                  redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/projects/:id/1/edit(.:format)                                                          redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/:locale/projects/:id/2(.:format)                                                       redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/projects/:id/2(.:format)                                                               redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/:locale/projects/:id/2/edit(.:format)                                                  redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/projects/:id/2/edit(.:format)                                                          redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/:locale/projects/:id/bronze(.:format)                                                  redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/projects/:id/bronze(.:format)                                                          redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/:locale/projects/:id/bronze/edit(.:format)                                             redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/projects/:id/bronze/edit(.:format)                                                     redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/:locale/projects/:id(.:format)                                                         redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                                         GET       (/:locale)/projects/:id(.:format)                                                                 redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                                         GET       (/:locale)/:locale/projects/:id/edit(.:format)                                                    redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                                         GET       (/:locale)/projects/:id/edit(.:format)                                                            redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}
                     delete_form_project GET       (/:locale)/projects/:id/delete_form(.:format)                                                     projects#delete_form {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                                         GET       (/:locale)/projects/:id(.:format)                                                                 projects#show_json {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                                         GET       (/:locale)/projects/:id(.:format)                                                                 projects#show_markdown {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                           level_project GET       (/:locale)/projects/:id/:criteria_level(.:format)                                                 projects#show {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, criteria_level: /(?-mix:passing|silver|gold|0|1|2|baseline\-1|baseline\-2|baseline\-3|bronze|permissions)/}
                      level_edit_project GET       (/:locale)/projects/:id/:criteria_level/edit(.:format)                                            projects#edit {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, criteria_level: /(?-mix:passing|silver|gold|0|1|2|baseline\-1|baseline\-2|baseline\-3|bronze|permissions)/}
                                projects GET       (/:locale)/projects(.:format)                                                                     projects#index {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                                         POST      (/:locale)/projects(.:format)                                                                     projects#create {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                             new_project GET       (/:locale)/projects/new(.:format)                                                                 projects#new {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                            edit_project GET       (/:locale)/projects/:id/edit(.:format)                                                            projects#edit {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                                 project GET       (/:locale)/projects/:id(.:format)                                                                 projects#show {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                                         PATCH     (/:locale)/projects/:id(.:format)                                                                 projects#update {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                                         PUT       (/:locale)/projects/:id(.:format)                                                                 projects#update {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                                         DELETE    (/:locale)/projects/:id(.:format)                                                                 projects#destroy {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
                             put_project PUT|PATCH (/:locale)/projects/:id(/:criteria_level/)edit(.:format)                                          projects#update {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, criteria_level: /(?-mix:passing|silver|gold|0|1|2|baseline\-1|baseline\-2|baseline\-3|bronze|permissions)/}
