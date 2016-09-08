#!/usr/bin/env ruby

require "bundler/setup"
require 'mindwave'

class EEG < Mindwave::Headset
def attentionCall(attention)
        str = eSenseStr(attention)
        puts "this is an attention #{attention}\n"
end
end

mw = Mindwave::Headset.new
puts "Serial open.."
mw.serial_open
sleep(2)
puts "Connect.."
mw.connect
sleep(2)
puts "Rrun..."
require 'timeout'
status = Timeout::timeout(15) {
mw.run
}
puts "Disconnect"
mw.disconnect
puts "Serial close.."
mw.serial_close

