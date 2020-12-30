# frozen_string_literal: true

module Teamwork
  module Client
    module Task
      module Collect
        # port监控告警拆分开来, 收集,告警,恢复,脚本
        class Port < Base
          def process(ops = {})
            port = ops['port'] || []
            port.map!(&:to_i)
            listen_port = listen_ports
            msg.merge!({ listen_port: listen_port, port: port })
          end

          def listen_ports
            _, port_lists = Teamwork::Utils.linux_command "netstat -antp | sed '1,2d' | awk '/tcp/{if($6 == \"LISTEN\")print $4}'"
            port_lists.map do |p|
              p.split(':').last.to_i
            end
          end
        end
      end
    end
  end
end
