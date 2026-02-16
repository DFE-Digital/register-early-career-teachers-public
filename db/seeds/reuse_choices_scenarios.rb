if Rails.env.staging? || Rails.env.development? || Rails.env.review?
  require Rails.root.join("db/seeds/support/seeds/reuse_choices")

  print_seed_info(
    "Seeding reuse choices scenario schools (staging only)",
    colour: :yellow,
    blank_lines_before: 1
  )

  Seeds::ReuseChoices.new(contract_period_year: 2025).call
end
