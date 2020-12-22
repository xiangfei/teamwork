module Teamwork
  module Alarm
    class Base
      class << self
        def alarm_config
          Teamwork::Task::Alarm.alarm_config
        end

        def find(remarked_id)
          instance = new remarked_id, nil, nil
          instance.full_message
        end

        def record_alarm(taskid, flag, value)
          instance = new taskid, flag, value
          instance.record_alarm
          instance
        end
      end
      attr_reader :taskid, :msg, :monitor_name
      # taskid 收集任务id   expected 期望结果 ,  real执行结果
      def initialize(taskid, expected, real)
        @taskid = taskid
        @real = real
        @expected = expected
        @msg = Teamwork.cache.get(taskid)
        @monitor_name = @msg["monitor_name"]
      end

      def record_alarm
        if alarm?
          self.recovered_times_cache = 0
          self.alarm_times_cache = self.alarm_times_cache + 1
          self.alarm_cache = self.detail
          self.started_at ||= Time.now.to_i
          self.recovered_cache = nil
          self.send_alarm = true
        else
          self.alarm_times_cache = 0
          self.started_at = nil
          self.recovered_times_cache = self.recovered_times_cache + 1
          self.recovered_cache = self.detail
          self.alarm_cache = nil
        end
      end

      def alarm?
        raise "abstract method"
      end

      def first_alarm?
        alarm_times_cache == 1
      end

      # 默认告警配置
      def config_alarm?
        if alarm_times == 0
          return false
        end
        if self.class.alarm_config["first"].include? alarm_times
          Teamwork.logger.debug "first match #{alarm_times}"
          return true
        else
          if alarm_times % self.class.alarm_config["repeat"] == 0
            Teamwork.logger.debug "repeat match #{alarm_times}"
            return true
          else
            Teamwork.logger.debug "not match all #{alarm_times}"
            return false
          end
        end
      end

      def many_alarm?
        alarm_times_cache > 1
      end

      def first_recovered?
        recovered_times_cache == 1 and self.send_alarm
      end

      def many_recovered?
        recovered_times_cache > 1
      end

      def alarm_times
        alarm_times_cache
      end

      alias :alarm_count :alarm_times

      def recovered_times
        recovered_times_cache
      end

      alias :recovered_count :recovered_times

      def message
        if alarm?
          "problem: #{@moniter_name} alarm value #{@expected}  current #{@real}"
        else
          "resolved: #{@monitor_name} alarm value #{@expected}  current #{@real}"
        end
      end

      def detail
        if alarm?
          @msg.merge({ message: message, status: "problem", alarm_count: alarm_times, started_at: started_at, timestamp: Time.now.to_i, time: Time.now.to_i })
        else
          @msg.merge({ message: message, status: "resolved", recovered_count: recovered_times, timestamp: Time.now.to_i, time: Time.now.to_i })
        end
      end

      def full_message
        alarm_cache || recovered_cache
      end

      #判断是否已经发送过告警
      def send_alarm=(value)
        Teamwork.cache.set "#{@taskid}_alarm_cache_send_alarm", value
      end

      def send_alarm
        Teamwork.cache.get("#{@taskid}_alarm_cache_send_alarm") || false
      end

      def started_at
        Teamwork.cache.get("#{@taskid}_alarm_cache_started_at")
      end

      def started_at=(value)
        Teamwork.cache.set "#{@taskid}_alarm_cache_started_at", value
      end

      def alarm_cache
        Teamwork.cache.get("#{@taskid}_alarm_cache")
      end

      def alarm_cache=(value)
        Teamwork.cache.set "#{@taskid}_alarm_cache", value
      end

      def recovered_cache
        Teamwork.cache.get("#{@taskid}_recovered_cache")
      end

      def recovered_cache=(value)
        Teamwork.cache.set "#{@taskid}_recovered_cache", value
      end

      def alarm_times_cache
        Teamwork.cache.get("#{@taskid}_alarm_times_cache") || 0
      end

      def alarm_times_cache=(value)
        Teamwork.cache.set "#{@taskid}_alarm_times_cache", value
      end

      def recovered_times_cache=(value)
        Teamwork.cache.set "#{@taskid}_recovered_times_cache", value
      end

      def recovered_times_cache
        Teamwork.cache.get("#{@taskid}_recovered_times_cache") || 0
      end
    end
  end
end
