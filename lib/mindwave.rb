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
# along with this dokuwiki gem; if not, write to the 
# Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, 
# Boston, MA  02110-1301  USA 
#++

require "mindwave/version"

require 'serialport' 
require 'bindata'
require 'logger'

# This module provides access to the Mindwave-Headset
module Mindwave

##
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
HEART_RATE = 0x03
# Attention
# = eSense Values(Attention and Meditation)
#  * 1-20 = strongly lowered
#  * 20-40 = reduced
#  * 40-60 = neutral
#  * 60-80 = slightly elevated
#  * 80-100 = elevated
ATTENTION = 0x04
# Meditation
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
EEG_POWER = 0x81
ASIC_EEG_POWER = 0x83
RRINTERVAL = 0x86

attr_accessor :headsetid, :device, :rate, :log
attr_reader :attention, :meditation, :poor, :headsetstatus, :heart

##
# Standard constructor
# * *Args* :
#   - headsetid (sticker in the battery-case)
#   - device  (tty-device)
#   - rate
#   - log (logger-instance)
def initialize(headsetid=nil,device='/dev/ttyUSB0', rate=115200, log=Logger.new(STDOUT))
        @headsetid=headsetid
        @device=device
        @rate=rate
	@log=log
	@log.level = Logger::FATAL
	@headsetstatus = 0
end

# connects the Mindwave-headset(not needed with Mindwave-Mobile)
# * *Args* :
#   - headsetid
# (Mindwave only)
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
        byte = 0
        tmpbyte = 0;

        while true
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
# * *Args* : (array) payload
def parse_payload(payload)
	if not payload.instance_of?Array or payload.nil? or payload.length < 2
		raise "Invalid Argument"
	end

	log.info("####### PARSE PAYLOAD #########")

	extcodelevel = 0

	# parse the first code and it's payload
	code = payload[0]
	pl = payload[1,payload.length-1]
	
	# TODO: implement Extended-Code-Level-Support
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
		if pl.length > 1
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

# this method sends a byte to the serial connection
# * *Args* : (Integer) hexbyte
# (Mindwave only)
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
        @conn = SerialPort.new(device,rate)
end

# this method closes a serial connection to the device
def serial_close
        @conn.close
end

# --------------------------
# :section: Callback Methods
# --------------------------

# this method is called when the poor-value is parsed
# override this method to implement your own clode
# * *Args* : poor-value
def poorCall(poor)
	if poor == 200 
		log.info("No skin-contact detected")
	end
end

# this method is called when the attention-value is parsed
# override this method to implement your own clode
# * *Args* : attention-value
def attentionCall(attention)
	str = eSenseStr(attention)
	log.info("ATTENTION #{attention} #{str}")
end

# this method is called when the meditation-value is parsed
# override this method to implement your own clode
# * *Args* : attention-value
def meditationCall(meditation)
	str = eSenseStr(attention)
	log.info("MEDITATION #{meditation} #{str}")
end

# this method is called when the heart-rate-value is parsed
# override this method to implement your own clode
# * *Args* : attention-value
def heartCall(heart)
	log.info("HEART RATE #{heart}")
end

# this method is called when the raw-wave-value is parsed
# override this method to implement your own clode
# * *Args* : attention-value
def rawCall(rawvalue)
	log.debug("Converted Raw-Value: #{rawvalue}")
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
# * *Args* : (numeric) value
# * *Returns* : string value
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
# * *Args* : 
#   - rawval1 (numeric) first byte-packet of the raw-wave-code
#   - rawval2 (numeric) second byte-packet of the raw-wave-code
#
# * *Returns* : (numeric) single value generated from the 2 bytes
def convertRaw(rawval1,rawval2)
	return (rawval1 << 8) | rawval2
end

end
end
