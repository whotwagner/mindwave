# Mindwave

[![GPL Licence](https://badges.frapsoft.com/os/gpl/gpl.png?v=103)](https://github.com/whotwagner/mindwave/blob/master/LICENSE.txt)  
[![Build Status](https://travis-ci.org/whotwagner/mindwave.svg?branch=master)](https://travis-ci.org/whotwagner/mindwave)
[![Inline docs](http://inch-ci.org/github/whotwagner/mindwave.svg?branch=master)](http://inch-ci.org/github/whotwagner/mindwave)
[![Code Climate](https://codeclimate.com/github/whotwagner/mindwave/badges/gpa.svg)](https://codeclimate.com/github/whotwagner/mindwave)


This gem is a library for the Neurosky Mindwave headset. It reads out EEG-data from the ThinkGear Serial Stream and provides callback-methods for processing the data.

Even if this library is written for the Mindwave-Headset most of the code should work with the Mindwave-Mobile-Headset too. The big difference is that the methods "connect and disconnect" are not needed for Mindwave Mobile Headsets. 

## Installation

TODO: Upload this Gem to rubygems

## Usage

In the following example the default callback-methods are invoked:

```ruby
#!/usr/bin/env ruby

require 'mindwave'

# create a new instance
mw = Mindwave::Headset.new
mw.log.level = Logger::INFO

# if we hit ctrl+c then just stop the run()-method
Signal.trap("INT") do
	mw.stop
end

# Create a new Thread
thread = Thread.new { mw.run }
# ..and run it
thread.join

mw.close

```

The callback-methods can be overwritten with own code:


```ruby
#!/usr/bin/env ruby

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
```

## Resources

   * http://developer.neurosky.com/docs/lib/exe/fetch.php?media=app_notes:mindwave_rf_external.pdf
   * http://developer.neurosky.com/docs/doku.php?id=thinkgear_communications_protocol
   * https://github.com/BarkleyUS/mindwave-python

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/whotwagner/mindwave. I am highly interested at pull requests for the mindwave-mobile-headset.

