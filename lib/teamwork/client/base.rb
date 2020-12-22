module Teamwork
  module Client
    class Base
      class << self
        attr_reader :_client_path, :_task_queue, :_task_path, :_config_path, :_config

        def set_queue(queue)
          @_task_queue ||= Teamwork.task.queue(queue)
        end

        def set_task_path(path)
          @_task_path ||= begin
              Teamwork.task.mkdir_p path
              path
            end
        end

        def set_config_path(path)
          @_config_path ||= begin
              Teamwork.task.mkdir_p path
              path
            end
        end

        def set_client_path(path)
          @_client_path ||= begin
              Teamwork.task.mkdir_p path
              path
            end
        end

        def create_and_watch_config(opts = {})
          if Teamwork.task.exists? config_path
            t = Teamwork.task.get config_path
            unless t
              create_config opts
            end
          else
            create_config opts
          end
          watch_config
          @_config = Teamwork.task.get(config_path)
        end

        def queue
          raise "not define queue" unless defined? @_task_queue
          @_task_queue
        end

        def client_path
          raise "not define client path" unless defined? @_client_path
          @_client_path
        end

        def task_path
          raise "not define task path" unless defined? @_task_path
          @_task_path
        end

        def config_path
          raise "not define config path" unless defined? @_config_path
          @_config_path
        end

        def config
          raise "not define config " unless defined? @_config
          @_config
        end

        def client_id
          raise "not define client path" unless defined? @_client_path
          @client_id ||= "#{@_client_path}/#{Teamwork::Utils.mac}"
        end

        private

        def create_task(task_id, opts = {})
          full_path = "#{task_path}/#{task_id}"
          if Teamwork.task.exists? full_path
            Teamwork.task.delete full_path
          end
          Teamwork.task.create full_path, opts.to_json
        end

        def create_config(opts = {})
          if Teamwork.task.exists? config_path
            Teamwork.task.delete config_path
          end
          Teamwork.task.create config_path, opts.to_json
        end

        def watch_config
          Teamwork.task.watch_update config_path do
            @_config = Teamwork.task.get(config_path)
          end
        end
      end

      def initialize
        raise "abstract class cannot initialize" if self.class == Teamwork::Client::Base
        @register = false
        @running = true
        register
        listen_stop
      end

      def register
        begin
          Teamwork.task.temp_create(self.class.client_id)
          @register = true
          Teamwork.logger.info "NODE: #{self.class.client_id} 注册成功. "
        rescue => e
          Teamwork.logger.error "NODE: #{self.class.client_id} 注册失败. #{e.message}"
          client_stop
          @register = false
        end
      end

      def listen_stop
        Teamwork.task.watch_delete self.class.client_id do
          Teamwork.logger.info "client #{self.class.client_id}  被踢下线"
          client_stop
        end
      end

      def client_stop
        @running = false
      end

      def join
        Thread.new do
          while @running
            sleep 300
            GC.start
          end
        end
        while @running
          sleep 1
        end
      end
    end
  end
end
