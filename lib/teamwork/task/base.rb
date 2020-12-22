module Teamwork
  module Task
    class Base
      def initialize
      end

      def queue(name)
        raise "abstract method"
      end

      def children(path)
        raise "abstract method"
      end

      def create(path)
        raise "abstract method"
      end

      def mkdir_p(path)
        raise "abstract method"
      end

      def temp_create(path)
        raise "abstract method"
      end

      def sequence_create(path)
        raise "abstract method"
      end

      def set(path, value)
        raise "abstract method"
      end

      def get(path)
        raise "abstract method"
      end

      def watch_children(path)
        raise "abstract method"
      end

      def watch_create(path)
        raise "abstract method"
      end

      def watch_delete(path)
        raise "abstract method"
      end

      def watch_update(path)
        raise "abstract method"
      end
    end
  end
end
