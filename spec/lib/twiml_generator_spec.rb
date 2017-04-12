require 'nokogiri'
require_relative '../spec_helper'
require_relative '../../lib/twiml_generator'

describe TwimlGenerator do
  describe '.confirm_from_state_attribute_is_correct' do
    before do
      xml_string = described_class.confirm_from_state_attribute_is_correct("PR")
      @document = Nokogiri::XML(xml_string)
    end

    it 'generates TwiML with Say' do
      expect(@document.at_xpath('//Response//Say').content)
        .to eq("Thank you for calling congress! It looks like
            you\'re calling from PR.
            If this is correct, please press 1. Press 2 if
            this is not your current state of residence.")
    end

    it 'generates TwiML with Gather and the proper action url' do
          expect(@document.at_xpath('//Response//Gather/@action').content)
            .to eq('/callcongress/set-state')
    end
  end

  describe '.gather_zipcode_and_look_it_up' do
    before do
      xml_string = described_class.gather_zipcode_and_look_it_up("message")
      @document = Nokogiri::XML(xml_string)
    end

    it 'generates TwiML with Say' do
      expect(@document.at_xpath('//Response//Say').content)
        .to eq("message")
    end

    it 'generates TwiML with Gather and the proper action url' do
          expect(@document.at_xpath('//Response//Gather/@action').content)
            .to eq('/callcongress/state-lookup')
    end
  end

  describe '.dial_second_senator' do
    before do
      senator = Senator.new(id: 1, name: 'senator1', phone: '+12345678')
      xml_string = described_class.dial_second_senator(senator)
      @document = Nokogiri::XML(xml_string)
    end

    it 'generates TwiML with Say' do
      expect(@document.at_xpath('//Response//Say').content)
        .to eq("Connecting you to senator1")
    end

    it 'generates TwiML with Dial' do
          expect(@document.at_xpath('//Response//Dial/@action').content)
            .to eq('/callcongress/goodbye')
          expect(@document.at_xpath('//Response//Dial').content).to eq('+12345678')
    end
  end

  describe '.hangup_call' do
    before do
      xml_string = described_class.hangup_call
      @document = Nokogiri::XML(xml_string)
    end

    it 'generates TwiML with Say and Hangup' do
      expect(@document.at_xpath('//Response//Say').content)
        .to eq("Thank you for using Call Congress!
             Your voice makes a difference. Goodbye.")
      expect(@document.at_xpath('//Response//Hangup')).to be_truthy
    end
  end

  describe '.dial_first_senator_then_connect_second' do
    before do
      senator1 = Senator.new(id: 1, name: 'senator1', phone: '+1')
      senator2 = Senator.new(id: 2, name: 'senator2', phone: '+2')
      xml_string = described_class.dial_first_senator_then_connect_second(senator1, senator2)
      @document = Nokogiri::XML(xml_string)
    end

    it 'generates TwiML with Say' do
      expect(@document.at_xpath('//Response//Say').content)
        .to eq("Connecting you to senator1.
            After the senator's office ends the call, you will
            be re-directed to senator2")
    end

    it 'generates TwiML with Dial' do
          expect(@document.at_xpath('//Response//Dial/@action').content)
            .to eq('/callcongress/call-second-senator/2')
          expect(@document.at_xpath('//Response//Dial').content).to eq('+1')
    end
  end
end
