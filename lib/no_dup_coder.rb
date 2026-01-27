# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# NoDupCoder is a drop-in replacement for ActiveSupport::Cache::MemoryStore's
# default DupCoder. Instead of duplicating strings on every cache read,
# NoDupCoder freezes values on write and returns the frozen object directly
# on read. This eliminates large string allocations from Marshal/dup on
# every cache hit (e.g., fragment cache reads).
#
# Safety: frozen strings cannot be mutated, so there is no risk of cache
# corruption. Frozen SafeBuffers preserve their html_safe? status.
module NoDupCoder
  extend self

  MARSHAL_SIGNATURE = "\x04\x08".b.freeze
  private_constant :MARSHAL_SIGNATURE

  def dump(entry)
    if entry.value && entry.value != true && !entry.value.is_a?(Numeric)
      ActiveSupport::Cache::Entry.new(
        dump_value(entry.value),
        expires_at: entry.expires_at, version: entry.version
      )
    else
      entry
    end
  end

  def dump_compressed(entry, threshold)
    compressed_entry = entry.compressed(threshold)
    compressed_entry.compressed? ? compressed_entry : dump(entry)
  end

  def load(entry)
    if !entry.compressed? && entry.value.is_a?(String)
      ActiveSupport::Cache::Entry.new(
        load_value(entry.value),
        expires_at: entry.expires_at, version: entry.version
      )
    else
      entry
    end
  end

  private

  def dump_value(value)
    if value.is_a?(String) && !value.start_with?(MARSHAL_SIGNATURE)
      value.frozen? ? value : value.dup.freeze
    else
      Marshal.dump(value)
    end
  end

  def load_value(string)
    if string.start_with?(MARSHAL_SIGNATURE)
      Marshal.load(string) # rubocop:disable Security/MarshalLoad
    else
      string
    end
  end
end
