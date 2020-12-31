# frozen_string_literal: true

module Teamwork
  module Module
    # no doc
    module Accessor
      def self.included(base)
        base.extend AClassMethods
      end

      # no doc
      module AClassMethods
        def teamwork_accessor(name, opts = {})
          attributes << name
          define_method name do
            name ||= if opts[:default]
                       opts[:default]
                     elsif opts[:callback]
                       send opts[:callback]
                     end
          end
          define_method "#{name}=" do |v|
            name = v
          end
        end

        def attributes
          @accessor_attributes ||= []
        end
      end
    end
  end
end
