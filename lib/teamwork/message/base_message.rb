module Teamwork
  module Message
    class BaseMessage
      def deliver_message(json_message, topic:)
        raise "abstract method"
      end

      def deliver_error_messages
      end
    end
  end
end
