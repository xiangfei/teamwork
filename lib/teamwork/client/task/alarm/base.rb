# frozen_string_literal: true

module Teamwork
  module Client
    module Task
      module Alarm
        # base class , define , kafka topic
        # 需要在每一台机器周期性执行任务
        # all alarm , first recover  发送到告警记录,
        # 匹配条件的告警发邮件,放入实时告警
        # 所有消息放大数据,等格式。
        class Base
          class << self
            attr_reader :_alarms

            def find(taskid)
              @_alarms ||= {}
              @_alarms[taskid] || new(taskid)
            end

            def destroy(taskid)
              @_alarms ||= {}
              @_alarms.delete taskid
            end
          end

          attr_reader :taskid, :key, :expect, :severity, :message

          def initialize(collecttaskid, key, value, alarm_class, severity = 'level_high', message = 'message  handler problem')
            @taskid = "alarm__#{key}__#{collecttaskid}"
            @collecttaskid = collecttaskid
            @key = key
            @expect = value
            @severity = severity
            @message = message
            @alarm_class = if alarm_class.is_a? String
                             Object.const_get(alarm_class)
                           else
                             alarm_class
                           end
          end

          def process(ops = {})
            # raise "abstract  method cannot run"
          end

          def record_alarm
            @al = @alarm_class.record_alarm @collecttaskid, expect, real, severity, message
          end

          def run(args = {})
            record_alarm
            process_alarm
            process args
            Teamwork.cache.set taskid, msg
          rescue StandardError => e
            Teamwork.logger.error("handler alarm failed  #{e.message}")
          end

          def process_alarm
            if @al.first_alarm?
              Teamwork.message.deliver_message msg, topic: 'teamwork.historyalarm'
              Teamwork.message.deliver_message msg, topic: 'teamwork.realalarm'
              Teamwork.message.deliver_message msg, topic: 'teamwork.notify'
            elsif @al.config_alarm?
              Teamwork.message.deliver_message msg, topic: 'teamwork.historyalarm'
              Teamwork.message.deliver_message msg, topic: 'teamwork.notify'
            elsif @al.first_recovered?
              Teamwork.message.deliver_message msg, topic: 'teamwork.historyalarm'
              Teamwork.message.deliver_message msg, topic: 'teamwork.realalarm'
              Teamwork.message.deliver_message msg, topic: 'teamwork.notify'
            elsif @al.many_alarm?
              Teamwork.message.deliver_message msg, topic: 'teamwork.historyalarm'
            elsif @al.many_recovered?
              Teamwork.logger.info "alarm  #{@al.detail} is not an alarm"
            end
          end

          def msg
            @al.detail.merge! 'alarm_task_id' => @taskid
          end

          def cache
            Teamwork.cache.get(@collecttaskid)
          end

          def real
            cache[key]
          end
        end
      end
    end
  end
end
