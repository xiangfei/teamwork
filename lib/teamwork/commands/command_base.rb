# frozen_string_literal: true

require 'dry/cli'

module Teamwork
  # no doc
  module Commands
    extend Dry::CLI::Registry
    # no doc
    class CommandBase < Dry::CLI::Command
      desc 'command base '
      class << self
        attr_reader :type

        def pid_base
          @pid_base ||= "#{Teamwork.gem_root}/pids"
        end

        def set_client_type(type)
          @type = type
        end
      end

      def call
        raise 'abstract method'
      end

      def info
        puts "teamwork version:  #{Teamwork::VERSION}"
        puts "ruby version:  #{RUBY_VERSION}"
        puts "ruby platform:  #{RUBY_PLATFORM}"
      end

      def daemonize
        ::Process.daemon(true)
        File.open(
          "#{self.class.pid_base}/#{self.class.type}",
          'w'
        ) { |file| file.write(::Process.pid) }
      end

      def can_start
        return true if find_process.empty?

        puts "already started  pid list #{find_process}"
        # exit 1
        Process.kill('TERM', ::Process.pid)
      end

      def status
        pid = read_pid
        if find_process.count > 1
          puts "find more than one process #{find_process}, not know how to handle  exit "
          exit
        end

        if find_process.count < 1
          puts "#{self.class.type} not started"
          exit
        end
        if pid == find_process[0]
          puts "#{self.class.type} current running: pid is #{find_process[0]} "
          exit
        else
          puts "#{self.class.type} current running: pid is #{find_process[0]}"
          puts " not run with command teamwork #{self.class.type} start"
        end
      end

      def clear_pid_file
        File.delete(pid_file)
      rescue StandardError
        nil
      end

      def read_pid
        File.read(pid_file).to_i
      rescue StandardError
        nil
      end

      def pid_file
        "#{self.class.pid_base}/#{self.class.type}"
      end

      def find_process
        list = []
        st, value = Teamwork::Utils.old_linux_command("ps aux | grep #{self.class.type} | grep teamwork | grep -v grep")
        unless st
          Teamwork.logger.error("find process failed  #{value}")
          return list
        end
        value.each_line do |line|
          list << line.split[1].to_i
        end
        list.reject { |x| x == Process.pid }
      end
    end
  end
end
