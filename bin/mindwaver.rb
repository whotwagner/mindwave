#!/usr/bin/env ruby

require "bundler/setup"
require 'mindwave'

mw = Mindwave::Dongle.new
puts "Serial open.."
mw.log = Logger.new("mindwave.log")
mw.log.level = Logger::INFO
mw.serial_open
sleep(2)
puts "Connect.."
mw.connect
#sleep(5)
#puts "Send Byte Attention"
#mw.sendbyte(0x01)
sleep(2)
puts "Reader..."
# require 'timeout'
# status = Timeout::timeout(30) {
mw.reader
# }
puts "Disconnect"
mw.disconnect
puts "Serial close.."
mw.serial_close

