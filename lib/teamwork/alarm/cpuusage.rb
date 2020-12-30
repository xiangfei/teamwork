# frozen_string_literal: true

module Teamwork
  module Alarm
    # no doc
    class Cpuusage < Base
      def alarm?
        @expected < @real
      end

      def message
        if alarm?
          "problem: #{@moniter_name} alarm value #{@expected}  current #{@real}"
        else
          "resolved: #{@monitor_name} alarm value #{@expected}  current #{@real}"
        end
      end
    end
  end
end
