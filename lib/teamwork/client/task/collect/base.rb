module Teamwork
  module Client
    module Task
      module Collect
        # 代理任务taskid, topic 固定, 处理流程收集消息,缓存到cache表
        class Base
          include Aspect4r
          class << self
            attr_reader :_taskinfo

            def set_task_info(opts = {})
              task_info.merge! opts
            end

            #只做收集,执行失败放告警任务
            def task_info
              @_taskinfo ||= { topic: "teamwork.collect.normal", send: true, task_id: self.name.downcase.gsub("::", "_") }
            end

            # 全局task_id, 用来创建默认collect 任务
            def task_id
              task_info[:task_id]
            end

            def send
              task_info[:send]
            end

            def topic
              task_info[:topic]
            end

            def s
              @instance ||= new
            end

            def basemsg
              @basemsg ||= { "task_id" => task_id, "ip" => Teamwork::Utils.ip, "mac" => Teamwork::Utils.mac, "hostname" => Teamwork::Utils.hostname }
            end
          end

          def initialize
            @_m = {}
          end

          def process(ops = {})
            raise "abstract  method cannot run"
          end

          def run(args = {})
            begin
              @_m.merge! self.class.basemsg
              process args
              @_m["time"] = Time.now.to_i
              Teamwork.cache.set task_id, @_m
            rescue StandardError => e
              Teamwork.logger.error("run task failed cls: #{self.class} , taskid: #{taskid} , message:  #{e.message}")
            end
            sendmsg if self.class.send
          end

          def msg
            return self
          end

          def []=(k, v)
            @_m[k] = v
          end

          def merge!(opts = {})
            @_m.merge! opts
          end

          def merge(opts = {})
            @_m.merge opts
          end

          private

          def task_id
            @_m["task_id"]
          end

          def sendmsg
            unless @_m
              Teamwork.logger.error "msg 为空不能发消息"
              return
            end
            begin
              Teamwork.message.deliver_message @_m, topic: self.class.topic
            rescue => e
              Teamwork.logger.error "msg  class #{self.class} , topic #{self.class.topic}  msg: #{@_m} error #{e.message}"
            end
          end
        end
      end
    end
  end
end
