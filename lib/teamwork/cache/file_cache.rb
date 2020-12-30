# frozen_string_literal: true

require 'digest/md5'

module Teamwork
  module Cache
    # no doc
    class FileCache
      def set(key, value)
        File.atomic_write "#{base}/#{digest(key)}" do |f|
          f.write value.to_json
        end
      end

      def exists?(key)
        File.exist?("#{base}/#{digest(key)}")
      rescue StandardError
        false
      end

      def get(key)
        content = File.read("#{base}/#{digest(key)}")
        JSON.parse content
      rescue StandardError
        nil
      end

      private

      def base
        @base ||= "#{Teamwork.gem_root}/cache"
      end

      def digest(key)
        Digest::MD5.hexdigest(key)
      end
    end
  end
end
