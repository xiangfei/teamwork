# frozen_string_literal: true

module Teamwork
  module Client
    module Task
      module Collect
        # 代理任务taskid, topic 固定, 处理流程收集消息,缓存到cache表
        class Base
          class << self
            attr_reader :_taskinfo, :_tasks

            def set_task_info(opts = {})
              task_info.merge! opts
            end

            # 只做收集,执行失败放告警任务
            def task_info
              @_taskinfo ||= { topic: 'teamwork.collect.normal', send: true, task_id: name.downcase.gsub('::', '_'), monitor_name: name.downcase.gsub('::', '_') }
            end

            # 全局task_id, 用来创建默认collect 任务
            def task_id
              task_info[:task_id]
            end

            def monitor_name
              task_info[:monitor_name]
            end

            def send
              task_info[:send]
            end

            def topic
              task_info[:topic]
            end

            def basemsg
              @basemsg ||= { 'task_id' => task_id, 'ip' => Teamwork::Utils.ip, 'mac' => Teamwork::Utils.mac, 'hostname' => Teamwork::Utils.hostname }
            end

            def find(taskid)
              tasks[taskid] ||= new
            end

            def tasks
              @_tasks ||= {}
            end

            def clean_tasks
              children.each do |c|
                c.tasks.clear
              end
            end

            def inherited(subclass)
              children << subclass
            end

            def children
              @_children ||= []
            end
          end

          def initialize
            @_m = {}
          end

          def process(_ops = {})
            raise 'abstract  method cannot run'
          end

          def run(args = {})
            begin
              @_m.merge! self.class.basemsg
              @_m['task_id'] = args['task_id'] || self.class.task_id
              @_m['monitor_name'] = args['monitor_name'] || self.class.monitor_name
              process args
              @_m['time'] = Time.now.to_i
              Teamwork.cache.set task_id, @_m
            rescue StandardError => e
              Teamwork.logger.error("run task failed cls: #{self.class} , taskid: #{task_id} , message:  #{e.message}")
            end
            sendmsg if self.class.send
            alarms = args['alarms'] || []
            trigger_alarms alarms
          end

          def msg
            @_m
          end

          def trigger_alarms(alarms = [])
            Teamwork.logger.info " #{task_id} no need to do alarm skip" if alarms.empty?
            alarms.each do |alarm|
              alarm_class = alarm['alarm_class']
              severity = alarm['severity']
              message = alarm['message']
              key = alarm['key']
              value = alarm['value']
              alarm = Teamwork::Client::Task::Alarm::Base.new task_id, key, value, alarm_class, severity, message
              alarm.run
            end
          end

          private

          def task_id
            @_m['task_id']
          end

          def sendmsg
            unless @_m
              Teamwork.logger.error 'msg 为空不能发消息'
              return
            end
            begin
              Teamwork.message.deliver_message @_m, topic: self.class.topic
            rescue StandardError => e
              Teamwork.logger.error "msg  class #{self.class} , topic #{self.class.topic}  msg: #{@_m} error #{e.message}"
            end
          end
        end
      end
    end
  end
end
