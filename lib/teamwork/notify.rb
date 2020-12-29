# frozen_string_literal: true
module Teamwork
  module Notify
    class Mail
      class << self
        def send_mail(to = [  "13388420160@189.cn"], opts = {})
          require "net/smtp" unless defined? Net::SMTP
          address = opts["address"] || Teamwork.config["notify"]["mail"]["address"]
          port = opts["port"] || Teamwork.config["notify"]["mail"]["port"]
          domain = opts["domain"] || Teamwork.config["notify"]["mail"]["domain"]
          authentication =  opts["authentication"] ||  Teamwork.config["notify"]["mail"]["authentication"]
          username = opts["username"] ||  Teamwork.config["notify"]["mail"]["username"]
          password = opts["password"] ||  Teamwork.config["notify"]["mail"]["password"]
          res = Net::SMTP.start(address, port, domain, username, password, authentication) do |smtp|
            #smtp.send_message message, "devops_test@51awifi.com", to
            smtp.open_message_stream(username, to) do |f|
              f.puts "From: #{username}"
              f.puts "To: #{to}"
              f.puts "Subject: teamwork #{opts["monitor_name"]} 告警 #{opts["status"]}"
              f.puts "告警名称: #{opts["monitor_name"]}"
              f.puts "告警等级: #{opts["severity"]}"
              f.puts "告警机器: #{opts["ip"]}"
              f.puts "告警时间: #{opts["time"]}"
              f.puts "告警平台: #{opts["platform"]}"
              f.puts "告警类型: #{opts["metric"]}"
              f.puts "告警消息: #{opts["message"]}"
            end
          end

          Teamwork.logger.debug "send sms #{opts} success #{res.success?}  status #{res.status} message #{res.message}"
        rescue => e
          Teamwork.logger.error "send mail #{opts} failed #{e.message}"
        end
      end
    end
  end
end
