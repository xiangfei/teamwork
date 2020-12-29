module Teamwork
  module Commands
    module Notify
      class Start < CommandBase
        desc "start notify  client"
        set_client_type "notify"

        def call
          logger = Logger.new("#{Teamwork.gem_root}/log/notify.log", 1, 1024000)
          logger.level = Logger::INFO
          Teamwork.logger = logger
          info
          can_start
          daemonize
          notify = Teamwork::Client::Notify.new
          notify.join
        end
      end

      class Status < CommandBase
        desc "notify client status"
        set_client_type "notify"

        def call
          Teamwork.logger.level = Logger::INFO
          status
        end
      end

      class Stop < CommandBase
        desc "stop notify client"
        set_client_type "notify"
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
