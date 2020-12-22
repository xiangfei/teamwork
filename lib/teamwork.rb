%w[
  json
  rufus-scheduler
  zeitwerk
  aspect4r
  teamwork/core_ext
].each(&method(:require))

module Teamwork
  class << self
    attr_writer :task, :logger, :message, :cache

    def gem_root
      @gem_root ||= Pathname.new(File.expand_path("..", __dir__))
    end

    def config
      @config ||= JSON.load(File.read("#{gem_root}/config/config.json"))
    rescue => e
      logger.error("read #{gem_root}/config/config.json failed #{e.message}")
      {}
    end

    def task
      @task ||= Teamwork::Task::Zk.new(config["task"]["zk"]) 
      #@task ||= Teamwork::Task::Etcd.new(config["task"]["etcd"])
    end

    def cache
      @cache ||= Teamwork::Cache::FileCache.new
    end

    def logger
      @logger ||= Logger.new STDOUT
    end

    def message
      #@message ||= Teamwork::Message::HttpMessage.new(config["message"]["http"])
      @message ||= Teamwork::Message::KafkaMessage.new(config["message"]["kafka"])
    end
  end
end

Zeitwerk::Loader.for_gem.tap(&:setup)