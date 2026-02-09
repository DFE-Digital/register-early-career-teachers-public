# As we remodel RIAB data we want to uncouple from imported legacy data
#
# Migrate fields necessary for analytics and an accurate paper trail for ABs
# that no longer use the service.
#
# NB: Migration for active ABs is facilitated by AppropriateBodyMigrator during login
#
ActiveRecord::Base.transaction do
  AppropriateBodyPeriod.legacy.each do |appropriate_body_period|
    LegacyAppropriateBody.find_or_create_by(
      dqt_id: appropriate_body_period.dqt_id,
      name: appropriate_body_period.name,
      body_type: appropriate_body_period.body_type,
      appropriate_body_period:
    )
  end
end
