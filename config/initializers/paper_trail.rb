# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Association Tracking for PaperTrail has been extracted to a separate gem
# as of PaperTrail version 10.
# We could use it by adding `paper_trail-association_tracking` to the Gemfile.
# However, like most people, we don't use it.
# Thus, we no longer need to add this line:
# PaperTrail.config.track_associations = false
