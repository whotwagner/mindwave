#!/usr/bin/env ruby

require "bundler/setup"
require 'mindwave'

class EEG < Mindwave::Headset
def attentionCall(attention)
        str = eSenseStr(attention)
        puts "this is an attention #{attention} #{str}\n"
end
end

mw = EEG.new
mw.log.level = Logger::FATAL
puts "Serial open.."
mw.serial_open
sleep(2)
puts "Connect.."
mw.connect
sleep(2)
# puts "Run..."
# require 'timeout'
# status = Timeout::timeout(60) {
# mw.run
# }
puts "Disconnect"
mw.disconnect
puts "Serial close.."
mw.serial_close

