def describe_lead_provider(lp, years)
  years_description = if years.any?
                        Colourize.text(years.map(&:year).join(', '), :green)
                      else
                        Colourize.text('inactive', :red)
                      end
  print_seed_info("#{lp.name} (#{years_description})", indent: 2)
end

ambitious_institute = LeadProvider.create!(name: 'Ambitious Institute')
capitan = LeadProvider.create!(name: 'Capitan')
teach_fast = LeadProvider.create!(name: 'Teach Fast')
international_institute_of_teaching = LeadProvider.create!(name: 'International Institute of Teaching')
better_practice_network = LeadProvider.create!(name: 'Better Practice Network')

{
  capitan => [2021, 2022, 2023],
  ambitious_institute => [2022, 2023, 2024, 2025],
  teach_fast => [2022, 2023, 2024, 2025],
  better_practice_network => [2022, 2023, 2024, 2025],
  international_institute_of_teaching => [2021],
}.each do |lead_provider, registration_years|
  registration_periods = RegistrationPeriod.where(year: registration_years)
  registration_periods.each { |registration_period| ActiveLeadProvider.create!(registration_period:, lead_provider:) }

  describe_lead_provider(lead_provider, registration_periods)
end
