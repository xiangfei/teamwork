# frozen_string_literal: true

module Teamwork
  # no doc
  module Callback
    def self.included(base)
      base.extend ClassMethods
      base.initialize_included_features
    end

    # no doc
    module ClassMethods
      def initialize_included_features
        @callbacks = {}
        %i[before after around].each { |filter| @callbacks[filter] = Hash.new { |h, k| h[k] = [] } }

        class << self
          attr_accessor :callbacks, :setting_callback
        end
      end

      def a_callback?(method)
        registered_methods.include?(method)
      end

      def registered_methods
        callbacks.values.map(&:keys).flatten.uniq
      end

      def store_callbacks(type, method_name, *callback_methods)
        callbacks[type.to_sym][method_name.to_sym].add_and_link(callback_methods.flatten.map(&:to_sym))
      end

      def process_callback_set(type, original_method, *callbacks)
        Array(original_method).each { |method| store_callbacks(type, method, *callbacks) }
      end

      def before(original_method, *callbacks)
        process_callback_set(:before, original_method, *callbacks)
      end

      def after(original_method, *callbacks)
        process_callback_set(:after, original_method, *callbacks)
      end

      def around(original_method, *callbacks)
        process_callback_set(:around, original_method, *callbacks)
      end

      def method_added(method)
        redefine_method(method) unless setting_callback && a_callback?(method) 
      end

      def objectify_and_remove_method(method)
        return unless method_defined?(method.to_sym)

        original = instance_method(method.to_sym)
        remove_method(method.to_sym)
        original
      end

      def redefine_method(original_method)
        original = objectify_and_remove_method(original_method)
        @setting_callback = true

        define_method(original_method.to_sym) do |*args, &block|
          trigger_callbacks(original_method, :before)
          return_value = trigger_around_callbacks(self.class.callbacks[:around][original_method.to_sym].first) do
            original&.bind(self)&.call(*args, &block)
          end
          trigger_callbacks(original_method, :after)
          return_value
        end

        @setting_callback = false
      end
    end

    def trigger_callbacks(method_name, callback_type)
      self.class.callbacks[callback_type][method_name.to_sym].each { |callback| send callback }
    end

    def trigger_around_callbacks(callback_method, &block)
      return block.call unless callback_method # there's no around callbacks, just call the original method

      if callback_method.next
        # outer around callbacks recurse until there's no more 'next'
        send(callback_method) { trigger_around_callbacks(callback_method.next) { block.call } }
      else
        # this is the innermost around callback which will call the original filtered method in the given block
        send(callback_method) { block.call }
      end
    end
  end
end
