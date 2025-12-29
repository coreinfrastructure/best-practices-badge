# Converting `NAME_status` Fields to Enums for Memory Optimization

## Goal

Reduce memory object creation in the Ruby application by converting hundreds of `NAME_status` fields in the projects table to use enums.

## Analysis

### Current State

We are receiving a massive number of queries that are causing increasing memory use. Every load of a project record causes many string objects to be created.

When examing the memory use, one thing is striking:

- There are hundreds of `NAME_status` fields stored as VARCHAR/TEXT in PostgreSQL
- Each field value creates a new String object in Ruby when loaded
- With hundreds of status fields per Project record, this means hundreds of String allocations per record

All of these values should be a mapping to the same underlying data type,
if possible. That's because all status values have the same 4 possible values:

* '?' => 0 (default. We want this to be 0 because it's the default)
* 'Unmet' => 1
* 'N/A' => 2
* 'Met' => 3 (We want this to be 3, so it takes 2 bit flips to go
  from '?' to 'Met')

All status values should map to a *single* enumerated type, since they
all have the same possibilities. It would much more confusing if there
was a different mapping.

### Proposed Solution: Rails Enums with Integer Storage

**Use Rails `enum` feature with integer database storage**

#### Benefits
1. ✅ **Database Storage**: 4-byte integers instead of VARCHAR/TEXT
2. ✅ **Ruby Memory**: Automatic symbol interning - only one Symbol object per unique value across all records
3. ✅ **Memory Savings**: Hundreds of status fields sharing a few symbol objects instead of creating hundreds of String objects per record
4. ✅ **API Improvements**: Clean Ruby API with predicate methods (`warnings.met?`, `warnings.unmet!`)
5. ✅ **Database Portability**: Works identically on other databases (not PostgreSQL-specific)
6. ✅ **Simpler Migration**: Standard Rails pattern

#### Example of what to avoid

We don't want this, if we can avoid it:

```ruby
class Project < ApplicationRecord
  # Common status values for most criteria
  enum floss_license_status: { '?' => 0, 'Unmet' => 1, 'Met' => 2, 'N/A' => 3 }
  enum build_status: { '?' => 0, 'Unmet' => 1, 'Met' => 2, 'N/A' => 3 }
  enum test_status: { '?' => 0, 'Unmet' => 1, 'Met' => 2, 'N/A' => 3 }
  # ... hundreds more
end
```
All status values should map to a *single* enumerated type, since they
all have the same possibilities.

### Rejected Alternative: PostgreSQL Native Enums (Not Recommended)

PostgreSQL native enum types would:
- ✅ Store as 4-byte integers in PostgreSQL
- ❌ Still create new String objects in Ruby by default
- ❌ Require explicit freezing/interning: `def status; super&.freeze; end`
- ❌ PostgreSQL-specific (not portable)
- ❌ More complex to modify enum values later

### Alternative Approach: Raw Integers with Custom Mapping (Recommended for Maximum Efficiency)

**Store as integers in PostgreSQL, keep as integers in Ruby, map only at serialization boundaries**

This is the most memory-efficient approach and deserves serious consideration.

#### Implementation

```ruby
class Project < ApplicationRecord
  # Single source of truth for all criterion status values
  CRITERION_STATUS = ['?', 'Unmet', 'N/A', 'Met'].freeze

  # Derived hash for fast reverse lookups (name to integer)
  CRITERION_STATUS_BY_NAME = CRITERION_STATUS.each_with_index.to_h { |name, idx| [name, idx] }.freeze

  # Constant integers
  CRITERION_UNKNOWN = CRITERION_STATUS_BY_NAME['?']
  CRITERION_UNMET = CRITERION_STATUS_BY_NAME['Unmet']
  CRITERION_NA = CRITERION_STATUS_BY_NAME['N/A']
  CRITERION_MET = CRITERION_STATUS_BY_NAME['Met']

  # Status fields stored as integers (0-3) in database and Ruby
  # No enum declarations needed - use integers directly
end
```

#### Benefits

1. ✅ **Maximum Memory Efficiency**: Integers are immediate values in Ruby (Fixnum) - no object allocation for small integers
2. ✅ **True Type Sharing**: Single array constant used for ALL status fields
3. ✅ **Fastest Access**: Direct integer comparison in Ruby (`status == 3` vs symbol comparison)
4. ✅ **No Method Pollution**: No hundreds of generated predicate methods cluttering the namespace
5. ✅ **Simpler Code**: `project.warnings_status == 3` is clear and direct
6. ✅ **Database Efficient**: Same 4-byte integer storage as Rails enum approach
7. ✅ **Clean Serialization**: Convert to strings only at API/view boundaries where needed

#### Drawbacks

1. ❌ **Manual Mapping Required**: Need explicit conversion for JSON/views: `CRITERION_STATUS[status_value]`
2. ❌ **No Predicate Methods**: Can't use `project.warnings_status.met?` - must use `project.warnings_status == 3`
3. ❌ **No Setter Convenience**: Can't use `project.warnings_status = :met` - must use integer or convert from string
4. ❌ **Magic Numbers in Code**: Direct integer comparisons less readable than symbols (though constants can help)

#### Memory Comparison

**Rails Enum Approach (per Project instance):**

- Hundreds of Symbol references (symbols interned globally, but still objects)
- Symbol overhead: ~40 bytes per unique symbol + pointer in each instance

**Raw Integer Approach (per Project instance):**

- Hundreds of Fixnum immediate values (0 bytes object allocation)
- Total overhead: 0 bytes for status values themselves

**Estimated savings per Project instance: Several KB**

#### Code Patterns

```ruby
# Setting values from user input (e.g., form params)
project.warnings_status = Project::CRITERION_STATUS_BY_NAME[params[:status]]

# Reading for display (JSON, views)
{ warnings_status: Project::CRITERION_STATUS[project.warnings_status] }

# Comparisons in business logic
if project.warnings_status == 3  # Met
  # Could use: Project::CRITERION_STATUS.index('Met')
  # Or define: CRITERION_MET = 3 for readability
end
```

#### Why This Is More Efficient Than Rails Enums

Rails enums convert integers to symbols automatically. While symbols are interned (shared across all instances), they are still heap-allocated objects. In contrast:

- **Small integers (Fixnum)**: Encoded directly in the VALUE (pointer-sized), no heap allocation
- **Symbols**: Require heap allocation, symbol table entry, and object overhead

With hundreds of status fields per Project, the difference compounds significantly.

## Expected Memory Impact

### Current (String-based)
- Each Project record: ~hundreds of String allocations
- 1000 Project records: ~hundreds of thousands of String objects

### After Rails Enum (Symbol-based)
- Each Project record: References to ~10 shared Symbol objects
- 1000 Project records: Still only ~10 Symbol objects total
- **Estimated savings**: Dozens of KB per Project instance

## JSON and editing

We generate JSON. When doing so, we need to convert these status values
back to strings (e.g., "Met") since the integers will mean little to
readers, and switching to integers would also be backwards-incompatible.

When we accept edit requests, we'll need to ensure that only valid
status values are accepted (we do that anyway) and they'll have the
same text inputs as current. This change to enums should be
entirely internal to the application and those with direct access to
the database, and should *not* impact external users in any way.

## Implementation Considerations

1. **Bulk Migration**: Converting hundreds of columns will be a large migration
2. **Backward Compatibility**: Ensure API compatibility if external code depends on string values
3. **Testing**: Comprehensive tests to ensure enum mappings are correct
4. **Documentation**: Update API documentation to reflect new enum methods
5. **Performance**: The migration itself may take time on large datasets (use batching if needed)

## Raw Integer Approach: Conversion Strategy

Based on analysis of the codebase, here's how the raw integer approach would handle data flow:

### Current Data Flow

1. **HTML Forms** (app/views/projects/_status_chooser.html.erb):
   - Radio buttons with string values: `'Met'`, `'Unmet'`, `'N/A'`, `'?'`
   - Example: `f.radio_button status_symbol, 'Met', label: t('criterion_status.Met')`

2. **JavaScript** (app/assets/javascripts/project-form.js):
   - Reads string values from DOM: `checkedInput.value`
   - Compares as strings: `if (status === 'Met')`

3. **Server Input** (app/controllers/projects_controller.rb):
   - Receives params with string values
   - Currently passes directly to ActiveRecord for storage as strings

4. **Server Output** (app/views/projects/_project.json.jbuilder):
   - Uses `project.attributes` to get all fields
   - Currently returns strings directly to JSON

### Required Changes for Raw Integer Approach

#### 1. No Changes Needed

- **HTML forms**: Continue using string values in radio buttons
- **JavaScript**: Continue using string comparisons and DOM reads
- **External API**: JSON continues to expose strings for backward compatibility

#### 2. Changes Required

**A. Project Model** (app/models/project.rb)

Add constants and conversion methods:

```ruby
class Project < ApplicationRecord
  # Single source of truth for all criterion status values
  CRITERION_STATUS = ['?', 'Unmet', 'N/A', 'Met'].freeze

  # Derived hash for fast reverse lookups (name to integer)
  CRITERION_STATUS_BY_NAME = CRITERION_STATUS.each_with_index.to_h { |name, idx| [name, idx] }.freeze

  # Optional: Readable constants for common comparisons
  CRITERION_UNKNOWN = 0
  CRITERION_UNMET = 1
  CRITERION_NA = 2
  CRITERION_MET = 3

  # Convert status integer to string for display
  def status_to_s(status_value)
    CRITERION_STATUS[status_value]
  end

  # Convert string status to integer (for params processing)
  # Returns nil for invalid values (let validation handle it)
  def self.status_from_s(status_string)
    CRITERION_STATUS_BY_NAME[status_string]
  end
end
```

**B. Controller Params Processing** (app/controllers/projects_controller.rb)

Add a before_action to convert incoming string params to integers:

```ruby
class ProjectsController < ApplicationController
  before_action :convert_status_params, only: [:create, :update]

  private

  def convert_status_params
    return unless params[:project]

    # Convert all status fields from strings to integers
    Project::ALL_CRITERIA_STATUS.each do |status_field|
      next unless params[:project][status_field]

      string_value = params[:project][status_field]
      integer_value = Project.status_from_s(string_value)
      params[:project][status_field] = integer_value if integer_value
    end
  end
end
```

**C. JSON Serialization** (app/views/projects/_project.json.jbuilder)

Convert integer values back to strings for API output:

```ruby
# Convert status fields from integers back to strings for API compatibility
transformed_attrs =
  project.attributes.transform_keys do |key|
    ProjectsHelper::BASELINE_FIELD_DISPLAY_NAME_MAP.fetch(key, key)
  end.transform_values do |value|
    # If this is an integer in the status range, convert to string
    if value.is_a?(Integer) && value >= 0 && value <= 3
      Project::CRITERION_STATUS[value]
    else
      value
    end
  end
```

**Alternative (more explicit)**: Transform only status fields:

```ruby
transformed_attrs = project.attributes.dup
Project::ALL_CRITERIA_STATUS.each do |status_field|
  status_value = transformed_attrs[status_field.to_s]
  transformed_attrs[status_field.to_s] = Project::CRITERION_STATUS[status_value] if status_value
end
# Then apply key transformation
transformed_attrs = transformed_attrs.transform_keys do |key|
  ProjectsHelper::BASELINE_FIELD_DISPLAY_NAME_MAP.fetch(key, key)
end
```

**D. View Helpers** (if status values displayed in ERB views)

Add helper method for displaying status in views:

```ruby
module ProjectsHelper
  def display_status(status_integer)
    Project::CRITERION_STATUS[status_integer]
  end
end
```

### Difficulty Assessment

**Is this difficult?** No, the conversion is straightforward:

1. **String → Integer (Input)**: One before_action filter in controller (10-15 lines)
2. **Integer → String (Output)**: Modify jbuilder template (5-10 lines)
3. **Model Constants**: Add CRITERION_STATUS constants (5 lines)
4. **View Helpers** (if needed): Simple array lookup (2-3 lines)

**Total implementation**: ~30-40 lines of code changes

**Key Advantages**:

- HTML/JavaScript completely unchanged (no frontend work)
- External API backward compatible (still serves strings)
- Conversion happens only at boundaries (controller input, JSON output)
- All business logic can use fast integer comparisons

**Potential Issues**:

- Need to update any direct comparisons in Ruby code (e.g., `if project.status == 'Met'` → `if project.status == 3`)
- Need to audit code for string assumptions
- Migration needs careful handling for existing data

## Conclusion

Using Rails enums with integer storage provides substantial memory savings by leveraging Ruby's automatic symbol interning, while also improving the API and maintaining database portability. This is the recommended approach for optimizing memory usage in the Rails application.
