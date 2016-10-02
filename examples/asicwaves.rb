#!/usr/bin/env ruby

require "bundler/setup"
require 'mindwave'
require 'mysql2'
require 'active_record'

# Set up the database connection
ActiveRecord::Base.establish_connection(
  :adapter     => "mysql2",
  :host        => "localhost",
  :username    => "svf",
  :password    => "idlinmal",
  :database    => "eeg"
)

# Define the EEG db/class
class EEGSession < ActiveRecord::Base
end

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

    # INSERT wave values into the db
    dbInsert(parsed)

  end

  def dbInsert(parsed)

    # Time format (datetime with miliseconds)
    f = '%Y%m%d %H:%M:%S.%3N'
    # fetch the time and format it
    t = Time.now.strftime(f)

    # temp values
    noise      = 0
    poor       = 0
    attention  = 50
    meditation = 50
    blink      = 1
    # INSERT EEG wave values into MySQL db
    sess = EEGSession.create!(datetime:                 t
                              amount_of_noise:          noise,
                              poor_signal_level_string: poor,
                              attention:                attention,
                              meditation:               meditation,
                              blink:                    blink,
                              delta:                    parsed[0], 
                              theta:                    parsed[1],
                              low_alpha:                parsed[2],
                              high_alpha:               parsed[3],
                              low_beta:                 parsed[4],
                              high_beta:                parsed[5],
                              low_gamma:                parsed[6],
                              mid_gamma:                parsed[7]
                              )
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
