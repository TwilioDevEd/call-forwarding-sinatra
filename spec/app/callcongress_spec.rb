require_relative '../spec_helper'

describe 'POST /callcongress/welcome' do
  it "generates TwiML to retrieve zipcode when from_state parameter is not present" do
    # when
    post '/callcongress/welcome'

    # then
    document = Nokogiri::XML(last_response.body)
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    expect(document.at_xpath('//Response//Say').content)
      .to eq("Thank you for calling Call Congress! If you wish to
                call your senators, please enter your 5-digit zip code.")
    expect(document.at_xpath('//Response//Gather/@action').content)
      .to eq('/callcongress/state-lookup')
  end

  it "generates TwiML to confirm from_state parameter is not correct" do
    # when
    post '/callcongress/welcome', FromState: 'PR'

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    document = Nokogiri::XML(last_response.body)
    expect(document.at_xpath('//Response//Say').content)
      .to eq("Thank you for calling congress! It looks like
                you\'re calling from PR.
                If this is correct, please press 1. Press 2 if
                this is not your current state of residence.")
    expect(document.at_xpath('//Response//Gather/@action').content)
      .to eq('/callcongress/set-state')
  end
end

describe '/callcongress/state-lookup' do
  it "generates TwiML to call both senators in state" do
    # given
    zipcode = Zipcode.new(id: 1, zipcode: 12345, state: 'PR')
    allow(Zipcode).to receive(:first)
      .and_return(zipcode)

    senator1 = Senator.new(id: 1, name: 'senator1', phone: '+1')
    senator2 = Senator.new(id: 2, name: 'senator2', phone: '+2')
    expect(State).to receive(:get_senators)
      .once
      .and_return([senator1, senator2])

    # when
    post '/callcongress/state-lookup', Digits: "012345"

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    document = Nokogiri::XML(last_response.body)
    expect(document.at_xpath('//Response//Say').content)
      .to eq("Connecting you to senator1. "\
             "After the senator's office ends the call, you will "\
             "be re-directed to senator2")
    expect(document.at_xpath('//Response//Dial/@action').content)
      .to eq('/callcongress/call-second-senator/2')
    expect(document.at_xpath('//Response//Dial').content).to eq('+1')
  end
end

describe '/callcongress/set-state' do
  it "generates TwiML to call both senators in state if Digits parameter is '1'" do
    # given
    senator1 = Senator.new(id: 1, name: 'senator1', phone: '+1')
    senator2 = Senator.new(id: 2, name: 'senator2', phone: '+2')
    expect(State).to receive(:get_senators)
      .once
      .and_return([senator1, senator2])

    # when
    post '/callcongress/set-state', Digits: "1", FromState: "PR"

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    document = Nokogiri::XML(last_response.body)
    expect(document.at_xpath('//Response//Say').content)
      .to eq("Connecting you to senator1. "\
             "After the senator's office ends the call, you will "\
             "be re-directed to senator2")
    expect(document.at_xpath('//Response//Dial/@action').content)
      .to eq('/callcongress/call-second-senator/2')
    expect(document.at_xpath('//Response//Dial').content).to eq('+1')
  end

  it "generates TwiML to collect zipcode if Digits parameter is '2'" do
    # when
    post '/callcongress/set-state', Digits: "2", FromState: "PR"

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    document = Nokogiri::XML(last_response.body)
    expect(document.at_xpath('//Response//Say').content)
      .to eq("If you wish to call your senators, please
              enter your 5-digit zip code.")
    expect(document.at_xpath('//Response//Gather/@action').content)
      .to eq('/callcongress/state-lookup')
  end
end

describe '/callcongress/call-second-senator/:senator_id' do
  it 'generates TwiML to call second senator' do
    # given
    senator = Senator.new(id: 1, name: 'senator1', phone: '+12345678')
    allow(Senator).to receive(:get)
      .with(anything)
      .and_return(senator)

    # when
    post '/callcongress/call-second-senator/1'

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    document = Nokogiri::XML(last_response.body)
    expect(document.at_xpath('//Response//Say').content)
      .to eq("Connecting you to senator1")
    expect(document.at_xpath('//Response//Dial/@action').content)
      .to eq('/callcongress/goodbye')
    expect(document.at_xpath('//Response//Dial').content).to eq('+12345678')
  end
end

describe '/callcongress/goodbye' do
  it 'generates TwiML to hungup call' do
    # when
    post '/callcongress/goodbye'

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    document = Nokogiri::XML(last_response.body)
    expect(document.at_xpath('//Response//Say').content)
      .to eq("Thank you for using Call Congress!
               Your voice makes a difference. Goodbye.")
    expect(document.at_xpath('//Response//Hangup')).to be_truthy
  end
end
