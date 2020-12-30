# frozen_string_literal: true

module Teamwork
  module Queue
    # no doc
    class Zk
      def initialize(zookeeper, queue_name, queue_root = '/_zkqueues')
        @zk = zookeeper
        @queue = queue_name
        @queue_root = queue_root
        @zk.create(@queue_root, '', mode: :persistent) unless @zk.exists?(@queue_root)
        @zk.create(full_queue_path, '', mode: :persistent) unless @zk.exists?(full_queue_path)
      end

      def push(data)
        @zk.create("#{full_queue_path}/message", data, mode: :persistent_sequential)
      rescue ZK::Exceptions::NodeExists
        Teamwork.logger.error 'push message to queue failed'
        false
      end

      def messages
        @zk.children(full_queue_path).sort! { |a, b| digit_from_path(a) <=> digit_from_path(b) }
      end

      def pull
        find_and_process_next_available(@zk.children(full_queue_path))
      end

      def consume(&block)
        @consumer = @zk.register(full_queue_path) do |_event, _zk|
          find_and_process_next_available(@zk.children(full_queue_path, watch: true), &block)
        end
        find_and_process_next_available(@zk.children(full_queue_path, watch: true), &block)
      end

      private

      def find_and_process_next_available(messages, &block)
        messages.each do |message_title|
          message_path = "#{full_queue_path}/#{message_title}"
          locker = @zk.locker(message_path)
          next unless locker.lock!

          begin
            data = @zk.get(message_path).first
            return [message_title, data] unless block_given?

            block.call(message_title, data)
          rescue StandardError
            Teamwork.logger.error "handle title #{message_title}  error"
          ensure
            begin
              @zk.delete(message_path)
            rescue StandardError
              nil
            end
            locker.unlock!
          end
        end
      end

      def full_queue_path
        @full_queue_path ||= "#{@queue_root}/#{@queue}"
      end

      def digit_from_path(path)
        path[/\d+$/].to_i
      end
    end
  end
end
