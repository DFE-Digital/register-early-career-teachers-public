if Rails.env.review? || Rails.env.staging?
  require Rails.root.join("db/seeds/support/seeds/reuse_choices")

  print_seed_info(
    "Seeding reuse choices scenario schools (staging only)",
    colour: :yellow,
    blank_lines_before: 1
  )

  # These reuse scenarios are intentionally tied to the 2025 contract period.
  # They represent fixed test data rather than current year behaviour,
  # so we avoid deriving from ContractPeriod.current to keep them stable over time.
  Seeds::ReuseChoices.new(contract_period_year: 2025).call
end
