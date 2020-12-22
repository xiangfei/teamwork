require "kafka"

module Teamwork
  module Message
    class KafkaMessage < BaseMessage
      def initialize(kafka_url)
        @kafka_url = kafka_url
      end

      def deliver_message(json_message, topic:)
        i = 0
        begin
          kafka.deliver_message json_message.to_json, topic: topic, partition_key: Teamwork::Utils.mac
          Teamwork.logger.info "deliver kafka message success #{json_message} , topic #{topic}"
        rescue
          while i < 3
            i = i + 1
            retry
          end
        end
      end

      private

      def kafka
        @kafka ||= ::Kafka.new(@kafka_url)
      end
    end
  end
end
