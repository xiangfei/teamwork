require "kafka"

module Teamwork
  module Consumer
    class Kafka
      def initialize(kafka_url)
        @kafka = ::Kafka.new(kafka_url)
      end

      def add_monitor(topic, group = nil, &block)
        mon = find_monitor topic
        if mon
          Teamwork.logger.error "topic #{topic} already exist , needs delete it first"
        else
          monitor_list << [topic, group, block]
        end
      end

      def remove_monitor(topic)
        stop_monitor topic
        monitor_list.reject! do |monitor|
          monitor[0] == topic
        end
      end

      def stop_monitor(topic)
        cm = monitor_hash[topic]
        if cm
          cm.stop
        else
          Teamwork.logger.warn "monitor #{topic} already stopped"
        end
      end

      def find_monitor(topic)
        mon = monitor_list.find do |monitor| monitor[0] == topic end
      end

      def start_monitor(topic)
        mon = find_monitor topic
        if mon
          topic, group, block = mon
          monitor topic, group, &block
        else
          Teamwork.logger.error "topic #{topic} not added"
        end
      end

      def stop_all_monitor
        monitor_hash.each do |_, cm|
          cm.stop
        end
      end

      def start_all_monitor
        monitor_list.each do |topic, group, block|
          monitor topic, group, &block
        end
      end

      private

      # use async monitor
      def monitor(topic, group = nil, &block)
        Thread.new do
          begin
            group_id = group ? group : "#{topic}.group"
            Teamwork.logger.info "监控#{topic} group:#{group_id}"
            cm = @kafka.consumer(group_id: "#{group_id}", offset_commit_interval: 5, offset_commit_threshold: 100, offset_retention_time: 7 * 60 * 60)
            cm.subscribe(topic)
            monitor_hash[topic] = cm
            #  cm.each_message do |message|
            #    #cm.mark_message_as_processed(message)
            #    #cm.commit_offsets
            #    block.call message if block_given?
            #    cm.mark_message_as_processed(message)
            #    cm.commit_offsets
            #  end
            cm.each_batch do |batch|
              batch.messages.each do |message|
                block.call message if block_given?
              end
            end
          rescue StandardError => e
            Teamwork.logger.error "monitor topic failed #{topic} , sleep 10 and try monitor again #{e} "
            sleep 10
            retry
          end
        end
      end

      def monitor_list
        @montior_list ||= []
      end

      def monitor_hash
        @monitor_hash ||= {}
      end

      def producer
        #@producer ||= Teamwork.kafka.producer(max_retries: 5, retry_backoff: 5)
        @producer ||= Teamwork.kafka.async_producer(delivery_threshold: 100, delivery_interval: 5)
      end

      def synchronized
        mutex.synchronize do
          yield
        end
      end

      def mutex
        @mutex ||= Mutex.new
      end
    end
  end
end
