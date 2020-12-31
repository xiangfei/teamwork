# frozen_string_literal: true

module Teamwork
  module Model
    # no doc
    class Base
      # add default value
      include ::Teamwork::Module::Accessor
      include ::Teamwork::Module::Validator
      include ::Teamwork::Module::Callback
      class << self
        def from_json(opts = {})
          new opts
        end

        def find(taskid)
          opts = Teamwork.cache.get taskid
          new opts
        end

        def inherited(base)
          base.send :teamwork_accessor, :time, callback: :set_time
          base.send :teamwork_accessor, :mac, default: ::Teamwork::Utils.mac
          base.send :teamwork_accessor, :ip, default: ::Teamwork::Utils.ip
          base.send :teamwork_accessor, :hostname, default: ::Teamwork::Utils.hostname
        end
      end

      def initialize(opts = {})
        raise 'abstact class cannot init' if instance_of?(::Teamwork::Model::Base)

        opts = JSON.parse opts.to_json
        attributes.each do |attr|
          send "#{attr}=", opts[attr.to_s]
        end
      end

      def as_json
        map = {}
        attributes.map do |attr|
          map[attr] = send(attr.to_s)
        end
        map
      end

      def attributes
        self.class.attributes
      end

      private

      def set_time
        Time.now.to_i
      end
    end
  end
end
