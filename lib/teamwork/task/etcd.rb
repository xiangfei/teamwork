require "etcdv3"

module Teamwork
  module Task
    class Etcd
      attr_writer :etcd

      def initialize(etcd_opts = {})
        @etcd_opts = etcd_opts
        @temp_hash = {}
        monitor_temp_hash
      end

      def queue(name)
        Teamwork::Queue::Etcd.new(zk, name)
      end

      def children(path)
        etcd.children path
      end

      def create(path, value = "")
        etcd.put path, value
      end

      def temp_create(path, value = "")
        temp_hash[path] = value
        etcd.put(path, value, lease: 10)
      end

      def sequence_create(path)
        etcd.put path, "", mode: :persistent_sequential
      end

      def set(path, value)
        etcd.put path, value
      end

      def exists?(node)
        if get(node)
          true
        else
          false
        end
      end

      def get(path)
        etcd.get(path).kvs.first.value
      rescue
        nil
      end

      def delete(node)
        etcd.del node
        temp_hash.delete node rescue nil
      end

      def mkdir_p(node)
        etcd.put node , ""
      end

      def watch_children(path)
        etcd.children(path, :watch => true)
        etcd.register path do |event|
          if event.node_child?
            etcd.children(path, :watch => true)
            yield
          end
        end
      end

      def watch_create(path)
        etcd.stat(path, :watch => true)
        etcd.register path do |event|
          if event.node_created?
            etcd.stat(path, :watch => true)
            yield
          end
        end
      end

      def watch_delete(path)
        etcd.stat(path, :watch => true)
        etcd.register path do |event|
          if event.node_deleted?
            etcd.stat(path, :watch => true)
            yield
          end
        end
      end

      def watch_update(path)
        etcd.stat(path, :watch => true)
        etcd.register path do |event|
          if event.node_changed?
            etcd.stat(path, :watch => true)
            yield
          end
        end
      end

      def etcd
        @etcd ||= begin
            username = @etcd_opts["username"]
            password = @etcd_opts["password"]
            if username
              Etcdv3.new(endpoints: @etcd_opts["url"].join(","), user: username, password: password)
            else
              Etcdv3.new(endpoints: @etcd_opts["url"].join(","))
            end
          end
      end

      def temp_hash
        @temp_hash
      end

      def monitor_temp_hash
        Thread.new do
          temp_hash.each do |k, v|
            temp_create k, v
          end
          sleep 5
        end
      end
    end
  end
end
