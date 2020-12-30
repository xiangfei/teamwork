# frozen_string_literal: true

require 'socket'

module Teamwork
  # no doc
  module Utils
    class << self
      link = ::Socket::PF_LINK if ::Socket.const_defined? :PF_LINK
      packet = ::Socket::PF_PACKET if ::Socket.const_defined? :PF_PACKET
      INTERFACE_PACKET_FAMILY = link || packet
      def ip
        @ip ||= begin
          Teamwork.logger.warn 'ip method 多网卡可能有问题'
          ip = ::Socket.ip_address_list.detect(&:ipv4_private?)
          ip.ip_address
        end
      end

      def mac
        @mac ||= begin
          Teamwork.logger.warn 'mac method多网卡可能有问题'
          interfaces = ::Socket.getifaddrs.select do |addr|
            addr.addr.pfamily == INTERFACE_PACKET_FAMILY if addr.addr
          end
          mac, = if ::Socket.const_defined? :PF_LINK
                   instance_map = interfaces.map do |addr|
                     addr.addr.getnameinfo
                   end
                   instance_map.find do |m,|
                     !m.empty?
                   end
                 elsif ::Socket.const_defined? :PF_PACKET
                   instance_map = interfaces.map do |addr|
                     addr.addr.inspect_sockaddr[/hwaddr=([\h:]+)/, 1]
                   end
                   instance_map.find do |mac_addr|
                     mac_addr != '00:00:00:00:00:00'
                   end
                 end
          mac
        end
      end

      def hostname
        @hostname ||= ::Socket.gethostname
      end

      def all_nics
        st, value = linux_command('ls /sys/class/net/')
        if st
          value.map { |x| x.split[0] }
        else
          Teamwork.logger.error 'get nic failed'
          []
        end
      end

      def virtual_nics
        st, value = linux_command('ls /sys/devices/virtual/net')
        if st
          value.map { |x| x.split[0] }
        else
          Teamwork.logger.error 'get nic failed'
          []
        end
      end

      def physical_nics
        st, value = linux_command('ls /sys/class/net/ | grep -v "`ls /sys/devices/virtual/net/`"')
        if st
          value.map { |x| x.split[0] }
        else
          Teamwork.logger.error 'get nic failed'
          []
        end
      end

      def old_linux_command(cmd, timeout = 60)
        require 'open3' unless defined?(Open3)
        Timeout.timeout timeout do
          Teamwork.logger.debug cmd
          output, status = Open3.capture2e cmd
          if status.success?
            [true, output]
          else
            [false, output]
          end
        end
      rescue StandardError => e
        Teamwork.logger.error "run command exception  #{cmd} result #{e.message}"
        [false, e.message]
      end

      def linux_command(cmd, timeout = 60)
        require 'open3' unless defined?(Open3)
        Timeout.timeout timeout do
          stdin, stdout, stderr, wait_thr = Open3.popen3(cmd.to_s)
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
        end
      rescue StandardError => e
        Teamwork.logger.error "run command failed  #{cmd} result #{e.message}"
        [false, e.message]
      end
    end
  end
end
