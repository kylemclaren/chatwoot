require 'rails_helper'

describe Twilio::IncomingMessageService do
  let!(:account) { create(:account) }
  let!(:twilio_sms) do
    create(:channel_twilio_sms, account: account, account_sid: 'ACxxx',
                                inbox: create(:inbox, account: account, greeting_enabled: false))
  end
  let!(:contact) { create(:contact, account: account, phone_number: '+12345') }
  let(:contact_inbox) { create(:contact_inbox, source_id: '+12345', contact: contact, inbox: twilio_sms.inbox) }
  let!(:conversation) { create(:conversation, contact: contact, inbox: twilio_sms.inbox, contact_inbox: contact_inbox) }

  describe '#perform' do
    it 'creates a new message in existing conversation' do
      params = {
        SmsSid: 'SMxx',
        From: '+12345',
        AccountSid: 'ACxxx',
        MessagingServiceSid: twilio_sms.messaging_service_sid,
        Body: 'testing3'
      }

      described_class.new(params: params).perform
      expect(conversation.reload.messages.last.content).to eq('testing3')
    end

    it 'creates a new conversation' do
      params = {
        SmsSid: 'SMxx',
        From: '+123456',
        AccountSid: 'ACxxx',
        MessagingServiceSid: twilio_sms.messaging_service_sid,
        Body: 'new conversation'
      }

      described_class.new(params: params).perform
      expect(Conversation.count).to eq(2)
    end

    context 'with a phone number' do
      let!(:twilio_sms) do
        create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'ACxxx',
                                                        inbox: create(:inbox, account: account, greeting_enabled: false))
      end

      it 'creates a new message in existing conversation' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          To: twilio_sms.phone_number,
          Body: 'testing3'
        }

        described_class.new(params: params).perform
        expect(conversation.reload.messages.last.content).to eq('testing3')
      end

      it 'creates a new conversation' do
        params = {
          SmsSid: 'SMxx',
          From: '+123456',
          AccountSid: 'ACxxx',
          To: twilio_sms.phone_number,
          Body: 'new conversation'
        }

        described_class.new(params: params).perform
        expect(Conversation.count).to eq(2)
      end
    end
  end
end
