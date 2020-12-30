# frozen_string_literal: true

module Teamwork
  module Validator
    # no doc
    class Required
      # only check required

      def initialize(opts = {}, required = [])
        @opts = opts
        @required = required
      end

      def validate
        @success = true
        @required.each do |k|
          unless @opts[k]
            errors << "#{k} not exist in #{@opts}"
            @success = false
          end
        end
        @success
      end

      def success?
        @success
      end

      def errors
        @errors ||= []
      end
    end
  end
end
