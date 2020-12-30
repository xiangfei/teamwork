# frozen_string_literal: true

module Teamwork
  module Client
    # no doc
    class Collect < Base
      class << self
        def create_collect_task(taskid, opts = {})
          create_task taskid, opts unless Teamwork.task.exists? "#{task_path}/#{taskid}"
        end
      end

      set_client_path '/teamwork/client/collect'
      set_queue Teamwork::Utils.mac
      set_task_path "/teamwork/task/collect/#{Teamwork::Utils.mac}"

      create_collect_task Teamwork::Client::Task::Collect::CpuUsage.task_id,
                          { time: 20, opt: 'every', method: 'run', cls: 'Teamwork::Client::Task::Collect::CpuUsage',
                            args: { alarms: [{ alarm_class: 'Teamwork::Alarm::Cpuusage', key: 'cpu_load_5', severity: 'level_high', message: 'cpu 负载过高', value: 0.001 }] } }
      1.upto 100 do |i|
        create_collect_task "cpuusage_#{i}",
                            { time: 20, opt: 'every', method: 'run', cls: 'Teamwork::Client::Task::Collect::CpuUsage',
                              args: { task_id: "cpuusage_#{i}", monitor_name: "cpuusage_#{i}", alarms: [{ alarm_class: 'Teamwork::Alarm::Cpuusage', key: 'cpu_load_5', severity: 'level_high', message: 'cpu 负载过高', value: 0.001 }] } }
      end

      def initialize
        super
        @rufus_scheduler ||= Teamwork::Schedule::RufusTask.new
        fetch_and_restart_scheduler
        monitor_collect_task
        monitor_queue_task
      end

      def monitor_queue_task
        self.class.queue.consume do |title, value|
          Teamwork.logger.debug "start handler collect  once task #{title}  #{value}"
          hash_task = JSON.parse value
          cls = Object.const_get(hash_task['cls'])
          timeout = hash_task['timeout'] || 600
          Timeout.timeout timeout do
            cls.s.send hash_task['method'], hash_task['args']
          end
          Teamwork.logger.debug "start handler collect once task #{title}  success"
        rescue StandardError => e
          Teamwork.logger.error "处理任务失败 #{title} #{value} error message #{e.message}"
        end
      end

      def monitor_collect_task
        Teamwork.task.watch_children self.class.task_path do
          fetch_and_restart_scheduler
        end
      end

      def fetch_and_restart_scheduler
        @rufus_scheduler.stop
        @rufus_scheduler.remove_all
        Teamwork::Client::Task::Collect::Base.clean_tasks
        Teamwork.task.children(self.class.task_path).each do |path|
          hash_task = Teamwork.task.get "#{self.class.task_path}/#{path}"
          opt = hash_task['opt']
          case opt
          when 'every'
            @rufus_scheduler.add path, timeout: hash_task['time'], every: hash_task['time'] do
              cls = Object.const_get(hash_task['cls'])
              cls.find(path).send hash_task['method'], hash_task['args']
            end
          # when 'cron'
          #  raise "unsupported type #{opt}"
          else
            raise "unsupported type #{opt}"
          end
        end
        @rufus_scheduler.start
      end
    end
  end
end
