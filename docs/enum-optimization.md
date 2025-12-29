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

### Proposed Solution: Rails Enums with Integer Storage

**Use Rails `enum` feature with integer database storage**

All of these enums should be a mapping to the same underlying data type,
if possible. That's because all status values have the same 4 possible values:

* '?' => 0 (default. We want this to be 0 because it's the default)
* 'Unmet' => 1
* 'N/A' => 2
* 'Met' => 3 (We want this to be 3, so it takes 2 bit flips to go
  from '?' to 'Met')

All status values should map to a *single* enumerated type, since they
all have the same possibilities. It would much more confusing if there
was a different mapping.

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

### Rejected Alternative: Store as integers in PostgreSQL, map in application

This would be efficient, but there'd be a lot of work to map the
ActiveRecord values (which would now have raw integers) to the strings
that JSON and the client-side JavaScript expect.
Since the enumerated values will all map to a few symbols, we
don't expect this to much more efficient.
It would be good to verify this with analysis.

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

## Conclusion

Using Rails enums with integer storage provides substantial memory savings by leveraging Ruby's automatic symbol interning, while also improving the API and maintaining database portability. This is the recommended approach for optimizing memory usage in the Rails application.
