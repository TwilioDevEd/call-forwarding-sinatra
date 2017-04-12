require_relative '../spec_helper'

describe 'GET /' do
  it 'renders' do
    get '/'

    expect(last_response).to be_ok
    expect(last_response.body).to include('Call 312-997-5372')
  end
end
