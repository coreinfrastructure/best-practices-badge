# frozen_string_literal: true

if Rails.env.local?
  # https://github.com/vcr/vcr/blob/master/lib/vcr/library_hooks/webmock.rb

  module VCR
    class LibraryHooks
      module WebMock
        module_function

        def with_global_hook_disabled(request)
          global_hook_disabled_requests << request

          begin
            yield
          ensure
            global_hook_disabled_requests.delete(request)
          end
        end

        def global_hook_disabled?(request)
          requests = Thread.current[:_vcr_webmock_disabled_requests]
          requests&.include?(request)
        end

        def global_hook_disabled_requests
          Thread.current[:_vcr_webmock_disabled_requests] ||= []
        end
      end
    end
  end
end
