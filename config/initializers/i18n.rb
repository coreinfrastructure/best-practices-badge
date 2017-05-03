# frozen_string_literal: true

# Allow use of locales Rails doesn't know about (e.g., Chinese - zh)
# We filter locales separately.
I18n.enforce_available_locales = false
