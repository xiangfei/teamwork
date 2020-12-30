# frozen_string_literal: true

module Teamwork
  module Client
    module Config
      # no doc
      class Alarm < Base
        self.path = '/teamwork/config/alarm'

        class << self
          def config_alarm?(alarm_times)
            return false if alarm_times.zero?

            c = alarm_times % config['repeat']
            return true if c.zero?

            if config['first'].include? alarm_times
              true
            else
              false
            end
          end
        end
      end
    end
  end
end
