module Teamwork
  module Client
    class Agent < Base
      class << self

        def create_agent_task(taskid, opts = {})
          unless Teamwork.task.exists? "#{task_path}/#{taskid}"
            create_task  taskid, opts
          end
        end
      end

      set_client_path "/teamwork/client/agent"
      set_task_path "/teamwork/task/agent"

      create_agent_task "r_cpu_usage", { :time => 240, :opt => "every", :method => "run", :cls => "Teamwork::Client::Agent::CpuUsage", :args => {} }

      def initialize
        super
        @rufus_scheduler ||= Teamwork::Schedule::RufusTask.new
        fetch_and_restart_scheduler
        monitor_agent_task
      end

      def monitor_agent_task
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
