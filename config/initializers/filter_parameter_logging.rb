# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += %i[
  _key
  author_email
  author_name
  certificate
  commit
  corrected_name
  crypt
  date_of_birth
  email
  emails
  email_address
  first_name
  last_name
  name
  national_insurance_number
  otp
  otp_secret
  passw
  q
  salt
  secret
  ssn
  token
  trn
  trs_email_address
  trs_first_name
  trs_last_name
  trs_date_of_birth
  trs_national_insurance_number
]
