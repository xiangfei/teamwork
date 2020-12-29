# frozen_string_literal: true

%w[
  json
  rufus-scheduler
  zeitwerk
  teamwork/core_ext
].each(&method(:require))

# no doc
module Teamwork
  class << self
    attr_writer :task, :logger, :message, :cache, :consumer

    def gem_root
      @gem_root ||= Pathname.new(File.expand_path('..', __dir__))
    end

    def config
      @config ||= JSON.parse(File.read("#{gem_root}/config/config.json"))
    rescue StandardError => e
      logger.error("read #{gem_root}/config/config.json failed #{e.message}")
      {}
    end

    def task
      @task ||= Teamwork::Task::Zk.new(config['task']['zk'])
      # @task ||= Teamwork::Task::Etcd.new(config["task"]["etcd"])
    end

    def cache
      @cache ||= Teamwork::Cache::FileCache.new
    end

    def logger
      @logger ||= Logger.new $stdout
    end

    def message
      # @message ||= Teamwork::Message::HttpMessage.new(config["message"]["http"])
      @message ||= Teamwork::Message::KafkaMessage.new(config['message']['kafka'])
    end

    def consumer
      @consumer ||= Teamwork::Consumer::Kafka.new(config['message']['kafka'])
    end

    def loader
      @loader ||= begin
        l = Zeitwerk::Loader.for_gem
        l.enable_reloading
        l
      end
    end

    def reload
      loader.reload
      # zookeeper = nil
      logger.info 'reload Teamwork class module finish'
    end
  end
end

Teamwork.loader.setup
