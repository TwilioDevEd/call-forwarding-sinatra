require_relative '../spec_helper'

describe 'POST /callcongress/welcome' do
  it "generates TwiML to retrieve zipcode when from_state parameter is not present" do
    # given
    expect(TwimlGenerator).to receive(:gather_zipcode_and_look_it_up)
      .once
      .and_return('TwiML')

    # when
    post '/callcongress/welcome'

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    expect(last_response.body).to include('TwiML')
  end

  it "generates TwiML to confirm from_state parameter is not correct" do
    # given
    expect(TwimlGenerator).to receive(:confirm_from_state_attribute_is_correct)
      .with('PR')
      .once
      .and_return('TwiML')

    # when
    post '/callcongress/welcome', FromState: 'PR'

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    expect(last_response.body).to include('TwiML')
  end
end

describe '/callcongress/state-lookup' do
  it "generates TwiML to call both senators in state" do
    # given
    zipcode = Zipcode.new(id: 1, zipcode: 12345, state: 'PR')
    allow(Zipcode).to receive(:first)
      .with(anything)
      .and_return(zipcode)

    expect(State).to receive(:get_senators)
      .once
      .and_return(['senator1', 'senator2'])

    expect(TwimlGenerator).to receive(:dial_first_senator_then_connect_second)
      .with('senator1', 'senator2')
      .once
      .and_return('TwiML')

    # when
    post '/callcongress/state-lookup', Digits: "012345"

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    expect(last_response.body).to include('TwiML')
  end
end

describe '/callcongress/set-state' do
  it "generates TwiML to call both senators in state if Digits parameter is '1'" do
    # given
    expect(State).to receive(:get_senators)
      .once
      .and_return(['senator1', 'senator2'])

    expect(TwimlGenerator).to receive(:dial_first_senator_then_connect_second)
      .with('senator1', 'senator2')
      .once
      .and_return('TwiML')

    # when
    post '/callcongress/set-state', Digits: "1", FromState: "PR"

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    expect(last_response.body).to include('TwiML')
  end

  it "generates TwiML to collect zipcode if Digits parameter is '2'" do
    # given
    expect(TwimlGenerator).to receive(:gather_zipcode_and_look_it_up)
      .once
      .and_return('TwiML')

    # when
    post '/callcongress/set-state', Digits: "2", FromState: "PR"

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    expect(last_response.body).to include('TwiML')
  end
end

describe '/callcongress/call-second-senator/:senator_id' do
  it 'generates TwiML to call second senator' do
    # given
    senator = Senator.new(id: 1, name: 'senator1', phone: '+12345678')
    allow(Senator).to receive(:get)
      .with(anything)
      .and_return(senator)

    expect(TwimlGenerator).to receive(:dial_second_senator)
      .with(senator)
      .once
      .and_return('TwiML')

    # when
    post '/callcongress/call-second-senator/1'

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    expect(last_response.body).to include('TwiML')
  end
end

describe '/callcongress/goodbye' do
  it 'generates TwiML to hungup call' do
    # given
    expect(TwimlGenerator).to receive(:hangup_call)
      .once
      .and_return('TwiML')

    # when
    post '/callcongress/goodbye'

    # then
    expect(last_response).to be_ok
    expect(last_response.header['Content-Type']).to be =="text/xml;charset=utf-8"
    expect(last_response.body).to include('TwiML')
  end
end
