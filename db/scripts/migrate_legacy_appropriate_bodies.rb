# As we remodel RIAB data we want to uncouple from imported legacy data
#
# Migrate fields necessary for analytics and an accurate paper trail for ABs
# that no longer use the service.
#
# NB: Migration for active ABs is facilitated by AppropriateBodyMigrator during login
#
ActiveRecord::Base.transaction do
  attributes =
    AppropriateBodyPeriod.legacy.map do |appropriate_body_period|
      {
        dqt_id: appropriate_body_period.dqt_id,
        name: appropriate_body_period.name,
        body_type: appropriate_body_period.body_type,
        appropriate_body_period_id: appropriate_body_period.id,
      }
    end

  LegacyAppropriateBody.insert_all(attributes)
end
