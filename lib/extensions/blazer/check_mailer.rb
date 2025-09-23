module Extensions
  module Blazer
    module CheckMailer
      # @see https://github.com/dxw/mail-notify/blob/main/lib/mail/notify/mailer.rb#L31C11-L53
      # @see https://github.com/alphagov/notifications-ruby-client/blob/main/lib/notifications/client/request_error.rb#L30
      #
      # @return [Mail::Message] with essential Notify variables
      def mail(*args)
        mail_message = super(*args)
        mail_message.template_id = ::ApplicationMailer::NOTIFY_TEMPLATE_ID
        mail_message.from = ::Blazer.from_email
        mail_message.personalisation = {
          subject: mail_message.subject,
          body: "[Manage checks](#{root_url}checks)",
        }
        mail_message
      end
    end
  end
end
