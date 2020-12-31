# frozen_string_literal: true

module Teamwork
  module Module
    # no doc
    module Validator
      def self.included(base)
        base.extend VClassMethods
      end

      # 检查 ,type , required , :cls
      def valid
        self.class.validate_attributes.each do |name, opts|
          # 通过 send 方法获取,如果不存在返回nil , 简单处理, 如果需要可以扩展
          v = begin
            send name
          rescue StandardError
            nil
          end
          if opts[:required] && !v
            errors << "#{name} cannot be null"
          end
          next unless opts[:cls]

          # puts name, opts
          if v.class != opts[:cls]
            errors << "#{name} cls check failed real #{v.class} expect #{opts[:cls]}"
          end
        end
        success?
      end

      def errors
        @errors ||= []
      end

      def success?
        errors.empty?
      end

      # no doc
      module VClassMethods
        def validate(name, opts = {})
          validate_attributes << [name, opts]
        end

        def validate_attributes
          @validate_attributes ||= []
        end
      end
    end
  end
end
