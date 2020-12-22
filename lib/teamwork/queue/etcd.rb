module Teamwork
  module Queue
    class Etcd
      def initialize(zk, queue_name, queue_root = "/_zkqueues")
        @zk = zk
        @queue = queue_name
        @queue_root = queue_root
        @zk.create(@queue_root, "", mode: :persistent) unless @zk.exists?(@queue_root)
        @zk.create(full_queue_path, "", mode: :persistent) unless @zk.exists?(full_queue_path)
      end

      def push(data)
        @zk.create("#{full_queue_path}/message", data, mode: :persistent_sequential)
      rescue ZK::Exceptions::NodeExists
        Teamwork.logger.error "push message to queue failed"
        false
      end

      def messages
        @zk.children(full_queue_path).sort! { |a, b| digit_from_path(a) <=> digit_from_path(b) }
      end

      def pull
        result = find_and_process_next_available(@zk.children(full_queue_path))
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
            if block_given?
              #Teamwork.logger.info "start handle title #{message_title}"
              block.call(message_title, data)
              #Teamwork.logger.info "end handle title #{message_title}"
            else
              return [message_title, data]
            end
          rescue
            Teamwork.logger.error "handle title #{message_title}  error"
          ensure
            @zk.delete(message_path) rescue nil  # 处理完成,删除queue
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
