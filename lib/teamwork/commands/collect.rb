
module Teamwork
  module Commands
    module Collect
      class Start < CommandBase
        desc "start collect  client (every node can only start one )"
        set_client_type "collect"

        def call
          logger = Logger.new("#{Teamwork.gem_root}/log/collect.log", 1, 1024000)
          logger.level = Logger::INFO
          Teamwork.logger = logger
          info
          can_start
          daemonize
          collect = Teamwork::Client::Collect.new
          collect.join
        end
      end

      class Status < CommandBase
        desc "collect client status"
        set_client_type "collect"

        def call
          Teamwork.logger.level = Logger::INFO
          status
        end
      end

      class Stop < CommandBase
        desc "stop collect client"
        set_client_type "collect"

        def call
          Teamwork.logger.level = Logger::INFO
          find_process.each do |pid|
            Process.kill("TERM", pid)
          end
          clear_pid_file
        end
      end
    end
  end
end
