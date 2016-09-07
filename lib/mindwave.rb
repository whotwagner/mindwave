require "mindwave/version"

require 'serialport' 
require 'bindata'
require 'logger'

module Mindwave

class Dongle
# Connection Requests
CONNECT = 0xc0
DISCONNECT = 0xc1
AUTOCONNECT = 0xc2
# Headset Status
HEADSET_CONNECTED = 0xd0
HEADSET_NOTFOUND = 0xd1
HEADSET_DISCONNECTED = 0xd2
REQUEST_DENIED = 0xd3
DONGLE_STANDBY = 0xd4
# Control Codes
SYNC = 0xaa
EXCODE = 0x55
# Singlebyte Codes
POOR_SIGNAL = 0x02
HEART_RATE = 0x03
ATTENTION = 0x04
MEDITATION = 0x05
BIT8_RAW = 0x06
RAW_MARKER = 0x07
# Multibyte Codes
RAW_WAVE = 0x80
EEG_POWER = 0x81
ASIC_EEG_POWER = 0x83
RRINTERVAL = 0x86

attr_accessor :headsetid, :device, :rate, :log

def initialize(headsetid=nil,device='/dev/ttyUSB0', rate=115200, log=Logger.new(STDOUT))
        @headsetid=headsetid
        @device=device
        @rate=rate
	@log=log
end

def test
        serial_open
        connect
        serial_close
end

# TODO: implement connection with headsetid
def connect(headsetid=nil)
        if not headsetid.nil?
                @headsetid = headsetid
        end

        if @headsetid.nil?
                autoconnect()
                return
        end

        cmd = BinData::Uint8be.new(Mindwave::Dongle::CONNECT)
        cmd.write(@conn)
end

def reader
        byte = 0
        tmpbyte = 0;

        while true
		log.debug("<<< START RECORD >>>")
                tmpbyte = logreadbyte

                if tmpbyte != Mindwave::Dongle::SYNC
			log.info(sprintf("LOST: %x\n",tmpbyte))
                        next
                else
                        tmpbyte = logreadbyte()
                        if tmpbyte != Mindwave::Dongle::SYNC
				log.info(sprintf("LOST: %x\n",tmpbyte))
                                next
                        end

                end
	
		while true
			plength = logreadbyte()
			if(plength != 170)
				break
			end
		end

		if(plength > 170)
			next
		end

		log.info(sprintf("plength: %d",plength))
		payload = Array.new(plength)
		checksum = 0
		(0..plength-1).each do |n|
			payload[n] = logreadbyte()
			checksum += payload[n]
		end

		checksum &= 0xff
		checksum = ~checksum & 0xff
		c = logreadbyte()

		if( c != checksum)
			log.info(sprintf("Checksum Error: %x - %x\n",c,checksum))
		else
			parse_payload(payload)
		end	
	
        end

end

def parse_payload(payload)
	if not payload.instance_of?Array or payload.nil?
		raise "Invalid Argument"
	end

	log.info("####### PARSE PAYLOAD #########")

	extcodelevel = 0

	code = payload[0]
	pl = payload[1,payload.length-1]
	
	# TODO: implement Extended-Code-Level-Support
	if code == Mindwave::Dongle::EXCODE
		extcodelevel += 1
		

		(1..payload.length).each do |n|
			if payload[n] == Mindwave::Dongle::EXCODE
				extcodelevel += 1
			else
				code = payload[n]
				pl = payload[n+1,payload.length-(n+1)]
				break
			end
		end
	end

	# some debugging output
	log.info(sprintf("extcodelevel: %x",extcodelevel))
	log.info(sprintf("Code: %x",code))
	log.info(sprintf("Length: %d",pl.length))
	pl.each do |n|
		log.debug(sprintf("payload: Hex: %x Dec: %d",n,n))
	end


	# SINGLE-BYTE-CODES
	if code < Mindwave::Dongle::RAW_WAVE or code >= Mindwave::Dongle::HEADSET_CONNECTED

		sbpayload = pl[0]
		codestr = ""

		case code
		when Mindwave::Dongle::HEADSET_CONNECTED
			codestr = "Headset connected"
		when Mindwave::Dongle::HEADSET_NOTFOUND
			codestr = "Headset not found"
		when Mindwave::Dongle::HEADSET_DISCONNECTED
			codestr = "Headset disconnected"
		when Mindwave::Dongle::REQUEST_DENIED
			codestr = "Request denied"
		when Mindwave::Dongle::DONGLE_STANDBY
			codestr = "Dongle standby"
		when Mindwave::Dongle::POOR_SIGNAL
			codestr = "Poor Signal"
		when Mindwave::Dongle::HEART_RATE
			codestr = "Heart Rate"
		when Mindwave::Dongle::ATTENTION
			codestr = "Attention"
		when Mindwave::Dongle::MEDITATION
			codestr = "Meditation"
		when Mindwave::Dongle::BIT8_RAW 
			codestr = "8Bit Raw"
		when Mindwave::Dongle::RAW_MARKER 
			codestr = "Raw Marker"
		else
			codestr = "Unknown"
		end

		log.info(sprintf("SINGLEBYTE-PAYLOAD: Code: %s Hex: %x - Dec: %d",codestr,sbpayload,sbpayload))

		# Re-Parse the rest of the payload 
		if pl.length > 1
			payload = pl[1,pl.length-1]
			parse_payload(payload)
		end

	# MULTI-BYTE-CODES
	else
		codestr = ""
		case code

		when Mindwave::Dongle::RAW_WAVE
			codestr = "RAW_WAVE Code detected"
		when Mindwave::Dongle::EEG_POWER
			codestr = "EEG Power"
		when Mindwave::Dongle::ASIC_EEG_POWER
			codestr = "ASIC EEG POWER"
		when Mindwave::Dongle::RRINTERVAL
			codestr = "RRINTERVAL"
		else
			codestr = "Unknown"
		end

		# Fetch the Multi-Payload
		plength = pl[0]
		log.info(sprintf("Multibyte-Code: %s",codestr))
		log.info(sprintf("Multibyte-Payload-Length: %d",pl[0]))
		mpl = pl[1,plength]
		mpl.each() do |n|
			log.info(sprintf("MULTIBYTE-PAYLOAD: Hex: %x - Dec: %d",n,n))
		end

		# Re-Parse the rest of the payload 
		if pl.length-1 > plength
			payload = pl[mpl.length+1,pl.length-mpl.length]
			parse_payload(payload)
		end
	end


end

def sendbyte(hexbyte)
	cmd = BinData::Uint8be.new(hexbyte)
	cmd.write(@conn)
end

def autoconnect
        cmd = BinData::Uint8be.new(Mindwave::Dongle::AUTOCONNECT)
        cmd.write(@conn)
end

def disconnect
        cmd = BinData::Uint8be.new(Mindwave::Dongle::DISCONNECT)
        cmd.write(@conn)
end


def serial_open
        @conn = SerialPort.new(device,rate)
end

def serial_close
        @conn.close
end


private

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

end
end
