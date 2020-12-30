# frozen_string_literal: true

module Teamwork
  module Client
    # no doc
    class Alarm < Base
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

      set_client_path '/teamwork/client/alarm'

      set_config_path '/teamwork/config/alarm'

      set_task_path "/teamwork/task/alarm/#{Teamwork::Utils.mac}"

      create_and_watch_default_config first: [1, 2, 3], repeat: 10

      # 只做收集任务
      def initialize
        @rufus_scheduler = Teamwork::Schedule::RufusTask.new
        start_timer
        monitor_alarm_task
      end

      def start_timer
        Teamwork.logger.info 'start alarm client'
        fetch_and_restart_scheduler
      rescue StandardError => e
        Teamwork.logger.error "error:#{self.class}.#{__method__} --> #{e.message}"
      end

      def monitor_alarm_task
        Teamwork.task.watch_children self.class.config_path do
          fetch_and_restart_scheduler
        end
      end

      # 监听操作太快可能丢失数据
      def fetch_and_restart_scheduler
        @rufus_scheduler.stop
        @rufus_scheduler.remove_all
        # sleep 5
        Teamwork.task.children(self.class.task_path).each do |path|
          hash_task = Teamwork.task.get "#{self.class.task_path}/#{path}"
          type = hash_task['type']
          case type
          when 'every'
            @rufus_scheduler.add path, timeout: hash_task['timeout'], every: hash_task['value'] do
              cls = Object.const_get(hash_task['cls'])
              cls.s.send hash_task['method'], hash_task['args']
            end
          when 'cron'
            @rufus_scheduler.add path, timeout: hash_task['timeout'], cron: hash_task['value'] do
              cls = Object.const_get(hash_task['cls'])
              cls.s.send hash_task['method'], hash_task['args']
            end
          else
            raise "unsupported type #{type}"
          end
        end
        @rufus_scheduler.start
      end
    end
  end
end
