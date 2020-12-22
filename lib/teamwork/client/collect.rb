module Teamwork
  module Client
    class Collect < Base
      set_client_path "/teamwork/client/collect"
      set_queue Teamwork::Utils.mac

      def initialize
        super
        @rufus_scheduler ||= Teamwork::Schedule::RufusTask.new
      end

      def monitor_task
      end

      def restart_task
        @rufus_scheduler.stop
        @rufus_scheduler.remove_all
        @rufus_scheduler.start
      end
    end
  end
end
