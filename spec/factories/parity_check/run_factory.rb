FactoryBot.define do
  factory(:parity_check_run, class: "ParityCheck::Run") do
    started_at { Faker::Time.between(from: 2.days.ago, to: Time.current) }
  end
end
