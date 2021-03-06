# frozen_string_literal: true

module Teamwork
  module Client
    # no doc
    class Notify < Base
      set_client_path '/teamwork/client/notify'
      set_config_path '/teamwork/config/notify'
      create_and_watch_default_config[]

      def initialize
        super
        @notify_topic = 'teamwork.notify'
        start_consumer
      end

      def start_consumer
        Teamwork.consumer.add_monitor @notify_topic, 'teamwork_notify' do |message|
          value = JSON.parse message.value
          Teamwork.logger.info value
          send_mail_notify value
        rescue StandardError => e
          Teamwork.logger.error "consumer message  #{message.value} failed #{e.message}"
        end
        Teamwork.consumer.start_monitor @notify_topic
      end

      def send_mail_notify(value)
        Teamwork::Notify::Mail.send_mail(value)
      end
    end
  end
end
