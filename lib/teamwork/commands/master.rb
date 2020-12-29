
module Teamwork
  module Commands
    module Master
      class Start < CommandBase
        desc "start master  client"
        set_client_type "master"

        def call
          logger = Logger.new("#{Teamwork.gem_root}/log/master.log", 1, 1024000)
          logger.level = Logger::INFO
          Teamwork.logger = logger
          info
          can_start
          daemonize
          master = Teamwork::Client::Master.new
          master.join
        end
      end

      class Status < CommandBase
        desc "master client status"
        set_client_type "master"

        def call
          Teamwork.logger.level = Logger::INFO
          status
        end
      end

      class Stop < CommandBase
        desc "stop master client"
        set_client_type "master"
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
