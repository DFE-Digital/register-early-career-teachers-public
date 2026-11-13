def describe_induction_platform(induction_platform)
  print_seed_info("#{induction_platform.name} (#{induction_platform.authorizations.active.count} active authorisations)", indent: 2)
end

alpha_platform = FactoryBot.create(:api_oauth_client, name: "Alpha Induction Platform")
beta_platform = FactoryBot.create(:api_oauth_client, name: "Beta Induction Platform")
gamma_platform = FactoryBot.create(:api_oauth_client, name: "Gamma Induction Platform")

appropriate_body_periods = AppropriateBodyPeriod.active.order(:name).first(5)

[
  { client: alpha_platform, appropriate_body_period: appropriate_body_periods[0], granted_by_name: "Sarah Jones", created_at: 3.months.ago, traits: [:with_token] },
  { client: alpha_platform, appropriate_body_period: appropriate_body_periods[1], granted_by_name: "Sanjay Patel", created_at: 2.months.ago, traits: [:with_token] },
  { client: alpha_platform, appropriate_body_period: appropriate_body_periods[2], granted_by_name: "Amara Okafor", created_at: 2.weeks.ago, traits: [:with_token] },
  { client: alpha_platform, appropriate_body_period: appropriate_body_periods[3], granted_by_name: "Revoked Grant", created_at: 4.months.ago, traits: %i[with_token revoked] },
  { client: alpha_platform, appropriate_body_period: appropriate_body_periods[4], granted_by_name: "Expired Grant", created_at: 13.months.ago, traits: [:with_expired_token] },
  { client: beta_platform, appropriate_body_period: appropriate_body_periods[3], granted_by_name: "Tom Hughes", created_at: 5.weeks.ago, traits: [:with_token] },
  { client: beta_platform, appropriate_body_period: appropriate_body_periods[4], granted_by_name: "Grace Lee", created_at: 1.week.ago, traits: [:with_token] },
].each do |attributes|
  traits = attributes.delete(:traits)
  FactoryBot.create(:api_oauth_authorization, *traits, **attributes)
end

[alpha_platform, beta_platform, gamma_platform].each { describe_induction_platform(it) }
