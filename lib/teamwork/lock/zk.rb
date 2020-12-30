# frozen_string_literal: true

module Teamwork
  module Lock
    # no doc
    class Zk
      attr_reader :locker

      def initialize(zookeeper, key)
        @locker = zookeeper.locker key
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
