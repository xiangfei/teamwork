# frozen_string_literal: true

module Teamwork
  module Validator
    # no doc
    class Collect < Required
      # only check required

      def initialize(opts = {})
        @opts = opts
        @required = %w[monitor_name task_id severity]
      end
    end
  end
end
