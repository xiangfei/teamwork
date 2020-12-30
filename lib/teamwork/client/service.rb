# frozen_string_literal: true

module Teamwork
  module Client
    # 抢占任务
    class Service < Base
      set_client_path '/teamwork/client/service'
      set_queue 'service'

      def initialize
        super
        @rufus_scheduler ||= Teamwork::Schedule::RufusTask.new
        monitor_queue_task
      end

      def monitor_queue_task
        self.class.queue.consume do |title, value|
          Teamwork.logger.debug "start handler service task #{title}  #{value}"
          hash_task = JSON.parse value
          cls = Object.const_get(hash_task['cls'])
          timeout = hash_task['timeout'] || 600
          Timeout.timeout timeout do
            cls.s.send hash_task['method'], hash_task['args']
          end
          Teamwork.logger.debug "start handler  service task #{title}  success"
        rescue StandardError => e
          Teamwork.logger.error "处理任务失败 #{title} #{value} error message #{e.message}"
        end
      end
    end
  end
end
