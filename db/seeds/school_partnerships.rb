def describe_school_partnership(sp)
  delivery_partner_name = sp.lead_provider_delivery_partnership.delivery_partner.name
  lead_provider_name = sp.lead_provider_delivery_partnership.active_lead_provider.lead_provider.name
  registration_period_year = sp.lead_provider_delivery_partnership.active_lead_provider.registration_period.year
  school_name = "Some School" # sp.school.gias_school.name

  print_seed_info("#{school_name} has partnered with:")
  print_seed_info("🤝 lead provider: #{lead_provider_name}", indent: 4)
  print_seed_info("🤝 delivery partner: #{delivery_partner_name}", indent: 4)
  print_seed_info("🤝 registration period: #{registration_period_year}", indent: 4)
end

lead_provider_delivery_partnerships = LeadProviderDeliveryPartnership.eager_load(:delivery_partner, active_lead_provider: %i[lead_provider registration_period])

lead_provider_delivery_partnerships.each do |lead_provider_delivery_partnership|
  SchoolPartnership.create!(lead_provider_delivery_partnership:).tap { describe_school_partnership(it) }
end
