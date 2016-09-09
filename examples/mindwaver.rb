#!/usr/bin/env ruby

require "bundler/setup"
require 'mindwave'

class EEG < Mindwave::Headset
	# override Attention-Callback-Method
	def attentionCall(attention)
        	str = eSenseStr(attention)
        	puts "this is an attention #{attention} #{str}\n"
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
