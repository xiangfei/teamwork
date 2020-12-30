# frozen_string_literal: true

module Teamwork
  module Lock
    #no doc
    class Etcd
      attr_reader :locker

      def initialize(key, zk: Teamwork.zookeeper)
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
