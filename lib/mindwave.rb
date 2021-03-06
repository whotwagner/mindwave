#--
# Copyright (C) 2016 Wolfgang Hotwagner <code@feedyourhead.at>       
#                                                                
# This file is part of the mindwave gem                                            
# 
# This mindwave gem is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License 
# as published by the Free Software Foundation; either version 2 
# of the License, or (at your option) any later version.
# 
# This mindwave gem is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License          
# along with this mindwave gem; if not, write to the 
# Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, 
# Boston, MA  02110-1301  USA 
#++

require "mindwave/version"

require 'serialport' 
require 'bindata'
require 'logger'

# This module provides access to the Mindwave-Headset
module Mindwave

# The Mindwave::Headset-class gives access to the Mindwave-Headset.
# It's written for the Mindwave-Headset only, but most of the code
# should work for Mindwave-Mobile too.
#
# To use the callback-methods, just inherit from this class and
# override the Callback-Methods with your own code.
class Headset
# -----------------------
# :section: Request Codes
# -----------------------

# Connection Requests
CONNECT = 0xc0 
# Disconnect Request
DISCONNECT = 0xc1
# Autoconnect Request
AUTOCONNECT = 0xc2

# -----------------------
# :section: Headset Status Codes
# -----------------------

# Headset connected
HEADSET_CONNECTED = 0xd0
# Headset not found
HEADSET_NOTFOUND = 0xd1
# Headset disconnected
HEADSET_DISCONNECTED = 0xd2
# Request denied
REQUEST_DENIED = 0xd3
# Dongle is in standby mode
DONGLE_STANDBY = 0xd4

# -----------------------
# :section: Control Codes
# -----------------------

# Start of a new data-set(packet)
SYNC = 0xaa 
# Extended codes
EXCODE = 0x55 

# -----------------------
# :section: Single-Byte-Codes
# -----------------------

# 0-255(zero is good). 200 means no-skin-contact
POOR_SIGNAL = 0x02 
# Heartrate
HEART_RATE = 0x03
# Attention 
# @see #eSenseStr
ATTENTION = 0x04
# Meditation 
# @see #eSenseStr
MEDITATION = 0x05
# Not available in Mindwave and Mindwave Mobile
BIT8_RAW = 0x06    
# Not available in Mindwave and Mindwave Mobile
RAW_MARKER = 0x07  

# -----------------------
# :section: Multi-Byte-Codes
# -----------------------

# Raw Wave output
RAW_WAVE = 0x80
# EEG-Power
EEG_POWER = 0x81
# ASIC-EEG-POWER-INT
ASIC_EEG_POWER = 0x83
# RRinterval
RRINTERVAL = 0x86

# @!attribute headsetid
#   @return [Integer] headset id
# @!attribute device
#   @return [String] dongle device(like /dev/ttyUSB0)
# @!attribute rate
#   @return [Integer] baud-rate of the device
# @!attribute log
#   @return [Logger] logger instance
attr_accessor :headsetid, :device, :rate, :log

# @!attribute [r] attention
#   stores the current attention-value
# @!attribute [r] meditation
#   stores the current meditation-value
# @!attribute [r] asic
#   stores the current asic-value
# @!attribute [r] poor
#   stores the current poor-value
# @!attribute [r] headsetstatus
#   stores the current headsetstatus-value
# @!attribute [r] heart
#   stores the current heart-value
# @!attribute [r] runner
#   @see #stop
attr_reader :attention, :meditation, :asic, :poor, :headsetstatus, :heart, :runner

# If connectserial is true, then this constructor opens a serial connection 
# and automatically connects to the headset
#
# @param [Integer] headsetid it's on the sticker in the battery-case
# @param [String] device tty-device
# @param [Integer] rate baud-rate
# @param [Logger] log (logger-instance)
def initialize(headsetid=nil,device='/dev/ttyUSB0', connectserial=true,rate=115200, log=Logger.new(STDOUT))
        @headsetid=headsetid
        @device=device
        @rate=rate
	@log=log
	@log.level = Logger::FATAL
	@headsetstatus = 0
	@runner = true

	if connectserial
		serial_open
		connect(@headsetid)
	end
end

# connects the Mindwave-headset(not needed with Mindwave-Mobile)
# (Mindwave only)
#
# @param [Integer] headsetid it's on the sticker in the battery-case
# TODO: implement connection with headsetid
def connect(headsetid=nil)
        if not headsetid.nil?
                @headsetid = headsetid
        end

        if @headsetid.nil?
                autoconnect()
                return
        end

        cmd = BinData::Uint8be.new(Mindwave::Headset::CONNECT)
        cmd.write(@conn)
end

# This method creates an infinite loop
# and reads out all data from the headset using
# the open serial-line.
def run

        tmpbyte = 0;
	@runner = true

        while @runner
		log.debug("<<< START RECORD >>>")
                tmpbyte = logreadbyte

		# 0xaa indicates the first start of a packet
                if tmpbyte != Mindwave::Headset::SYNC
			log.info(sprintf("LOST: %x\n",tmpbyte))
                        next
                else
                        tmpbyte = logreadbyte()
			# a second 0xaa verifies the start of a packet
                        if tmpbyte != Mindwave::Headset::SYNC
				log.info(sprintf("LOST: %x\n",tmpbyte))
                                next
                        end

                end
	
		while true
			# read out the length of the packet
			plength = logreadbyte()
			if(plength != 170)
				break
			end
		end

		if(plength > 170)
			next
		end

		log.info(sprintf("Header-Length: %d",plength))
		payload = Array.new(plength)
		checksum = 0
		# read out payload
		(0..plength-1).each do |n|
			payload[n] = logreadbyte()
			# ..and add it to the checksum
			checksum += payload[n]
		end

		# weird checksum calculations
		checksum &= 0xff
		checksum = ~checksum & 0xff
	
		# read checksum-packet
		c = logreadbyte()

		# compare checksum-packet with the calculated checksum
		if( c != checksum)
			log.info(sprintf("Checksum Error: %x - %x\n",c,checksum))
		else
			# so finally parse the payload of our packet
			parse_payload(payload)
		end	
	
        end

end

# this method parses the payload of a data-row, parses the values and invokes the callback methods
# @param [Array] payload Array with the payload
def parse_payload(payload)
	if not payload.instance_of?Array or payload.nil? or payload.length < 2
		raise "Invalid Argument"
	end

	log.info("####### PARSE PAYLOAD #########")

	extcodelevel = 0

	# parse the first code and it's payload
	code = payload[0]
	pl = payload[1,payload.length-1]
	
	if code == Mindwave::Headset::EXCODE
		extcodelevel += 1
		
		# iterate through the payload-array
		(1..payload.length).each do |n|
			# if there is an excode, increment the level
			if payload[n] == Mindwave::Headset::EXCODE
				extcodelevel += 1
			else
				# ..otherwise parse the next code and it's payload
				code = payload[n]
				pl = payload[n+1,payload.length-(n+1)]
				break
			end
		end
	end

	# some debugging output
	log.info(sprintf("extcodelevel: %x",extcodelevel))
	log.info(sprintf("Code: %x",code))
	log.debug(sprintf("Length: %d",pl.length))
	pl.each do |n|
		log.debug(sprintf("payload: Hex: %x Dec: %d",n,n))
	end


	# SINGLE-BYTE-CODES
	if code < Mindwave::Headset::RAW_WAVE or code >= Mindwave::Headset::HEADSET_CONNECTED

		sbpayload = pl[0]
		codestr = ""

		case code
		when Mindwave::Headset::HEADSET_CONNECTED
			codestr = "Headset connected"
			@headsetstatus = code
		when Mindwave::Headset::HEADSET_NOTFOUND
			codestr = "Headset not found"
			@headsetstatus = code
		when Mindwave::Headset::HEADSET_DISCONNECTED
			codestr = "Headset disconnected"
			@headsetstatus = code
		when Mindwave::Headset::REQUEST_DENIED
			codestr = "Request denied"
			@headsetstatus = code
		when Mindwave::Headset::DONGLE_STANDBY
			codestr = "Dongle standby"
			@headsetstatus = code
		when Mindwave::Headset::POOR_SIGNAL
			codestr = "Poor Signal"
			@poor = sbpayload
			poorCall(@poor)
		when Mindwave::Headset::HEART_RATE
			codestr = "Heart Rate"
			@heart = sbpayload
			heartCall(@heart)
		when Mindwave::Headset::ATTENTION
			codestr = "Attention"
			@attention = sbpayload
			attentionCall(@attention)
		when Mindwave::Headset::MEDITATION
			codestr = "Meditation"
			@meditation = sbpayload
			meditationCall(@meditation)
		## THIS METHODS ARE NOT AVAILABLE FOR MINDWAVE(MOBILE)
		when Mindwave::Headset::BIT8_RAW 
			codestr = "8Bit Raw"
		when Mindwave::Headset::RAW_MARKER 
			codestr = "Raw Marker"
		# EOF NOT AVAILABLE
		else
			codestr = "Unknown"
		end

		log.debug(sprintf("SINGLEBYTE-PAYLOAD: Code: %s Hex: %x - Dec: %d",codestr,sbpayload,sbpayload))

		# Re-Parse the rest of the payload 
		if pl.length > 2
			payload = pl[1,pl.length-1]
			# recursive call of parse_payload for the next data-rows
			parse_payload(payload)
		end

	# MULTI-BYTE-CODES
	else
		codestr = ""
		plength = pl[0]
		mpl = pl[1,plength]

		case code

		when Mindwave::Headset::RAW_WAVE
			codestr = "RAW_WAVE Code detected"
			rawCall(convertRaw(mpl[0],mpl[1]))
		when Mindwave::Headset::EEG_POWER
			codestr = "EEG Power"
		when Mindwave::Headset::ASIC_EEG_POWER
			codestr = "ASIC EEG POWER"
			@asic = mpl
			asicCall(@asic)
		when Mindwave::Headset::RRINTERVAL
			codestr = "RRINTERVAL"
		else
			codestr = "Unknown"
		end

		# Fetch the Multi-Payload
		log.info(sprintf("Multibyte-Code: %s",codestr))
		log.info(sprintf("Multibyte-Payload-Length: %d",pl[0]))
		
		mpl.each() do |n|
			log.debug(sprintf("MULTIBYTE-PAYLOAD: Hex: %x - Dec: %d",n,n))
		end

		# Re-Parse the rest of the payload 
		if pl.length-1 > plength
			payload = pl[mpl.length+1,pl.length-mpl.length]
			# recursive call of parse_payload for the next data-rows
			parse_payload(payload)
		end
	end


end

# this method parses the raw ASIC values and returns the values of each
# of the wave types
#
# @param [Integer] asic value 
#
# @returns [Array<Integer>] Array of: delta,theta,lowAlpha,highAlpha,lowBeta,highBeta,lowGamma,midGamma
def parseASIC(asic)
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

    # stuff wave values in array
    asicArray = [delta,theta,lowAlpha,highAlpha,lowBeta,highBeta,lowGamma,midGamma]
    
    # return array of wave values
    return asicArray
end

# this method sends a byte to the serial connection
# (Mindwave only)
#
# @param [Integer] hexbyte byte to send
def sendbyte(hexbyte)
	cmd = BinData::Uint8be.new(hexbyte)
	cmd.write(@conn)
end

# This method connects to the headset automatically without knowing the device-id
# (Mindwave only)
def autoconnect
        cmd = BinData::Uint8be.new(Mindwave::Headset::AUTOCONNECT)
        cmd.write(@conn)
end

# this method disconnects a connection between headset and dongle
# (Mindwave only)
def disconnect
        cmd = BinData::Uint8be.new(Mindwave::Headset::DISCONNECT)
        cmd.write(@conn)
end

# this method opens a serial connection to the device
def serial_open
        @conn = SerialPort.new(@device,@rate)
end

# this method closes a serial connection to the device
def serial_close
        @conn.close
end

# this method disconnects the headset and closes the serial line
def close
	disconnect
	serial_close
end

# this method stops the run-method
def stop
	@runner = false
end

# --------------------------
# :section: Callback Methods
# --------------------------

# this method is called when the poor-value is parsed
# override this method to implement your own clode
#
# @param [Integer] poor poor-value
def poorCall(poor)
	if poor == 200 
		log.info("No skin-contact detected")
	end
end

# this method is called when the attention-value is parsed
# override this method to implement your own code
#
# @param [Integer] attention attention-value
def attentionCall(attention)
	str = eSenseStr(attention)
	log.info("ATTENTION #{attention} #{str}")
end

# this method is called when the meditation-value is parsed
# override this method to implement your own code
#
# @param [Integer] meditation meditation-value
def meditationCall(meditation)
	str = eSenseStr(meditation)
	log.info("MEDITATION #{meditation} #{str}")
end

# this method is called when the heart-rate-value is parsed
# override this method to implement your own code
#
# @param [Integer] heart heart-value
def heartCall(heart)
	log.info("HEART RATE #{heart}")
end

# this method is called when the raw-wave-value is parsed
# override this method to implement your own code
#
# @param [Integer] rawvalue raw-wave-value
def rawCall(rawvalue)
	log.debug("Converted Raw-Value: #{rawvalue}")
end

##
# this method is called when the asic-value is parsed
# override this method to implement your own code
#
# @param [Integer] asic asic-value
#
def asicCall(asic)
	log.debug("ASIC Value: #{asic}")
end

private

# reads out a byte from the serial-line and
# logs the byte using "debug"
def logreadbyte
	begin
	ret = @conn.readbyte
	rescue EOFError
		log.fatal("EOFError")
		# But Ignore it with FF
		ret = 0x00
	end
	log.debug(sprintf("HEX: %x DEC: %d",ret,ret))
	return ret
end

# this method converts the numeric eSense-value of attention or meditation
# to a string
# 
# @param [Integer] value eSense-value
# @returns [String] string-value
# = eSense Values(Attention and Meditation)
#  * 1-20 = strongly lowered
#  * 20-40 = reduced
#  * 40-60 = neutral
#  * 60-80 = slightly elevated
#  * 80-100 = elevated
def eSenseStr(value)
	result = case value
		when 0..20   then "Strongly lowered"
		when 21..40  then "Reduced"
		when 41..60  then "Neutral"
		when 61..80  then "Slightly elevated"
		when 81..100 then "Elevated"
		else
			"Unknown"
		end

	return result
end

# converts a raw-wave-data-packet of 2 bytes to a single value
#
# @param [Integer] rawval1 first byte-packet of the raw-wave-code
# @param [Integer] rawval2 second byte-packet of the raw-wave-code
#
# @return [Integer] single value generated from the 2 bytes
def convertRaw(rawval1,rawval2)

	raw = rawval1*256 + rawval2
        if raw >= 32768
                raw = raw - 65536
        end

	return raw
end

# converts a raw ASIC power packet of three bytes to a single value
#
# @param [Integer] threeBytes[0] first byte-packet of the ASIC wave code
# @param [Integer] threeBytes[1] second byte-packet of the ASIC wave code
# @param [Integer] threeBytes[2] third byte-packet of the ASIC wave code
#
# @return [Integer] single value generated from the 3 bytes
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
end
