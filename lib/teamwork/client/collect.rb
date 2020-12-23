module Teamwork
  module Client
    class Collect < Base
      class << self
        def create_collect_task(taskid, opts = {})
          unless Teamwork.task.exists? "#{task_path}/#{taskid}"
            create_task taskid, opts
          end
        end
      end

      set_client_path "/teamwork/client/collect"
      set_queue Teamwork::Utils.mac
      set_task_path "/teamwork/task/collect/#{Teamwork::Utils.mac}"

      create_collect_task Teamwork::Client::Task::Collect::CpuUsage.task_id, { :time => 20, :opt => "every", :method => "run", :cls => "Teamwork::Client::Task::Collect::CpuUsage", :args => {} }

      def initialize
        super
        @rufus_scheduler ||= Teamwork::Schedule::RufusTask.new
        fetch_and_restart_scheduler
        monitor_collect_task
        monitor_queue_task
      end

      def monitor_queue_task
        self.class.queue.consume do |title, value|
          begin
            Teamwork.logger.debug "start handler collect  once task #{title}  #{value}"
            hash_task = JSON.load value
            cls = eval(hash_task["cls"])
            timeout = hash_task["timeout"] || 600
            Timeout.timeout timeout do
              cls.s.send hash_task["method"], hash_task["args"]
            end
            Teamwork.logger.debug "start handler  once task #{title}  #{value}"
          rescue => e
            Teamwork.logger.error "处理任务失败 #{title} #{value} error message #{e.message}"
          end
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
        Teamwork.task.children(self.class.task_path).each do |path|
          hash_task = Teamwork.task.get "#{self.class.task_path}/#{path}"
          opt = hash_task["opt"]
          case opt
          when "every"
            @rufus_scheduler.add path, timeout: hash_task["time"], every: hash_task["time"] do
              cls = eval(hash_task["cls"])
              cls.s.send hash_task["method"], hash_task["args"]
            end
          when "cron"
            raise "unsupported type #{opt}"
          else
            raise "unsupported type #{opt}"
          end
        end
        @rufus_scheduler.start
      end
    end
  end
end
