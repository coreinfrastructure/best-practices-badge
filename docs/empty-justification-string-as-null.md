# Implementing "NULL for blank string" optimization for justifications

## Background

The badge application receives a very large number of requests,
especially for "project" data. We believe this is because many organizations
are trying to train AI systems based on machine learning, and are
basically repeatedly downloading everything on the Internet to train them.

This massive number of requests leads to
a massive number of memory allocations. We need to reduce the
memory allocations when retrieving project data, and have taken
various steps to do this.

The "project" table has a large number of `t.text` fields
for criteria justification, e.g., `know_common_errors_justification`.
Their current definition permits NULL values.
In many cases the stored justification values are empty strings.

## Data Analysis (from development database)

Analysis of the development database (9,372 projects) as of 2025-12-30
revealed:

- **193 justification fields** per project
- **1,808,796 total justification cells** (193 fields × 9,372 projects)

**Current distribution:**

- **Empty strings**: 273,826 cells (15.14%)
- **NULL values**: 1,319,823 cells (72.97%)
- **Non-empty strings**: 215,147 cells (11.89%)

**Key finding**: The vast majority of justification cells (72.97%) are
already NULL, demonstrating that the application already handles NULL
values correctly throughout.

## Hypothesis - CONFIRMED ✓

**Hypothesis**: We can optimize memory usage by always storing *empty*
justification strings as NULL values.

**Confirmation**: Testing confirms that:

1. **Empty strings consume memory**: Each empty string allocates 40 bytes
   with a unique object_id
2. **nil is zero-cost**: Ruby's `nil` is a singleton (object_id: 4) that
   takes 0 more bytes to allocate
3. **Memory savings**: Converting 273,826 empty strings to NULL would save
   ~10.4 MB of direct allocations plus reduce garbage collection overhead
   if you simply loaded each project in once (as a thought experiment
   to estimate impact).
4. **Rails compatibility**: Rails often treats `nil` and `''` equivalently:
   - `nil.blank?` == `''.blank?` (both true)
   - `nil.present?` == `''.present?` (both false)
   - `nil.to_s` == `''` (both empty string)

## Implementation Approach

Since 72.97% of justifications are already NULL and the application handles
them correctly, we can take a simple, focused approach:

### Required Changes

1. **Migration**: Convert all empty string justifications to NULL
   - Update all 273,826 empty string cells to NULL
   - This is a one-time data cleanup

2. **Input normalization**: Ensure incoming empty strings become NULL
   - When receiving data updates (form submissions, API calls), convert
     empty justification strings to `nil` before saving
   - This prevents new empty string allocations from being created

### What Does NOT Need to Change

- **JSON serialization**: Can remain as-is. While `nil` will serialize as
  `null` instead of `""`, this is semantically more correct and unlikely
  to cause issues for API consumers, since this already can occur,
  and there's no semantic difference for a user.
- **HTML rendering**: Rails automatically converts `nil.to_s` to `''`,
  so forms and views will display empty strings correctly
- **Validation logic**: Already uses `.blank?` and `.present?` which
  treat `nil` and `''` identically
- **Database schema**: Already permits NULL values, no schema changes needed

### Benefits

- Reduced memory allocations. When a project is loaded, empty justifications
  will refer to nil instead of allocating a useless empty string.
  This reduces the memory use, and also reduces garbage collection pressure
  since the nil values don't need to be cleaned up later
  by the garbage collector.
- Minimal code changes required

The actual impact depends on which projects are loaded. However,
if you simply loaded each project once as they are currently, there would be
273,826 fewer objects to track and ~10.4 MB saved.
It's really the number of objects eliminated that matters.
