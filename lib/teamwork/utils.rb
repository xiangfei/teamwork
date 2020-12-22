require "socket"

module Teamwork
  module Utils
    class << self
      link = ::Socket::PF_LINK if ::Socket.const_defined? :PF_LINK
      packet = ::Socket::PF_PACKET if ::Socket.const_defined? :PF_PACKET
      INTERFACE_PACKET_FAMILY = link || packet

      # 多网卡可能有问题
      def ip
        @ip ||= begin
            Teamwork.logger.warn "ip method 多网卡可能有问题"
            ip = ::Socket.ip_address_list.detect { |intf| intf.ipv4_private? }
            ip.ip_address
          end
      end

      # 多网卡可能有问题
      def mac
        @mac ||= begin
            Teamwork.logger.warn "mac method多网卡可能有问题"
            interfaces = ::Socket.getifaddrs.select do |addr|
              addr.addr.pfamily == INTERFACE_PACKET_FAMILY if addr.addr
            end
            mac, = if ::Socket.const_defined? :PF_LINK
                instance_map = interfaces.map do |addr|
                  addr.addr.getnameinfo
                end
                instance_map.find do |m, |
                  !m.empty?
                end
              elsif ::Socket.const_defined? :PF_PACKET
                instance_map = interfaces.map do |addr|
                  addr.addr.inspect_sockaddr[/hwaddr=([\h:]+)/, 1]
                end
                instance_map.find do |mac_addr|
                  mac_addr != "00:00:00:00:00:00"
                end
              end
            mac
          end
      end

      def hostname
        @hostname ||= ::Socket.gethostname
      end

    def all_nics
        st, value = linux_command("ls /sys/class/net/")
        if st
          value.map do |x| x.split[0] end
        else
          Teamwork.logger.error "get nic failed"
          []
        end
      end

      def virtual_nics
        st, value = linux_command("ls /sys/devices/virtual/net")
        if st
          value.map do |x| x.split[0] end
        else
          Teamwork.logger.error "get nic failed"
          []
        end
      end

      def physical_nics
        st, value = linux_command("ls /sys/class/net/ | grep -v \"`ls /sys/devices/virtual/net/`\"")
        if st
          value.map do |x| x.split[0] end
        else
          Teamwork.logger.error "get nic failed"
          []
        end
      end

      def old_linux_command(cmd, timeout = 60, &block)
        require "open3" unless defined?(Open3)
        Timeout.timeout timeout do
          Teamwork.logger.debug cmd
          output, status = Open3.capture2e cmd
          if status.success?
            [true, output]
          else
            [false, output]
          end
        end
      rescue => e
        Teamwork.logger.error "run command exception  #{cmd} result #{e.message}"
        return false, e.message
      end

      def linux_command(cmd, timeout = 60, &block)
        require "open3" unless defined?(Open3)
        Timeout.timeout timeout do
          begin
            stdin, stdout, stderr, wait_thr = Open3.popen3("#{cmd}")
            stdin.close
            exit_status = wait_thr.value
            if exit_status.success?
              result = stdout.readlines
              Teamwork.logger.debug "run command success #{cmd}  result #{result}"
              return true, result
            else
              result = stderr.readlines
              Teamwork.logger.error "run command failed  #{cmd} result #{result}"
              return false, result
            end
          ensure
            stdin.close rescue nil
            stderr.close rescue nil
          end
        end
      rescue => e
        Teamwork.logger.error "run command exception  #{cmd} result #{e.message}"
        return false, e.message
      end


    end
  end
end
