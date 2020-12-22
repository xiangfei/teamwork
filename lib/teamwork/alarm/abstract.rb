module Teamwork
  module Alarm
    #只定义告警策略,以后有必要拆出来
    class Abstract
      class << self
        attr_reader :prefix

        def awifi_alarm_prefix(value)
          @prefix = value
        end

        def prefix
          @prefix ||= ""
        end

        def alarm_config
          Teamwork::Task::Alarm.alarm_config
        end

        def find(remarked_id)
          instance = new remarked_id, nil, nil, {}
          instance.full_message
        end

        def record_alarm(taskid, flag, value, args = {})
          instance = new taskid , flag ,value ,args 
          instance.record_alarm
          instance
        end
      end

      attr_reader :taskid, :msgbase, :value, :flag, :args
      # flag ops 监控数据 , value ,执行结果
      def initialize(taskid, flag, value, args = {})
        @taskid = taskid
        @msgbase = args["monitor_name"]
        @flag = flag
        @value = value
        @args = args
        #record_alarm
      end

      def record_alarm
        if alarm?
          self.recovered_times_cache = 0
          self.alarm_times_cache = self.alarm_times_cache + 1
          self.alarm_cache = self.detail
          self.started_at ||= Time.now.to_i
          self.recovered_cache = nil
          # 一直没有告警不需要发消息
          self.send_alarm = true
          self.full_message = detail
        else
          self.alarm_times_cache = 0
          self.started_at = nil
          self.recovered_times_cache = self.recovered_times_cache + 1
          self.recovered_cache = self.detail
          self.alarm_cache = nil
          self.full_message = detail
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
          "problem: #{@msgbase} alarm value #{@flag}  current #{@value}"
        else
          "resolved: #{@msgbase} alarm value #{@flag}  current #{@value}"
        end
      end

      def full_message=(value)
        Teamwork.cache.set "#{@taskid}_fullmessage#{self.class.prefix}", value
      end

      def full_message
        Teamwork.cache.get("#{@taskid}_fullmessage#{self.class.prefix}")
      end

      def detail
        if alarm?
          @args.merge({ message: message, status: "problem", alarm_count: alarm_times, started_at: started_at, timestamp: Time.now.to_i, time: Time.now.to_i })
        else
          @args.merge({ message: message, status: "resolved", recovered_count: recovered_times, timestamp: Time.now.to_i, time: Time.now.to_i })
        end
      end

      def send_alarm=(value)
        Teamwork.cache.set "#{@taskid}_alarm_cache_send_alarm#{self.class.prefix}", value
      end

      def send_alarm
        Teamwork.cache.get("#{@taskid}_alarm_cache_send_alarm#{self.class.prefix}") || false
      end

      def started_at
        Teamwork.cache.get("#{@taskid}_alarm_cache_started_at#{self.class.prefix}")
      end

      def started_at=(value)
        Teamwork.cache.set "#{@taskid}_alarm_cache_started_at#{self.class.prefix}", value
      end

      def alarm_cache
        Teamwork.cache.get("#{@taskid}_alarm_cache#{self.class.prefix}")
      end

      def alarm_cache=(value)
        Teamwork.cache.set "#{@taskid}_alarm_cache#{self.class.prefix}", value
      end

      def recovered_cache
        Teamwork.cache.get("#{@taskid}_recovered_cache#{self.class.prefix}")
      end

      def recovered_cache=(value)
        Teamwork.cache.set "#{@taskid}_recovered_cache#{self.class.prefix}", value
      end

      def alarm_times_cache
        Teamwork.cache.get("#{@taskid}_alarm_times_cache#{self.class.prefix}") || 0
      end

      def alarm_times_cache=(value)
        Teamwork.cache.set "#{@taskid}_alarm_times_cache#{self.class.prefix}", value
      end

      def recovered_times_cache=(value)
        Teamwork.cache.set "#{@taskid}_recovered_times_cache#{self.class.prefix}", value
      end

      def recovered_times_cache
        Teamwork.cache.get("#{@taskid}_recovered_times_cache#{self.class.prefix}") || 0
      end
    end
  end
end
