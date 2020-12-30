# frozen_string_literal: true

module Teamwork
  module Schedule
    # rufus task
    class RufusTask
      attr_reader :rufus_task, :producers

      # main step
      # step 1 initialize
      # step 2 add task
      # step 3 start
      # step 4 remove task
      # step 5 restart
      def initialize(logger: Teamwork.logger)
        @logger = logger
        @producers ||= []
      end

      def add(name, timeout:, cron: nil, every: nil, &block)
        @producers << [name, { cron: cron, every: every, timeout: timeout, overlap: false }, block]
      end

      def remove(name)
        @producers.reject! do |p|
          p[0] == name
        end
      end

      def remove_all
        @producers = []
      end

      def start
        if @producers.empty?
          Teamwork.logger.warn 'no task to run'
          return
        end
        Teamwork.logger.info "start task #{@producers.map { |x| x[0] }}"
        @rufus_task = Rufus::Scheduler.new(max_work_threads: 40)
        @producers.each do |method, args, block|
          cron = args[:cron]
          every = args[:every]
          cal_args = args.compact.merge tag: method
          if cron
            @rufus_task.send :cron, cron, cal_args, &block
          elsif args[:every]
            @rufus_task.send :every, every, cal_args, &block
          else
            Teamwork.logger.error "current only support cron and every mode #{cal_args}"
          end
        end
      end

      # wait for all jobs finish
      def stop
        Teamwork.logger.info "stop task #{@producers.map { |x| x[0] }}"
        @rufus_task&.shutdown(:wait)
      end

      def restart
        stop
        sleep 1
        start
      end
    end

    # no doc
    class RufusLockTask < RufusTask
      def initialize(logger: Teamwork.logger, key: 'zklock')
        super(logger: logger)
        @lock = Teamwork.task.lock(key)
      end

      def start
        if @producers.empty?
          Teamwork.logger.info 'no task to run'
          return
        end
        Teamwork.logger.info "start task #{@producers.map { |x| x[0] }} "
        @rufus_task = Rufus::Scheduler.new(trigger_lock: @lock)
        @producers.each do |method, args, block|
          cron = args[:cron]
          every = args[:every]
          cal_args = args.compact.merge tag: method
          if cron
            @rufus_task.send :cron, cron, cal_args, &block
          elsif args[:every]
            @rufus_task.send :every, every, cal_args, &block
          else
            Teamwork.logger.error "目前只支持cron and every 2种格式  #{cal_args}"
          end
        end
      end
    end
  end
end
