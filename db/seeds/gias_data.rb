def describe_school_link(school_link)
  link_type = Colourize.text(school_link.link_type, :blue)
  from_urn = Colourize.text(school_link.from_gias_school.urn, :yellow)
  to_urn = Colourize.text(school_link.to_gias_school.urn, :yellow)
  print_seed_info("🔗 #{link_type}: #{school_link.from_gias_school.name} (#{from_urn}) -> #{school_link.to_gias_school.name} (#{to_urn})", indent: 2)
end

def describe_mentorship_period(mp)
  mentor_name = Colourize.text("#{mp.mentor.teacher.trs_first_name} #{mp.mentor.teacher.trs_last_name}", :blue)
  ect_name = Colourize.text("#{mp.mentee.teacher.trs_first_name} #{mp.mentee.teacher.trs_last_name}", :yellow)

  print_seed_info("#{mentor_name} mentoring #{ect_name} at #{mp.mentor.school.gias_school.name}", indent: 2)
end

def teacher(...) = TeacherHistories::TeacherBuilder.teacher(...)

def populate_school(gias_school, counter = 0)
  school = gias_school.school
  closed_on = gias_school.closed_on || Date.current

  rp2025 = ContractPeriod.find_by!(year: 2025)
  rp2026 = ContractPeriod.find_by!(year: 2026)

  lead_provider = LeadProvider.find_by!(name: "Ambition Institute")
  delivery_partner = DeliveryPartner.find_by!(name: "Artisan Education Group")

  [rp2025, rp2026].each do |contract_period|
    active_lead_provider = ActiveLeadProvider.find_by!(lead_provider:, contract_period:)
    lead_provider_delivery_partnership = LeadProviderDeliveryPartnership.find_or_create_by!(active_lead_provider:, delivery_partner:)
    SchoolPartnership.find_or_create_by!(school:, lead_provider_delivery_partnership:)
  end

  start_dates = ["2025-09-05", "2025-12-05", 1.week.from_now.to_date.to_s]
  contract_periods = [2025, 2025, 2026]
  finished_dates = [closed_on - 1.day, nil, nil]

  mentees = []
  mentors = []

  2.times do |i|
    start_date = start_dates[i]
    contract_period = contract_periods[i]
    mentees << teacher(9_000_000 + counter, "Teacher #{counter += 1}") do
      ect_at_school_period(school, start_date) do
        training_period(lead_provider, contract_period, start_date)
      end
    end

    mentors << teacher(9_000_000 + counter, "Teacher #{counter += 1}") do
      mentor_at_school_period(school, start_date) do
        training_period(lead_provider, contract_period, start_date)
      end
    end
  end

  (0..1).each do |i|
    mentee = mentees[i].ect_at_school_periods.first
    mentor = mentors[i].mentor_at_school_periods.first
    finished_on = finished_dates[i]

    create_mentorship(mentee:, mentor:, finished_on:)
  end

  counter
end

def create_mentorship(mentee:, mentor:, finished_on:)
  started_on = [mentee.started_on, mentor.started_on].max

  attributes = { mentee:, mentor:, started_on:, finished_on: }.compact

  FactoryBot.create(:mentorship_period, **attributes).tap do |mentorship|
    describe_mentorship_period(mentorship)
  end
end

print_seed_info("\n🌱 GIAS Updates:")

print_seed_info("\n🐉 Creating Test Schools:")

monsters_college = FactoryBot.create(:gias_school, :with_school, :closed, closed_on: Date.new(2026, 4, 30), urn: 9_123_500, name: "Monsters College").tap do |school|
  describe_school(school)
end

school_of_excellence = FactoryBot.create(:gias_school, status: :open, opened_on: Date.new(2026, 4, 30), urn: 9_123_501, name: "Michael Wazowski School of Excellence").tap do |school|
  describe_school(school)
end

girls_high_school = FactoryBot.create(:gias_school, status: :open, opened_on: Date.new(2026, 4, 30), urn: 9_123_502, name: "Abigail Hardscrabble High School for Girls").tap do |school|
  describe_school(school)
end

primary_school = FactoryBot.create(:gias_school, :with_school, :closed, closed_on: Date.new(2026, 5, 31), urn: 9_123_503, name: "Monsters Primary School").tap do |school|
  describe_school(school)
end

prep_school = FactoryBot.create(:gias_school, status: :open, opened_on: Date.new(2026, 5, 31), urn: 9_123_504, name: "James P. Sullivan Preparatory School").tap do |school|
  describe_school(school)
end

closed_school = FactoryBot.create(:gias_school, :with_school, :closed, closed_on: Date.new(2026, 4, 30), urn: 9_123_505, name: "Frank McCay Technical College").tap do |school|
  describe_school(school)
end

open_school = FactoryBot.create(:gias_school, status: :open, opened_on: Date.new(2026, 3, 31), urn: 9_123_506, name: "Monsters Junior School").tap do |school|
  describe_school(school)
end

counter = 0

counter = populate_school(closed_school, counter)
counter = populate_school(monsters_college, counter)
populate_school(primary_school, counter)

print_seed_info("\n🌱 Closures:")
print_seed_info("🔒 #{Colourize.text(closed_school.name, :yellow)} (URN: #{Colourize.text(closed_school.urn, :yellow)}) closed on #{Colourize.text(closed_school.closed_on, :yellow)}", indent: 2)

print_seed_info("\n🌱 Openings:")
print_seed_info("🔓 #{Colourize.text(open_school.name, :yellow)} (URN: #{Colourize.text(open_school.urn, :yellow)}) opened on #{Colourize.text(open_school.opened_on, :yellow)}", indent: 2)

print_seed_info("\n🌱 Changes:")

FactoryBot.create(:gias_school_link,
                  :successor_unique,
                  from_gias_school: primary_school,
                  to_gias_school: prep_school).tap do |school_link|
  describe_school_link(school_link)
end

FactoryBot.create(:gias_school_link,
                  :successor_split,
                  from_gias_school: monsters_college,
                  to_gias_school: school_of_excellence).tap do |school_link|
  describe_school_link(school_link)
end

FactoryBot.create(:gias_school_link,
                  :successor_split,
                  from_gias_school: monsters_college,
                  to_gias_school: girls_high_school).tap do |school_link|
  describe_school_link(school_link)
end
