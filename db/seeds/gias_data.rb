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

def populate_school(gias_school)
  school = gias_school.school
  closed_on = gias_school.closed_on || Date.current
  mentors = FactoryBot.create_list(:mentor_at_school_period, 2, :ongoing, :with_training_period, school:)
  mentees = FactoryBot.create_list(:ect_at_school_period, 2, :ongoing, :with_training_period, school:)
  mentors << FactoryBot.create(:mentor_at_school_period, :with_training_period, school:, started_on: 1.week.from_now)
  mentees << FactoryBot.create(:ect_at_school_period, :with_training_period, school:, started_on: 1.week.from_now)

  finished_dates = [closed_on - 1.day, nil, nil]
  (0..2).each do |i|
    mentee = mentees[i]
    mentor = mentors[i]
    finished_on = finished_dates[i]

    create_mentorship(mentee:, mentor:, finished_on:)
  end
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

populate_school(closed_school)
populate_school(monsters_college)
populate_school(primary_school)

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
