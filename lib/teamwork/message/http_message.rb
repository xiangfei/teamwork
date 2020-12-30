# frozen_string_literal: true

module Teamwork
  module Message
    # no doc
    class HttpMessage < BaseMessage
      def initialize(http_url)
        @http_url = http_url
      end

      def deliver_message(json_message, topic:)
        # kafka.deliver_message json_message.to_json, topic: topic, partition_key: Teamwork::Utils.mac
        Teamwork.logger.info "deliver http message success #{json_message} , topic #{topic}"
      end

      private

      def http
        @http_url.sample
      end
    end
  end
end
