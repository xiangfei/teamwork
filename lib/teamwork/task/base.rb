# frozen_string_literal: true

module Teamwork
  module Task
    # base abstract class
    class Base
      def initialize; end

      def queue(_name)
        raise 'abstract method'
      end

      def children(_path)
        raise 'abstract method'
      end

      def create(_path)
        raise 'abstract method'
      end

      def mkdir_p(_path)
        raise 'abstract method'
      end

      def temp_create(_path)
        raise 'abstract method'
      end

      def sequence_create(_path)
        raise 'abstract method'
      end

      def set(_path, _value)
        raise 'abstract method'
      end

      def get(_path)
        raise 'abstract method'
      end

      def watch_children(_path)
        raise 'abstract method'
      end

      def watch_create(_path)
        raise 'abstract method'
      end

      def watch_delete(_path)
        raise 'abstract method'
      end

      def watch_update(_path)
        raise 'abstract method'
      end
    end
  end
end
