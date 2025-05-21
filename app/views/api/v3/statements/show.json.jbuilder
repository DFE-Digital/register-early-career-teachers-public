json.id @statement.api_id
json.type "statement"

json.attributes do
  json.month Date::MONTHNAMES[@statement.month]
  json.year @statement.year.to_s
  json.cohort @statement.active_lead_provider.registration_period.year.to_s
  json.cut_off_date @statement.deadline_date&.iso8601
  json.payment_date @statement.payment_date&.iso8601
  json.paid @statement.paid?
  json.created_at @statement.created_at&.rfc3339
  json.updated_at @statement.updated_at&.rfc3339
end
