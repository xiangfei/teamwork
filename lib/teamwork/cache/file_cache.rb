require 'digest/md5'

module Teamwork
  module Cache
    class FileCache
      def set(key, value)
        File.atomic_write "#{base}/#{digest(key)}" do |f|
          f.write value.to_json
        end
      end

      def exists?(key)
        File.exists?("#{base}/#{digest(key)}")
      rescue
        false
      end

      def get(key)
        content = File.read("#{base}/#{digest(key)}")
        JSON.load content
      rescue
        nil
      end

      private
      def base
        @base ||= "#{Teamwork.gem_root}/cache"
      end

      def digest(key)
         key = Digest::MD5.hexdigest(key)
      end
    end
  end
end
