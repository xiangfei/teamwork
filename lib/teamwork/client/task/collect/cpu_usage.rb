# frozen_string_literal: true

module Teamwork
  module Client
    module Task
      module Collect
        # no doc
        class CpuUsage < Base
          set_task_info topic: 'teamwork.collect.normal', send: true, task_id: 'teamwork_client_task_collect_cpu_usage'

          # include Teamwork::Callback
          # before :process, :set_meta
          # after :process , :trigger_alarm
          def set_meta
            puts 'meta'
          end

          def trigger_alarm
            puts 'trigger_alarm'
          end

          def process(_args = {})
            _, cpu_usage = Teamwork::Utils.linux_command("top -bn 1 | awk '/Cpu/ {print $2}'")
            msg['cpu_usage'] = cpu_usage.first.to_i
            _, cpu_load = Teamwork::Utils.linux_command('uptime')
            cpu_load = cpu_load.first.split(':').last.split(',')
            msg['cpu_load_1'] = cpu_load[0].to_f
            msg['cpu_load_5'] = cpu_load[1].to_f
            msg['cpu_load_15'] = cpu_load[2].to_f
            msg
          end
        end
      end
    end
  end
end
