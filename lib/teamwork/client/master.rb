module Teamwork
  module Client
    # service   once task  generator
    class Master < Base
      set_client_path "/teamwork/client/master"

      set_task_path "/teamwork/task/master"

      set_queue "service"

      class << self
        def create_master_task(taskid, opts = {})
          unless Teamwork.task.exists? "#{task_path}/#{taskid}"
            create_task taskid, opts
          end
        end
      end

      def initialize
        super
        @rufus_scheduler ||= Teamwork::Schedule::RufusLockTask.new key: "service"
        start_master
      end

      def start_master
        watch_master_task_path
        handler_master_task_path
      end

      def watch_master_task_path
        Teamwork.task.watch_children self.class.task_path do
          handler_schedule_task_path
        end
      end

      def handler_master_task_path
        @rufus_scheduler.stop
        @rufus_scheduler.remove_all
        Teamwork.task.children(self.class.task_path).each do |path|
          hash_task = Teamwork.task.get "#{self.class.task_path}/#{path}"
          begin
            hash_task = Teamwork.task.get "#{self.class.task_path}/#{path}"
            type = hash_task["type"]
            hash_task["timeout"] ||= 600
            case type
            when "every"
              @rufus_scheduler.add path, timeout: hash_task["timeout"], every: hash_task["value"] do
                qvalue = { cls: hash_task["cls"], args: hash_task["args"], method: hash_task["method"], timeout: hash_task["timeout"] }.to_json
                Teamwork.logger.info "create every task succes #{qvalue}"
                self.class.queue.push qvalue
              end
            when "cron"
              @rufus_scheduler.add path, timeout: hash_task["timeout"], cron: hash_task["value"] do
                qvalue = { cls: hash_task["cls"], args: hash_task["args"], method: hash_task["method"], timeout: hash_task["timeout"] }.to_json
                Teamwork.logger.info "create cron  task success #{qvalue}"
                self.class.queue.push qvalue
              end
            else
              raise "unsupported type #{type}"
            end
          rescue => e
            Teamwork.logger.error "start task failed #{task}  #{e}"
          end
        end
        @rufus_scheduler.add "sync_master", timeout: 3, every: 5 do
          set_master
        end

        @rufus_scheduler.start
      end

      def set_master
        begin
          Teamwork.task.set(self.class.client_path, "#{Teamwork::Utils.mac}")
          Teamwork.logger.info "MASTER: #{Teamwork::Utils.mac} standby: #{standby}"
        rescue Exception => e
          Teamwork.logger.info "MASTER: #{Teamwork::Utils.mac} can not get master. #{e.message}"
        end
      end

      def standby
        Teamwork.task.children(self.class.client_path).select do |x| x != current  end
      end

      def current
        Teamwork.task.raw_get(self.class.client_path)
      end
    end
  end
end
