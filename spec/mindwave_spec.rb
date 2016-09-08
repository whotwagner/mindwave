require 'spec_helper'

describe Mindwave do
  let(:mw) {Mindwave::Headset.new}

  it 'has a version number' do
    expect(Mindwave::VERSION).not_to be nil
  end

it 'connects and disconnects' do
     mw.serial_open
     sleep(2)
     mw.connect
     sleep(5)
     mw.disconnect
     mw.serial_close

end

it 'test all' do
	puts "Serial open.."
     mw.log = Logger.new("mindwave.log")
	mw.serial_open
     sleep(2)
	puts "Connect.."
     mw.connect
     sleep(5)
     puts "Send Byte Attention"
     mw.sendbyte(0x01)
     sleep(2)
     puts "Reader..."
     require 'timeout'
     status = Timeout::timeout(15) {
     mw.run
     }
     puts "Disconnect"
     mw.disconnect
     puts "Serial close.."
     mw.serial_close

end

  it 'parses the payload' do
# D, [2016-09-07T20:53:01.403348 #20974] DEBUG -- : <<< START RECORD >>>
# D, [2016-09-07T20:53:01.403358 #20974] DEBUG -- : HEX: aa DEC: 170
# D, [2016-09-07T20:53:01.403366 #20974] DEBUG -- : HEX: aa DEC: 170
# D, [2016-09-07T20:53:01.403374 #20974] DEBUG -- : HEX: 20 DEC: 32
# I, [2016-09-07T20:53:01.403382 #20974]  INFO -- : plength: 32
# 
# D, [2016-09-07T20:53:01.403391 #20974] DEBUG -- : HEX: 2 DEC: 2
# D, [2016-09-07T20:53:01.403400 #20974] DEBUG -- : HEX: 1a DEC: 26
# D, [2016-09-07T20:53:01.403409 #20974] DEBUG -- : HEX: 83 DEC: 131
# D, [2016-09-07T20:53:01.403417 #20974] DEBUG -- : HEX: 18 DEC: 24
# D, [2016-09-07T20:53:01.403426 #20974] DEBUG -- : HEX: 5 DEC: 5
# D, [2016-09-07T20:53:01.403434 #20974] DEBUG -- : HEX: bd DEC: 189
# D, [2016-09-07T20:53:01.403443 #20974] DEBUG -- : HEX: c3 DEC: 195
# D, [2016-09-07T20:53:01.403451 #20974] DEBUG -- : HEX: 2 DEC: 2
# D, [2016-09-07T20:53:01.403460 #20974] DEBUG -- : HEX: 5c DEC: 92
# D, [2016-09-07T20:53:01.403468 #20974] DEBUG -- : HEX: 28 DEC: 40
# D, [2016-09-07T20:53:01.403477 #20974] DEBUG -- : HEX: 0 DEC: 0
# D, [2016-09-07T20:53:01.403497 #20974] DEBUG -- : HEX: a0 DEC: 160
# D, [2016-09-07T20:53:01.403506 #20974] DEBUG -- : HEX: e1 DEC: 225
# D, [2016-09-07T20:53:01.403518 #20974] DEBUG -- : HEX: 0 DEC: 0
# D, [2016-09-07T20:53:01.403527 #20974] DEBUG -- : HEX: 6f DEC: 111
# D, [2016-09-07T20:53:01.403536 #20974] DEBUG -- : HEX: ca DEC: 202
# D, [2016-09-07T20:53:01.403544 #20974] DEBUG -- : HEX: 1 DEC: 1
# D, [2016-09-07T20:53:01.403553 #20974] DEBUG -- : HEX: 8 DEC: 8
# D, [2016-09-07T20:53:01.403561 #20974] DEBUG -- : HEX: 2b DEC: 43
# D, [2016-09-07T20:53:01.403570 #20974] DEBUG -- : HEX: 0 DEC: 0
# D, [2016-09-07T20:53:01.403578 #20974] DEBUG -- : HEX: e1 DEC: 225
# D, [2016-09-07T20:53:01.403586 #20974] DEBUG -- : HEX: 9e DEC: 158
# D, [2016-09-07T20:53:01.403595 #20974] DEBUG -- : HEX: 0 DEC: 0
# D, [2016-09-07T20:53:01.403603 #20974] DEBUG -- : HEX: 77 DEC: 119
# D, [2016-09-07T20:53:01.403612 #20974] DEBUG -- : HEX: a0 DEC: 160
# D, [2016-09-07T20:53:01.403620 #20974] DEBUG -- : HEX: 0 DEC: 0
# D, [2016-09-07T20:53:01.403629 #20974] DEBUG -- : HEX: 2b DEC: 43
# D, [2016-09-07T20:53:01.403637 #20974] DEBUG -- : HEX: c7 DEC: 199
# D, [2016-09-07T20:53:01.403657 #20974] DEBUG -- : HEX: 4 DEC: 4
# D, [2016-09-07T20:53:01.403666 #20974] DEBUG -- : HEX: 25 DEC: 37
# D, [2016-09-07T20:53:01.403674 #20974] DEBUG -- : HEX: 5 DEC: 5
# D, [2016-09-07T20:53:01.403683 #20974] DEBUG -- : HEX: a DEC: 10
# D, [2016-09-07T20:53:01.403691 #20974] DEBUG -- : HEX: 8f DEC: 143

  	payload = Array.new(32)
	payload[0] = 0x02
	payload[1] = 0x1a
	payload[2] = 0x83
	payload[3] = 0x18
	payload[4] = 0x05
	payload[5] = 0xbd
	payload[6] = 0xc3
	payload[7] = 0x02
	payload[8] = 0x5c
	payload[9] = 0x28
	payload[10] = 0x00
	payload[11] = 0xa0
	payload[12] = 0xe1
	payload[13] = 0x00
	payload[14] = 0x6f
	payload[15] = 0xca
	payload[16] = 0x01
	payload[17] = 0x08
	payload[18] = 0x2b
	payload[19] = 0x00
	payload[20] = 0xe1
	payload[21] = 0x9e
	payload[22] = 0x00
	payload[23] = 0x77
	payload[24] = 0xa0
	payload[25] = 0x00
	payload[26] = 0x2b
	payload[27] = 0xc7
	payload[28] = 0x04
	payload[29] = 0x25
	payload[30] = 0x05
	payload[31] = 0x0a
	mw.parse_payload(payload)
  end
end
