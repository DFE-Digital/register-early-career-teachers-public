require 'extensions/blazer/check_mailer'

# Patch Blazer to use GOV.UK Notify for sending emails
Blazer::CheckMailer.include Extensions::Blazer::CheckMailer
