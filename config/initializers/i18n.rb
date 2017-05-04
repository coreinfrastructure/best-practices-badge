# frozen_string_literal: true

# Allow use of locales Rails doesn't know about (e.g., Chinese - zh)
# We filter locales separately.
I18n.enforce_available_locales = false

# Some pages say this is needed, but we haven't needed it so far.
# config.i18n.default_locale = :en
# config.i18n.fallbacks = [ :en ]
