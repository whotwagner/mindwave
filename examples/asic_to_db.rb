#!/usr/bin/env ruby

require "bundler/setup"
require 'mindwave'
require 'sqlite3'
require 'active_record'

# Set up the database connection
ActiveRecord::Base.establish_connection(
  :adapter     => "sqlite3",
  :database    => "eeg.db"
)

# Define a minimal database schema
ActiveRecord::Schema.define do
  create_table :sessions, force: true do |t|
    t.datetime  :datetime
    t.integer   :delta
    t.integer   :theta
    t.integer   :low_alpha
    t.integer   :high_alpha
    t.integer   :low_beta
    t.integer   :high_beta
    t.integer   :low_gamma
    t.integer   :mid_gamma
  end
end

# Define the EEG db/class
class Session < ActiveRecord::Base
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

    # INSERT EEG wave values into the db via ActiveRecord
    sess = Session.create!(datetime:                 t,
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

# create a new instance and override default device
mw = EEG.new(nil,'/dev/tty.MindWaveMobile-DevA')
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
