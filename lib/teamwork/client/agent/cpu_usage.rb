module Teamwork
  module Client
    class Agent
      class CpuUsage < Base
        set_task_id "teamwork_client_agent_cpu_usage"
        #set_task_info topic: "xcxx", send: false

        def process(args = {})
          _, cpu_usage = Teamwork::Utils.linux_command("top -bn 1 | awk '/Cpu/ {print $2}'")
          msg["cpu_usage"] = cpu_usage.first.to_i
          _, cpu_load = Teamwork::Utils.linux_command("uptime")
          cpu_load = cpu_load.first.split(":").last.split(",")
          msg["cpu_load_1"] = cpu_load[0].to_f
          msg["cpu_load_5"] = cpu_load[1].to_f
          msg["cpu_load_15"] = cpu_load[2].to_f
          msg
        end
      end
    end
  end
end