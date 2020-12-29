module Teamwork
  module Lock
    class Zk
      attr_reader :locker

      def initialize(zk , key)
        @locker = zk.locker key
      end

      def lock
        @locker.lock
      end

      def unlock
        @locker.unlock
      end

      def locked?
        @locker.locked?
      end
    end
  end
end
