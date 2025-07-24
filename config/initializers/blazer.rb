# Patch Blazer to use GOV.UK Notify for sending emails
module Blazer
  # @see https://github.com/dxw/mail-notify/blob/main/lib/mail/notify/mailer.rb#L31C11-L53
  # @see https://github.com/alphagov/notifications-ruby-client/blob/main/lib/notifications/client/request_error.rb#L30
  #
  # rubocop:disable Rails/ApplicationMailer
  class CheckMailer < ActionMailer::Base
    # @return [Mail::Message] with essential Notify variables
    def mail(*args)
      mail_message = super(*args)
      mail_message.template_id = ::ApplicationMailer::NOTIFY_TEMPLATE_ID
      mail_message.from = ::Blazer.from_email
      mail_message.personalisation = {
        subject: mail_message.subject,
        body: ::ReverseMarkdown.convert(mail_message.body.to_s)
      }
      mail_message
    end
  end
  # rubocop:enable Rails/ApplicationMailer
end
