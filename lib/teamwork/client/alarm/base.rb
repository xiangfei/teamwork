module Teamwork
  module Client
    class Alarm
      module Agent
        # base class , define , kafka topic
        # 需要在每一台机器周期性执行任务
        # all alarm , first recover  发送到告警记录,
        # 匹配条件的告警发邮件,放入实时告警
        # 所有消息放大数据,等格式。
        class Base
          include Aspect4r
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

          attr_reader :taskid

          def initialize(collecttaskid, key, value, alarm_class)
            @taskid = "#alarm_#{collecttaskid}"
            @collecttaskid = collecttaskid
            @key = key
            @expect = value
          end

          def process(ops = {})
           # raise "abstract  method cannot run" 
          end

          def record_alarm
            @al = alarm_class.record_alarm real, expect, cache
          end

          def run(args = {})
            begin
              record_alarm
              process args
              Teamwork.cache.set self.class.taskid, msg
            rescue => e
              Teamwork.logger.error("handler alarm failed  #{e.message}")
            end
            sendmsg if self.class.send_msg
          end

          def first_alarm
            if @al.first_alarm?
            end
          end

          def first_recover
            if @al.first_recover?
            end
          end

          def config_alarm?
            if @al.config_alarm?
            end
          end

          def many_recover?
            if @al.many_recover?
            end
          end

          def cache
            Teamwork.cache.get(@collecttaskid)
          end

          def key
            @key
          end

          def real
            cache[key]
          end

          def expect
            @expect
          end
        end
      end
    end
  end
end
