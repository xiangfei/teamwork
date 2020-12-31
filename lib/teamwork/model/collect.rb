# frozen_string_literal: true

module Teamwork
  module Model
    # collect model
    class Collect < Base
      teamwork_accessor :task_id
      teamwork_accessor :type
      teamwork_accessor :monitor_name
      teamwork_accessor :meta, default: {}
      teamwork_accessor :result, default: {}

      validate :type, required: true, cls: Hash

      before_method :xx, :yy

      def xx
        puts 'xx'
      end

      def yy
        puts 'yy'
      end
    end
  end
end
