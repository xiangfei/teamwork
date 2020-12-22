module Teamwork
  module Alarm
    class Cpuusage < Base
      # cpu 实际 大于期望 告警
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
