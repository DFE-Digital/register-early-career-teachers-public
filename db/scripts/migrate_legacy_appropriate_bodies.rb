# Iterate over ABs that will not be able to authenticate and generate ±400 new model records
#
ActiveRecord::Base.transaction do
  AppropriateBody.inactive.each do |appropriate_body_period|
    LegacyAppropriateBody.find_or_create_by(
      dqt_id: appropriate_body_period.dqt_id,
      name: appropriate_body_period.name,
      body_type: appropriate_body_period.body_type,
      appropriate_body_period:
    )
  end
end
