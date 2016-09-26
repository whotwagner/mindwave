#!/usr/bin/env ruby

require "bundler/setup"
require 'mindwave'

class EEG < Mindwave::Headset
  # override Attention-Callback-Method
  def asicCall(asic)

    puts "DEBUG: ASIC array: #{asic}\n"

    # pass asic to parseASIC and store result
    parsed = parseASIC(asic)

    # print the values of the waves to STDOUT
    puts "delta:     #{parsed[0]}"
    puts "theta:     #{parsed[1]}"
    puts "lowAlpha:  #{parsed[2]}"
    puts "highAlpha: #{parsed[3]}"
    puts "lowBeta:   #{parsed[4]}"
    puts "highBeta:  #{parsed[5]}"
    puts "lowGamma:  #{parsed[6]}"
    puts "midGamma:  #{parsed[7]}"
  end

end

# create a new instance
mw = EEG.new
# mw.log.level = Logger::DEBUG

# if we hit ctrl+c then just stop the run()-method
Signal.trap("INT") do
	mw.stop
end

# Create a new Thread
thread = Thread.new { mw.run }
# ..and run it
thread.join


mw.close
