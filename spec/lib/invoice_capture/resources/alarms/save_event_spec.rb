require 'spec_helper'

describe InvoiceCapture::AlarmResource do

  let(:client) { InvoiceCapture::API.new(api_token: 'bogus_token') }
  let(:connection) { client.connection }
  let(:resource) { described_class.new(connection: connection) }

  describe '#save_event' do

    {
      invalid: { code: 400, exception: InvoiceCapture::InvalidRequest, message: 'Invalid JSON' },
      unauthorized: { code: 401, exception: InvoiceCapture::Unauthorized, message: 'Credentials are required to access this resource' },
      conflict: { code: 409, exception: InvoiceCapture::InvalidRequest, message: 'Random conflict error' },
      unprocessable: { code: 422, exception: InvoiceCapture::InvalidRequest, message: 'Unprocessable request' }
    }.each do |key, attrs|

      it "fails on #{key} error" do
        fixture = api_fixture("alarm/#{key}")
        stub_do_api("/alarms/something/events", :post).with(body: '{}').to_return(body: fixture, status: attrs[:code])
        params = {}
        expect {
          resource.save_event "something", params
        }.to raise_exception(attrs[:exception]).with_message("#{attrs[:code]}: #{attrs[:message]}")
      end

    end

    it 'uses an alarm event object' do
      fixture = api_fixture('alarm/save_event')
      parsed  = JSON.load(fixture)

      attrs = { gid: SecureRandom.uuid, origin: 'potatoes@farm.com', destination: 'onions@farm.com' }
      event = InvoiceCapture::AlarmEvent.new(attrs)
      stub_do_api("/alarms/something/events", :post).with(body: event.to_json).to_return(body: fixture, status: 201)
      event = resource.save_event "something", event

      expect(event).to be_kind_of(InvoiceCapture::AlarmEvent)

      expect(event.gid).to eq(parsed['gid'])
      expect(event.origin).to eq(parsed['origin'])
      expect(event.destination).to eq(parsed['destination'])
    end

    it 'uses an alarm event hash' do
      fixture = api_fixture('alarm/save_event')
      parsed  = JSON.load(fixture)

      attrs = { gid: SecureRandom.uuid, origin: 'potatoes@farm.com', destination: 'onions@farm.com' }
      stub_do_api("/alarms/something/events", :post).with(body: attrs.to_json).to_return(body: fixture, status: 201)
      event = resource.save_event "something", attrs

      expect(event).to be_kind_of(InvoiceCapture::AlarmEvent)

      expect(event.gid).to eq(parsed['gid'])
      expect(event.origin).to eq(parsed['origin'])
      expect(event.destination).to eq(parsed['destination'])
    end

  end

end