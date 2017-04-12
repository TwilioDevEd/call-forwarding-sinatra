module TwimlGenerator
  def self.confirm_from_state_attribute_is_correct(from_state)
    Twilio::TwiML::Response.new do |r|
      r.Say "Thank you for calling congress! It looks like
            you\'re calling from #{from_state}.
            If this is correct, please press 1. Press 2 if
            this is not your current state of residence."
      r.Gather numDigits: 1,
               action: '/callcongress/set-state',
               method: 'POST',
               from_state: from_state
    end.to_xml
  end

  def self.gather_zipcode_and_look_it_up(message)
    Twilio::TwiML::Response.new do |r|
      r.Say message
      r.Gather numDigits: 5,
               action: '/callcongress/state-lookup',
               method: 'POST'
    end.to_xml
  end

  def self.dial_second_senator(senator)
    Twilio::TwiML::Response.new do |r|
      r.Say "Connecting you to #{senator.name}"
      r.Dial senator.phone, action: "/callcongress/goodbye"
    end.to_xml
  end

  def self.hangup_call()
    Twilio::TwiML::Response.new do |r|
      e.Say "Thank you for using Call Congress!
             Your voice makes a difference. Goodbye."
      e.Hangup
    end.to_xml
  end

  def self.dial_first_senator_then_connect_second(first_call, second_call)
    Twilio::TwiML::Response.new do |r|
      r.Say "Connecting you to #{first_call.name}.
            After the senator's office ends the call, you will
            be re-directed to #{second_call.name}"
      r.Dial first_call.phone,
             action: "/callcongress/call-second-senator/#{second_call.id}"
    end.to_xml
  end
end
