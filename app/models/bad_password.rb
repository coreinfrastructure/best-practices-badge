# frozen_string_literal: true

# Copyright the CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# This is a simple list of records with column "forbidden" of all
# "known bad passwords". There's not anything to it; ActiveRecord handles it.

class BadPassword < ApplicationRecord
end
