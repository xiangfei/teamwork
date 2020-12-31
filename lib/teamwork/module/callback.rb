# frozen_string_literal: true

module Teamwork
  module Module
    # no doc  ,  目前只支持 无参方法 , 方法一个 , 最简单的逻辑处理 , 多个method
    # class A
    #  include Teamwork::Module::Callback
    #  before_method :xx , :yy
    #  def xx
    #    puts "xxxx"
    #  end
    #  def yy
    #    puts "yyyy"
    #  end
    # end
    module Callback
      def self.included(base)
        base.extend ClassMethod
      end

      # no doc
      module ClassMethod
        def before_method(method, prefix_method) 

          before_callback_methods(method) << prefix_method
        end

        def after_method(method, after_method)
          after_callback_methods(method) << after_method
        end

        def method_added(meth)
          return unless callback_method? meth

          refine_method(meth) unless refined?
        end

        def refine_method(meth)
          puts "method #{meth} refined"
          puts  "#{before_callback_methods(meth)} before"
          puts  "#{after_callback_methods(meth)} after"
          @refined = true
          original = instance_method(meth)
          remove_method(meth)
          define_method meth do
            puts "#{self.class.before_callback_methods(meth)} instance"
            self.class.before_callback_methods(meth).each do |m|
              send m
            end
            result = original&.bind(self)&.call
            self.class.after_callback_methods(meth).each do |m|
              send m
            end
            result
          end
          @refined = false
        end

        def before_callback_methods(before)
          callbacks[:before][before] ||= []
        end

        def after_callback_methods(after)
          callbacks[:after][after] ||= []
        end

        def callback_method?(meth)
          if before_callback_methods(meth).empty? && after_callback_methods(meth).empty?
            false
          else
            true
          end
        end

        def callbacks
          @callbacks ||= { before: {}, after: {} }
        end

        def refined?
          @refined ||= false
        end
      end
    end
  end
end
