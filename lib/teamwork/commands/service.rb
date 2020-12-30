# frozen_string_literal: true

module Teamwork
  module Commands
    module Service
      # no doc
      class Start < CommandBase
        desc 'start service  client '
        set_client_type 'service'

        def call
          logger = Logger.new("#{Teamwork.gem_root}/log/service.log", 1, 1_024_000)
          logger.level = Logger::INFO
          Teamwork.logger = logger
          info
          can_start
          daemonize
          service = Teamwork::Client::Service.new
          service.join
        end
      end

      # no doc
      class Status < CommandBase
        desc 'service client status'
        set_client_type 'service'

        def call
          Teamwork.logger.level = Logger::INFO
          status
        end
      end

      # no doc
      class Stop < CommandBase
        desc 'stop service client'
        set_client_type 'service'

        def call
          Teamwork.logger.level = Logger::INFO
          find_process.each do |pid|
            Process.kill('TERM', pid)
          end
          clear_pid_file
        end
      end
    end
  end
end
