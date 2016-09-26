#!/usr/bin/env ruby

require "bundler/setup"
require 'mindwave'

class EEG < Mindwave::Headset
  # override Attention-Callback-Method
  def asicCall(asic)
    puts "DEBUG: ASIC array: #{asic}\n"
    # assign #{asic} to the array 'a'
    a = "#{asic}"
    # strip off square brackets
    a = a.delete! '[]'
    # convert to array of integers
    a = a.split(",").map(&:to_i)

    # define wave values
    delta     = convertToBigEndianInteger(a[0..3])
    theta     = convertToBigEndianInteger(a[3..6])
    lowAlpha  = convertToBigEndianInteger(a[6..9])
    highAlpha = convertToBigEndianInteger(a[9..12])
    lowBeta   = convertToBigEndianInteger(a[12..15])
    highBeta  = convertToBigEndianInteger(a[15..18])
    lowGamma  = convertToBigEndianInteger(a[18..21])
    midGamma  = convertToBigEndianInteger(a[21..24])

    puts "delta:     #{delta}"
    puts "theta:     #{theta}"
    puts "lowAlpha:  #{lowAlpha}"
    puts "highAlpha: #{highAlpha}"
    puts "lowBeta:   #{lowBeta}"
    puts "highBeta:  #{highBeta}"
    puts "lowGamma:  #{lowGamma}"
    puts "midGamma:  #{midGamma}"
  end

  def convertToBigEndianInteger(threeBytes)
    # see MindwaveDataPoints.py at
    # https://github.com/robintibor/python-mindwave-mobile
    #
    bigEndianInteger = (threeBytes[0] << 16) |\
     (((1 << 16) - 1) & (threeBytes[1] << 8)) |\
      ((1 << 8) -1) & threeBytes[2]
    return bigEndianInteger
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
