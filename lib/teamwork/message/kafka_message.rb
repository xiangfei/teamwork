# frozen_string_literal: true

require 'kafka'

module Teamwork
  module Message
    # no doc
    class KafkaMessage < BaseMessage
      def initialize(kafka_url)
        @kafka_url = kafka_url
      end

      # async producer  , may lost data
      def deliver_message(json_message, topic:)
        producer.produce json_message.to_json, topic: topic, partition_key: Teamwork::Utils.mac
        Teamwork.logger.info "deliver kafka message success #{json_message} , topic #{topic}"
      end

      private

      def kafka
        @kafka ||= ::Kafka.new(@kafka_url)
      end

      def producer
        # @producer ||= Teamwork.kafka.producer(max_retries: 5, retry_backoff: 5)
        @producer ||= kafka.async_producer(delivery_threshold: 100, delivery_interval: 5)
      end
    end
  end
end
