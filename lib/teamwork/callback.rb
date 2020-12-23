module Teamwork
  module Callback
    def self.included(base)
      base.extend(ClassMethods)
    end


    module ClassMethods

      
      def before_method(method_name, options = {})
        aop_methods = Array(options[:only]).compact
        return if aop_methods.empty?
        aop_methods.each do |m|
          alias_method "#{m}_old", m

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{m}
            #{method_name}
            #{m}_old
          end
        RUBY
        end
      end
    end
  end
end
