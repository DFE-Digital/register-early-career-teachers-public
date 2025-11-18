RSpec.describe 'Blazer' do
  describe 'Gov.uk compatible mailer' do
    subject(:message) do
      Blazer::CheckMailer.failing_checks('headteacher@school.com', []).deliver_now
    end

    let(:notify) do
      Mail::Notify::DeliveryMethod.new(api_key: "fake-key-#{SecureRandom.uuid}-#{SecureRandom.uuid}")
    end

    let(:mail_subject) { '0 Checks Failing' }

    let(:mail_body) do
      "[Manage checks](http://example.com/admin/blazer/checks)"
    end

    before do
      allow_any_instance_of(Notifications::Client).to receive(:send_email).with(
        email_address: 'headteacher@school.com',
        template_id: 'c437a1cb-9e1c-49ff-83ee-967c92f95637',
        personalisation: { subject: mail_subject, body: mail_body }
      ).and_return(kind_of(Notifications::Client::ResponseNotification))

      notify.deliver!(message)
    end

    it 'sends messages with template_id and personalisation variables' do
      expect(message.template_id).to eq(::ApplicationMailer::NOTIFY_TEMPLATE_ID)
      expect(message.personalisation).to eq({ subject: mail_subject, body: mail_body })
    end
  end
end
