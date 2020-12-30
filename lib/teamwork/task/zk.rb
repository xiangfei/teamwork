# frozen_string_literal: true

require 'zk'

module Teamwork
  module Task
    # no doc
    class Zk
      attr_writer :zk

      def initialize(zk_opts = {})
        @zk_opts = zk_opts
      end

      def queue(name)
        Teamwork::Queue::Zk.new(zk, name)
      end

      def lock(name)
        Teamwork::Lock::Zk.new(zk, name)
      end

      def children(path)
        zk.children path
      end

      def create(path, value = '')
        zk.create path, value
      end

      def temp_create(path, value = '')
        zk.create path, value, mode: :ephemeral
      end

      def sequence_create(path)
        zk.create path, '', mode: :persistent_sequential
      end

      def set(path, value)
        zk.set path, value
      end

      def exists?(node)
        zk.exists? node
      end

      def get(path)
        s, = zk.get path
        JSON.parse(s)
      end

      def raw_get(path)
        s, = zk.get path
        s
      end

      def delete(node)
        zk.rm_rf node
      end

      def mkdir_p(node)
        zk.mkdir_p node
      end

      def watch_children(path)
        zk.children(path, watch: true)
        zk.register path do |event|
          if event.node_child?
            zk.children(path, watch: true)
            yield
          end
        end
      end

      def watch_create(path)
        zk.stat(path, watch: true)
        zk.register path do |event|
          if event.node_created?
            zk.stat(path, watch: true)
            yield
          end
        end
      end

      def watch_delete(path)
        zk.stat(path, watch: true)
        zk.register path do |event|
          if event.node_deleted?
            zk.stat(path, watch: true)
            yield
          end
        end
      end

      def watch_update(path)
        zk.stat(path, watch: true)
        zk.register path do |event|
          if event.node_changed?
            zk.stat(path, watch: true)
            yield
          end
        end
      end

      def zk
        @zk ||= begin
          ZK.new(@zk_opts['url'].join(',')).tap do |zk|
            username = @zk_opts['username']
            password = @zk_opts['password']
            zk.add_auth scheme: 'digest', cert: "#{username}:#{password}" if username
          end
        end
      end
    end
  end
end
