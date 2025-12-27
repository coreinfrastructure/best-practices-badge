# Route Consolidation Plan

This document outlines a plan to consolidate and simplify the routing
structure for `/projects` GET routes in the Best Practices Badge application.

## Problem Statement

The current routing configuration for GET ... `/projects`
has significant issues:

1. **Route Proliferation**: Multiple overlapping patterns cause the router
   to repeatedly attempt pattern matching for the same request
2. **Maintenance Burden**: Obsolete section names (0, 1, 2, bronze) require
   extensive redirect handling
3. **Scattered Logic**: Format handling and validation spread across routes
   instead of centralized in controllers
4. **Performance**: Each request may traverse many route patterns before
   finding a match

The current routes were generated and stored in `,projects-routes` for
analysis, revealing these inefficiencies.

Note: the PUT, PATCH, etc., routes are simpler and not what we're focusing on.

## Goals

1. **Simplify Routing**: Reduce the number of route patterns by consolidating
   related functionality
2. **Centralize Logic**: Move format and section handling from routes to
   controllers where appropriate
3. **Maintain Compatibility**: Preserve all existing widely-used
   URLs through redirects. We're less concerned about URLs for
   markdown (.md) format, as those aren't widely known. We're less concerned
   about "edit" for obsolete section names, as those aren't normally linked to.
4. **Improve Performance**: Reduce route matching overhead
5. **Future-Proof**: Support planned features like per-project default sections

## Proposed Route Structure

### Badge Images (Unchanged)

```
GET /projects/:id/badge(.:format)
  → projects#badge
  → Constraints: format: "svg", id: /[1-9][0-9]*/
  → No locale needed (badges are locale-independent)
```

This route remains as-is since it works well.

### Project Listing (Unchanged)

```
GET (/:locale)/projects(.:format)
  → projects#index
  → Shows list of all projects
  → If :locale omitted: 302 redirect to /:detected_locale/projects
```

### New Project (Unchanged)

```
GET (/:locale)/projects/new(.:format)
  → projects#new
  → Shows form to create new project
  → If :locale omitted: 302 redirect to /:detected_locale/projects/new
```

### Delete Confirmation (Unchanged)

This is unchanged.

```
GET (/:locale)/projects/:id/delete_form(.:format)
  → projects#delete_form
  → Shows delete confirmation page
  → If :locale omitted: 302 redirect to /:detected_locale/projects/:id/delete_form
  → Kept as separate route for security (requires GET before DELETE)
```

### Edit Section

```
GET (/:locale)/projects/:id/:section/edit
  → projects#edit
  → Constraints: :section must be valid section (passing, silver, gold,
    baseline-1, baseline-2, baseline-3, permissions)
  → Does NOT accept obsolete values (0, 1, 2, bronze). We don't expect
    those URLs to be widely linked to.
  → If :locale omitted: 302 redirect to /:detected_locale/projects/:id/:section/edit
```

### View Section (HTML or Markdown)

```
GET (/:locale)/projects/:id/:section(.:format)
  → Handles both viewing and format-specific requests
  → If :locale omitted: 302 redirect to /:detected_locale/projects/:id/:section

  Behavior by :section value:

  - If :section is obsolete (bronze, 0, 1, 2):
    → 301 redirect to current name with same locale/format
    → Mapping: bronze→passing, 0→passing, 1→silver, 2→gold

  - If :section is valid (passing, silver, gold, baseline-*, permissions):
    → Behavior depends on format:
      - .html or no format: projects#show (HTML view)
      - .md: projects#show (Markdown view)
    → Controller uses respond_to to handle format
```

I suspect the controller will call some sort of method like
`show_handler` that takes the section and format, then handles it
(e.g., redirects, calls `show`, or calls `show_json`)

### View Project (Default Section)

```
GET (/:locale)/projects/:id(.:format)
  → 302 redirect to (/:locale)/projects/:id/passing(.:format)
  → Preserves format if specified
  → If :locale omitted: 302 redirect happens first to add locale,
    then redirects again to add section
  → Future: May redirect to project-specific default section instead
    of always "passing"
```

### JSON API (Locale-Independent)

```
GET /(:locale/)projects/:id.json
  → Eventually calls projects#show_json (though the implementation
    might call another method first, like "show", and then call show_json).
  → Returns complete project data as JSON
  → If locale in URL, always 301 redirect to non-locale version
    (JSON is locale-independent)
  → NO per-section JSON (doesn't make semantic sense)
  → Note: Different from HTML/Markdown which ARE locale-specific and
    depend on sections.
```

### Markdown Without Locale (Redirect Chain)

```
GET /projects/:id.md
  → 302 redirect to /:detected_locale/projects/:id.md
  → Which then 302 redirects to /:detected_locale/projects/:id/passing.md
  → Markdown IS locale-specific (unlike JSON)
  → Default section is "passing" until per-project defaults implemented
```

## Format Handling Details

### HTML (Default)

- URL: `/:locale/projects/:id/:section` or `/:locale/projects/:id/:section.html`
- Renders localized HTML view of the specified section
- Uses Rails templates with I18n

### Markdown

- URL: `/:locale/projects/:id/:section.md`
- Renders localized Markdown view of the specified section
- **Change from current**: Markdown is now per-section, not per-project
- Old project-level markdown route will be removed
- Redirect chain: `/projects/:id.md` → `/:locale/projects/:id.md` →
  `/:locale/projects/:id/passing.md`

### JSON

- URL: `/(:locale/)projects/:id.json`
- If locale provided, redirects (permanently) to non-locale version.
- Returns complete project data as JSON
- Not locale-specific (client handles localization if needed)
- No per-section JSON endpoint

### Controller Implementation

```ruby
def show
  @section = params[:section] || 'passing'

  # Handle obsolete section names with permanent redirect
  if OBSOLETE_SECTIONS[@section]
    redirect_to project_section_path(@project, OBSOLETE_SECTIONS[@section]),
                status: :moved_permanently
    return
  end

  respond_to do |format|
    format.html { render_section_html }
    format.md   { render_section_markdown }
    # We will NOT use: format.json { render_project_json }
  end
end
```

## Redirect Types and Rationale

### Permanent Redirects (301)

Used when URLs should **never** be used again:

- **Obsolete section names**: `bronze` → `passing`, `0` → `passing`,
  `1` → `silver`, `2` → `gold`

Rationale: Search engines and browsers will cache these redirects,
reducing server load for old bookmarks.

### Temporary Redirects (302)

Used when redirect target **may change** in the future:

- **Locale detection**: `/projects` → `/:detected_locale/projects`
  (user's browser language may change)
- **Default section**: `/projects/:id` → `/projects/:id/passing`
  (will become per-project configurable)
- **Markdown section**: `/projects/:id.md` → `/:locale/projects/:id/passing.md`
  (default section may become configurable)

Rationale: Prevents caching of redirects that may change based on
user preferences or future features.

## Routes Being Removed

We don't need to support `/:locale/:locale/projects/...` routes;
doubled locales make no sense. Don't support them.

These current routes will be removed (functionality replaced):

```
# Old project-level markdown (replaced by section-level markdown)
GET (/:locale)/projects/:id(.:format) → projects#show_markdown

# Old project-level edit (replaced by section-level edit)
GET (/:locale)/projects/:id/edit(.:format) → projects#edit
```

## URL Migration Examples

| Old URL | New URL | Redirect Type | Notes |
|---------|---------|---------------|-------|
| `/projects/123` | `/:locale/projects/123/passing` | 302 | Locale detected, then section added |
| `/fr/projects/123` | `/fr/projects/123/passing` | 302 | Section added (which one may become configurable) |
| `/en/projects/123/bronze` | `/en/projects/123/passing` | 301 | Obsolete section name |
| `/en/projects/123/0` | `/en/projects/123/passing` | 301 | Obsolete numeric section |
| `/en/projects/123/1` | `/en/projects/123/silver` | 301 | Obsolete numeric section |
| `/en/projects/123/2` | `/en/projects/123/gold` | 301 | Obsolete numeric section |
| `/projects/123.md` | `/:locale/projects/123/passing.md` | 302 (maybe chain) | Locale added, then section. It'd be okay to do this in a chain or all at once. |
| `/en/projects/123.md` | `/en/projects/123/passing.md` | 302 | Section added |
| `/en/projects/123.json` | `/projects/123.json` | 301 | JSON has no locale
| `/en/projects/123/edit` | `/en/projects/123/passing/edit` | 302 | Section added |
| `/en/projects/123/bronze/edit` | N/A | Error | Obsolete sections not accepted in edit URLs |

## Migration Strategy

### Phase 1: Preparation (No User Impact)

1. **Add Controller Logic**
   - Implement section validation in controller
   - Add format handling with `respond_to`
   - Create obsolete section redirect logic
   - Add comprehensive controller tests

2. **Add New Routes**
   - Deploy new consolidated routes alongside existing ones
   - New routes point to updated controller methods
   - Existing routes remain functional
   - No user-visible changes yet

3. **Test Extensively**
   - Verify all new routes work correctly
   - Test redirect chains
   - Validate format handling
   - Check locale detection

### Phase 2: Redirect Old Routes (Minimal Impact)

1. **Convert Old Routes to Redirects**
   - Update old route definitions to redirect to new canonical URLs
   - Use 301 for obsolete sections
   - Use 302 for locale/section defaults

2. **Monitor and Measure**
   - Log redirect usage to identify high-traffic patterns
   - Monitor error rates and 404s
   - Check performance metrics
   - Validate redirect chains aren't too long

3. **Update Internal Links**
   - Change all internal application links to use new URLs
   - Update documentation
   - Fix any test fixtures

### Phase 3: Deprecation (6-12 Months Later)

1. **Announce Deprecation**
   - Document old URL patterns as deprecated
   - Encourage users to update bookmarks
   - Add deprecation warnings to logs

2. **Remove Old Routes**
   - After sufficient transition period
   - Keep redirect routes for obsolete sections (bronze, 0, 1, 2)
   - Remove only truly redundant routes

3. **Cleanup**
   - Remove old controller methods if unused
   - Remove route-related technical debt
   - Update all documentation

## Testing Strategy

### Route Tests (test/controllers/routing/)

- [ ] Verify all redirect paths work correctly
- [ ] Test 301 redirects for obsolete sections
- [ ] Test 302 redirects for locale detection
- [ ] Test 302 redirects for default section
- [ ] Confirm section validation (accept valid, reject invalid)
- [ ] Test locale detection and redirection
- [ ] Validate format detection (.html, .md, .json)
- [ ] Test redirect chains (e.g., `/projects/123.md`)
- [ ] Verify JSON route has no locale
- [ ] Confirm markdown routes have locale

### Controller Tests (test/controllers/projects_controller_test.rb)

- [ ] Test section parameter handling
- [ ] Test obsolete section redirects
- [ ] Test format responses (HTML, Markdown, JSON)
- [ ] Test locale handling in views
- [ ] Verify proper rendering for each section
- [ ] Test error handling for invalid sections

### Integration Tests

- [ ] Update existing tests using old URL patterns
- [ ] Add tests for new consolidated routes
- [ ] Verify backward compatibility during transition
- [ ] Test complete user workflows with new URLs
- [ ] Verify bookmarked URLs still work (via redirects)

### System Tests (test/system/)

- [ ] Test user navigation through sections
- [ ] Verify edit workflows
- [ ] Test markdown download
- [ ] Verify JSON API access
- [ ] Test locale switching
- [ ] Verify proper redirects in browser

### Performance Tests

- [ ] Measure route matching time before/after
- [ ] Benchmark controller logic overhead
- [ ] Test redirect chain performance
- [ ] Verify CDN compatibility with new URLs

## Rollback Strategy

If critical issues arise during deployment:

1. **Keep Old Routes Available**
   - Comment out old routes in code rather than deleting
   - Can be quickly uncommented and redeployed

2. **Monitor Key Metrics**
   - 404 error rate (should not increase)
   - Response time (should improve or stay same)
   - User error reports
   - Redirect chain length

3. **Database of Changes**
   - Maintain list of all changed URLs
   - Keep redirect mappings documented
   - Easy to revert redirect logic if needed

4. **Feature Flag (Optional)**
   - Consider feature flag for new route system
   - Can toggle between old and new routes
   - Useful for gradual rollout

## Impact Analysis

### Positive Impacts

- **Performance**: Fewer route patterns to match reduces routing overhead
- **Maintainability**: Centralized logic easier to understand and modify
- **Consistency**: Clearer URL structure
- **Future-Ready**: Easier to add per-project default sections

### Potential Concerns

- **Controller Complexity**: Section validation moves from routes to controller

  Mitigation: Well-tested controller methods, clear documentation

- **Redirect Chains**: Some URLs require multiple redirects

  Mitigation: Only 2 redirects maximum, acceptable for user experience

- **Bookmark Updates**: Users may need to update bookmarks

  Mitigation: Redirects handle this automatically, no action required

### SEO Considerations

- **301 Redirects**: Search engines will update indexed URLs for obsolete sections
- **302 Redirects**: Search engines will preserve original URLs for temporary redirects
- **Canonical URLs**: New structure provides clearer canonical URLs for each section
- **Impact**: Minimal to none; redirects properly signal intent to search engines

## Future Enhancements

### Per-Project Default Section

Currently `/projects/:id` redirects to `/projects/:id/passing` for all projects.

Future implementation:

- Add `default_section` column to projects table
- Redirect to project-specific default section
- Change redirect from 302 to 307 (Temporary Redirect, preserves method)

### Section Permissions

Some sections may become restricted based on project visibility or user permissions:

- Public projects: All sections visible
- Private projects: Restrict access to certain sections
- Implement in controller, not routes

## Appendix: Current Routes

For reference, these are the current GET routes for `/projects`:

```
GET /projects/:id/badge(.:format)
  → projects#badge {format: "svg", id: /[1-9][0-9]*/}

GET (/:locale)/:locale/projects/:id/0(.:format)
  → redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/projects/:id/0(.:format)
  → redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/:locale/projects/:id/0/edit(.:format)
  → redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/projects/:id/0/edit(.:format)
  → redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/:locale/projects/:id/1(.:format)
  → redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/projects/:id/1(.:format)
  → redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/:locale/projects/:id/1/edit(.:format)
  → redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/projects/:id/1/edit(.:format)
  → redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/:locale/projects/:id/2(.:format)
  → redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/projects/:id/2(.:format)
  → redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/:locale/projects/:id/2/edit(.:format)
  → redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/projects/:id/2/edit(.:format)
  → redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/:locale/projects/:id/bronze(.:format)
  → redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/projects/:id/bronze(.:format)
  → redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/:locale/projects/:id/bronze/edit(.:format)
  → redirect(301) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/projects/:id/bronze/edit(.:format)
  → redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/:locale/projects/:id(.:format)
  → redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}

GET (/:locale)/projects/:id(.:format)
  → redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}

GET (/:locale)/:locale/projects/:id/edit(.:format)
  → redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/projects/:id/edit(.:format)
  → redirect(302) {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/, id: /[1-9][0-9]*/}

GET (/:locale)/projects/:id/delete_form(.:format)
  → projects#delete_form {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}

GET (/:locale)/projects/:id(.:format)
  → projects#show_json {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}

GET (/:locale)/projects/:id(.:format)
  → projects#show_markdown {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}

GET (/:locale)/projects/:id/:criteria_level(.:format)
  → projects#show {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/,
    criteria_level: /(?-mix:passing|silver|gold|0|1|2|baseline\-1|baseline\-2|baseline\-3|bronze|permissions)/}

GET (/:locale)/projects/:id/:criteria_level/edit(.:format)
  → projects#edit {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/,
    criteria_level: /(?-mix:passing|silver|gold|0|1|2|baseline\-1|baseline\-2|baseline\-3|bronze|permissions)/}

GET (/:locale)/projects(.:format)
  → projects#index {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}

GET (/:locale)/projects/new(.:format)
  → projects#new {locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}

GET (/:locale)/projects/:id/edit(.:format)
  → projects#edit {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}

GET (/:locale)/projects/:id(.:format)
  → projects#show {id: /[1-9][0-9]*/, locale: /(?:en|zh-CN|es|fr|de|ja|pt-BR|ru|sw)/}
```
