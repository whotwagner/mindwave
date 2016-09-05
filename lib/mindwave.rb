require "mindwave/version"

require 'serialport' 
require 'bindata'

module Mindwave

class Dongle
CONNECT = 0xc0
DISCONNECT = 0xc1
AUTOCONNECT = 0xc2
SYNC = 0xaa
ATTENTION = 0x04
RAW_WAVE = 0x80

attr_accessor :headsetid, :device, :rate

def initialize(headsetid=nil,device='/dev/ttyUSB0', rate=115200)
        @headsetid=headsetid
        @device=device
        @rate=rate
end

def test
        serial_open
        connect
        serial_close
end

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
                tmpbyte = @conn.readbyte

                if tmpbyte != Mindwave::Dongle::SYNC
                        printf("LOST: %x\n",tmpbyte)
                        next
                else
                        tmpbyte = @conn.readbyte
                        if tmpbyte != Mindwave::Dongle::SYNC
                                printf("LOST: %x\n",tmpbyte)
                                next
                        end

                end


                code1 = @conn.readbyte
                code2 = @conn.readbyte
                if code1 == Mindwave::Dongle::ATTENTION
                        puts "Attention"
                else
                        printf("Code1: %x\n",code1)
                end

                if code2 == Mindwave::Dongle::RAW_WAVE
                        puts "Raw Wave"
                else
                        printf("Code2: %x\n",code2)
                end

                packlen = @conn.readbyte
                # puts "Packet Length: #{packlen}\n"
                (1..packlen).each do |n|
#       printf("%x\n",@conn.readbyte)
                end
        end

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

end
end
