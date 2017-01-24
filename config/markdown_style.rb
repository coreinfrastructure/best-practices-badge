# frozen_string_literal: true
# Configure for markdownlint (mdl), a markdown style checker
# Note: mdl 0.2.0 and 0.2.1 have a serious bug in command line parsing,
# and thus you *have* to use a file to adjust rules.

all
# We *must* permit long lines, because we're using GitHub flavored markdown,
# which inserts <br> on every newline in a normal paragraph.
exclude_tag :line_length

# For the moment we'll disable many rules to make it easier to get started.
# The current plan is to slowly remove many of these over time.

# Rule MD004 requires that unordered lists use a consistent marking, but it
# has no way to enforce the rule "* at the topmost level, - at the next one".
# Having all levels with the same symbol is confusing, so we exclude the rule.
exclude_rule 'MD004'

# exclude_rule 'MD005'
exclude_rule 'MD007'
exclude_rule 'MD009'
exclude_rule 'MD012'
exclude_rule 'MD022'
exclude_rule 'MD025'
exclude_rule 'MD026'
exclude_rule 'MD029'
exclude_rule 'MD030'
# We include rule MD032, which requires that
# lists be surrounded by blank lines (MD032).
# This detects a lot of malformed text that should be in a list but is not.
# This is also important for portability: Some markdown formatters
# require blank lines around lists, while others don't.
# To see this portability problem in action, see:
# http://johnmacfarlane.net/babelmark2/?text=Is+this+a+list%3F%0A*+First+bullet%0A*+Second+bullet%0A
exclude_rule 'MD033'
exclude_rule 'MD034' # Bare URLs are okay, just surround with <..>
exclude_rule 'MD036'
exclude_rule 'MD039'
exclude_rule 'MD040'
