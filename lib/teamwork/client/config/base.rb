# frozen_string_literal: true

module Teamwork
  module Client
    module Config
      # no doc
      class Base
        class << self
          attr_writer :config, :path

          def path
            # @path ||= '/teamwork/config/alarm'
            raise 'path cannot be null' unless @path

            @path
          end

          def config
            @config ||= begin
              watch
              begin
                Teamwork.task.get(path)
              rescue StandardError => e
                Teamwork.logger.error("get path #{path} config failed")
                {}
              end
            end
          end

          def watch
            Teamwork.task.watch_update path do
              @config = begin
                Teamwork.task.get(path)
              rescue StandardError
                Teamwork.logger.error("wath path #{path} failed")
                {}
              end
            end
          end

          def create_default_config(opts = {})
            Teamwork.task.mkdir_p path  unless Teamwork.task.exists? path
            Teamwork.task.set path, opts.to_json if config.empty?
          end
        end
      end
    end
  end
end
