# frozen_string_literal: true

module Teamwork
  module Validator
    # no doc
    class Alarm < Required
      # only check required

      def initialize(opts = {})
        @opts = opts
        @required = %w[severity collect_task_id key expect alarm_class]
      end

    end
  end
end
