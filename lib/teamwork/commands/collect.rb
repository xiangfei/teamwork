# frozen_string_literal: true

module Teamwork
  module Commands
    module Collect
      # no doc
      class Start < CommandBase
        desc 'start collect  client (every node can only start one )'
        set_client_type 'collect'

        def call
          logger = Logger.new("#{Teamwork.gem_root}/log/collect.log", 1, 1_024_000)
          logger.level = Logger::INFO
          Teamwork.logger = logger
          info
          can_start
          daemonize
          collect = Teamwork::Client::Collect.new
          collect.join
        end
      end

      # no doc
      class Status < CommandBase
        desc 'collect client status'
        set_client_type 'collect'

        def call
          Teamwork.logger.level = Logger::INFO
          status
        end
      end

      # no doc
      class Stop < CommandBase
        desc 'stop collect client'
        set_client_type 'collect'

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
