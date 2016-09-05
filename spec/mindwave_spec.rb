require 'spec_helper'

describe Mindwave do
  let(:mw) {Mindwave::Dongle.new}

  it 'has a version number' do
    expect(Mindwave::VERSION).not_to be nil
  end

  it 'opens a serial connection' do
	mw.serial_open
  end

  it 'connects' do
  	sleep(2)
  	mw.connect()
  end

  it 'reads packets..' do
  	sleep(5)
	mw.reader
  end

  it 'disconnects..' do
  	mw.disconnect
  end

  it 'closes the serial connection' do
  	mw.serial_close
  end

  it 'test all' do
  	puts "Serial open.."
  	mw.serial_open
	sleep(2)
  	puts "Connect.."
	mw.connect
	sleep(5)
	puts "Reader..."
	mw.reader
	puts "Disconnect"
	mw.disconnect
	puts "Serial close.."
	mw.serial_close

  end
end
