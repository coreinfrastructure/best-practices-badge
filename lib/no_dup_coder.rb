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
#
# Unlike DupCoder, this module never inspects string contents to guess
# whether they are marshaled data. Instead, marshaled non-string values
# are wrapped in a MarshaledValue struct, so the type alone determines
# handling on load. This avoids the risk of a potential deserialization
# vulnerability where user-supplied strings starting with
# Marshal's signature bytes could trigger Marshal.load.

module NoDupCoder
  # Wrapper that distinguishes marshaled non-string values from plain
  # strings stored in the cache. Using a distinct type eliminates any
  # need to inspect string contents on load.
  MarshaledValue = Struct.new(:data)

  extend self # rubocop:disable Style/ModuleFunction

  def dump(entry)
    value = entry.value
    if value.is_a?(String)
      # Hot path: fragment cache produces strings/SafeBuffers.
      # Already-frozen strings need no new Entry at all.
      return entry if value.frozen?

      new_entry(value.dup.freeze, entry)
    elsif value.frozen?
      # All Ruby immediates (nil, true, false, Integer, Float, Symbol)
      # are frozen. This also covers any future Ruby immediates and any
      # value the caller has explicitly frozen.
      entry
    else
      new_entry(MarshaledValue.new(Marshal.dump(value)), entry)
    end
  end

  def dump_compressed(entry, threshold)
    compressed_entry = entry.compressed(threshold)
    compressed_entry.compressed? ? compressed_entry : dump(entry)
  end

  def load(entry)
    if entry.value.is_a?(MarshaledValue)
      new_entry(
        Marshal.load(entry.value.data), # rubocop:disable Security/MarshalLoad
        entry
      )
    else
      entry
    end
  end

  private

  def new_entry(value, source)
    ActiveSupport::Cache::Entry.new(
      value, expires_at: source.expires_at, version: source.version
    )
  end
end
