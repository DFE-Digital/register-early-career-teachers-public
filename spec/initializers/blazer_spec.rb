RSpec.describe 'Blazer' do
  describe 'Gov.uk compatible mailer' do
    let(:message) do
      Blazer::CheckMailer.failing_checks('admin@example.com', []).deliver_now
    end

    let(:notify) do
      Mail::Notify::DeliveryMethod.new(api_key: ENV.fetch('GOVUK_NOTIFY_API_KEY'))
    end

    it 'sends a message with a template_id' do
      allow_any_instance_of(Notifications::Client).to receive(:send_email).with(
        email_address: 'admin@example.com',
        template_id: 'c437a1cb-9e1c-49ff-83ee-967c92f95637'
      ).and_return(kind_of(Notifications::Client::ResponseNotification))

      notify.deliver!(message)
    end
  end
end
