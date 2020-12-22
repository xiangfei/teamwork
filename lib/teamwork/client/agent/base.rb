module Teamwork
  module Client
    class Agent
      # 代理任务taskid, topic 固定, 处理流程收集消息,缓存到cache表
      class Base
        include Aspect4r
        class << self
          attr_reader :_taskid, :_taskinfo

          def data
            Teamwork.cache.get task_id
          end

          def set_task_info(opts = {})
            task_info.merge! opts
          end

          def task_info
            @_taskinfo ||= { topic: "teamwork.agent.normal", send: true }
          end

          def set_task_id(msg)
            @_taskid = msg
          end

          def task_id
            @_taskid || self.class.name
          end

          def s
            #@instance ||= new
            new
          end

          def basemsg 
            @basemsg ||= {"taskid" => task_id , "ip" => Teamwork::Utils.ip , "mac" => Teamwork::Utils.mac , "hostname" => Teamwork::Utils.hostname } 
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
            Teamwork.cache.set self.class.task_id, @_m
          rescue StandardError => e
            Teamwork.logger.error("run task failed cls: #{self.class} , taskid: #{self.class.task_id} , message:  #{e.message}")
          end
          sendmsg if self.class.task_info[:send]
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

        def sendmsg
          unless @_m
            Teamwork.logger.error "msg 为空不能发消息"
            return
          end
          begin
            Teamwork.message.deliver_message @_m, topic: self.class.task_info[:topic]
          rescue => e
            Teamwork.logger.error "msg  class #{self.class} , topic #{self.class.task_info[:topic]}  msg: #{@_m} error #{e.message}"
          end
        end
      end
    end
  end
end
