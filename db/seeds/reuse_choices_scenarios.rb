require Rails.root.join("db/seeds/support/seeds/reuse_choices")

return unless Rails.env.staging? || Rails.env.development? || Rails.env.review?

Rails.logger.debug "Seeding reuse choices scenario schools (staging only)"

Seeds::ReuseChoices.new(contract_period_year: 2025).call
