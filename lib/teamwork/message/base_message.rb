# frozen_string_literal: true

module Teamwork
  module Message
    # no doc
    class BaseMessage
      def deliver_message(_json_message, topic:)
        puts  topic
        raise 'abstract method'
      end

      def deliver_error_messages; end
    end
  end
end
