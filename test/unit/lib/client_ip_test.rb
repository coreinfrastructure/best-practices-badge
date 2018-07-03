# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class ClientIpTest < ActiveSupport::TestCase
  test 'ClientIP works correctly without X-Forwarded-For' do
    class MockReq
      def get_header(_x)
        nil
      end

      def ip
        '1.2.3.4'
      end
    end

    m = MockReq.new
    result = ClientIp.acquire(m)
    assert '1.2.3.4', result
  end

  # In our production environment we must use SECOND from the end.
  # Change this test, and ClientIp, if your environment is different.
  test 'ClientIP works correctly with X-Forwarded-For, production env' do
    class MockReq
      def get_header(_x)
        '1.1.1.1, 100.36.183.117, 157.52.82.3'
      end

      def ip
        '1.2.3.4'
      end
    end

    m = MockReq.new
    result = ClientIp.acquire(m)
    assert '100.36.183.117', result
  end
end
