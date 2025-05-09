ECT_COLOUR = :magenta
MENTOR_COLOUR = :yellow

def print_seed_info(text, indent: 0, colour: nil)
  if colour
    puts "🌱 " + (" " * indent) + Colourize.text(text, colour)
  else
    puts "🌱 " + (" " * indent) + text
  end
end

def teacher_name(teacher)
  Teachers::Name.new(teacher).full_name
end

def describe_period_duration(period)
  period.finished_on ? "between #{period.started_on} and #{period.finished_on}" : "since #{period.started_on}"
end

def describe_mentorship_period(mp)
  mentor_name = Colourize.text("#{mp.mentor.teacher.trs_first_name} #{mp.mentor.teacher.trs_last_name}", MENTOR_COLOUR)
  ect_name = Colourize.text("#{mp.mentee.teacher.trs_first_name} #{mp.mentee.teacher.trs_last_name}", ECT_COLOUR)

  print_seed_info("#{mentor_name} mentoring #{ect_name} at #{mp.mentor.school.gias_school.name} #{describe_period_duration(mp)}", indent: 2)
end

def describe_school_partnership(pp)
  print_seed_info("#{pp.lead_provider.name} (LP) 🤝 #{pp.delivery_partner.name} (DP) in #{pp.registration_period.year}", indent: 2)
end

def describe_lead_provider(lp)
  print_seed_info(lp.name, indent: 2)
end

def describe_delivery_partner(dp)
  print_seed_info(dp.name, indent: 2)
end

def describe_registration_period(ay)
  print_seed_info("#{ay.year} (running from #{ay.started_on} until #{ay.finished_on})", indent: 2)
end

def describe_induction_period(ip)
  suffix = "(induction period)"

  print_seed_info("* is having their induction overseen by #{ip.appropriate_body.name} (AB) #{describe_period_duration(ip)} #{suffix}", indent: 4)

  author_attributes = {
    author_email: 'fkend@appropriate-body.org',
    author_name: 'Felicity Kendall',
    author_type: 'appropriate_body_user',
  }

  Event.create!(
    event_type: 'induction_period_opened',
    induction_period: ip,
    teacher: ip.teacher,
    appropriate_body: ip.appropriate_body,
    heading: "#{teacher_name(ip.teacher)} was claimed by #{ip.appropriate_body.name}",
    happened_at: ip.started_on.at_midday + rand(-300..300).minutes,
    **author_attributes
  )

  if ip.finished_on
    Event.create!(
      event_type: 'induction_period_opened',
      induction_period: ip,
      teacher: ip.teacher,
      appropriate_body: ip.appropriate_body,
      heading: "#{teacher_name(ip.teacher)} was released by #{ip.appropriate_body.name}",
      happened_at: ip.finished_on.at_midday + rand(-300..300).minutes,
      **author_attributes
    )
  end
end

def describe_training_period(tp)
  pp = tp.school_partnership
  suffix = "(training period)"

  print_seed_info("* was trained by #{pp.lead_provider.name} (LP) and #{pp.delivery_partner.name} #{describe_period_duration(tp)} #{suffix}", indent: 4)
end

def describe_ect_at_school_period(sp)
  suffix = "(ECT at school period)"

  print_seed_info("* has been an ECT at #{sp.school.name} #{describe_period_duration(sp)} #{suffix}", indent: 4)
end

def describe_mentor_at_school_period(sp)
  suffix = "(mentor at school period)"

  print_seed_info("* was a mentor at #{sp.school.name} from #{sp.started_on} #{describe_period_duration(sp)} #{suffix}", indent: 4)
end

def describe_extension(ext)
  suffix = "(extension)"

  print_seed_info("* had their induction extended by #{ext.number_of_terms} #{suffix}", indent: 4)
end

def describe_pending_induction_submission(pending_induction_submission)
  suffix = "(pending_induction_submission)"

  print_seed_info("* has one pending induction submission from #{pending_induction_submission.appropriate_body.name} #{suffix}", indent: 4)
end

def describe_user(user)
  print_seed_info("Added DfE staff user #{user.name} #{user.email}", indent: 2)
end

def describe_teacher(teacher)
  teacher_name = "#{teacher.trs_first_name} #{teacher.trs_last_name}"

  ero_status = if teacher.mentor_became_ineligible_for_funding_reason == 'completed_during_early_roll_out'
                 Colourize.text('yes', :green)
               else
                 Colourize.text('no', :red)
               end

  print_seed_info("#{teacher_name} (early roll out mentor: #{ero_status})", indent: 2)
end

print_seed_info("Adding teachers")

early_roll_out_mentor_attrs = { mentor_became_ineligible_for_funding_reason: 'completed_during_early_roll_out', mentor_became_ineligible_for_funding_on: Date.new(2021, 4, 19) }

emma_thompson = Teacher.create!(trs_first_name: 'Emma', trs_last_name: 'Thompson', trn: '1023456').tap { |t| describe_teacher(t) }
kate_winslet = Teacher.create!(trs_first_name: 'Kate', trs_last_name: 'Winslet', trn: '1023457').tap { |t| describe_teacher(t) }
alan_rickman = Teacher.create!(trs_first_name: 'Alan', trs_last_name: 'Rickman', trn: '2084589').tap { |t| describe_teacher(t) }
hugh_grant = Teacher.create!(trs_first_name: 'Hugh', trs_last_name: 'Grant', trn: '3657894').tap { |t| describe_teacher(t) }
colin_firth = Teacher.create!(trs_first_name: 'Colin', trs_last_name: 'Firth', trn: '1237894').tap { |t| describe_teacher(t) }
harriet_walter = Teacher.create!(trs_first_name: 'Harriet', trs_last_name: 'Walter', trn: '2017654', **early_roll_out_mentor_attrs).tap { |t| describe_teacher(t) }
hugh_laurie = Teacher.create!(trs_first_name: 'Hugh', trs_last_name: 'Laurie', trn: '4786654', **early_roll_out_mentor_attrs).tap { |t| describe_teacher(t) }
stephen_fry = Teacher.create!(trs_first_name: 'Stephen', trs_last_name: 'Fry', trn: '4786655').tap { |t| describe_teacher(t) }
andre_roussimoff = Teacher.create!(trs_first_name: 'André', trs_last_name: 'Roussimoff', trn: '8886654').tap { |t| describe_teacher(t) }
imogen_stubbs = Teacher.create!(trs_first_name: 'Imogen', trs_last_name: 'Stubbs', trn: '6352869').tap { |t| describe_teacher(t) }
gemma_jones = Teacher.create!(trs_first_name: 'Gemma', trs_last_name: 'Jones', trn: '9578426').tap { |t| describe_teacher(t) }
anthony_hopkins = Teacher.create!(trs_first_name: 'Anthony', trs_last_name: 'Hopkins', trn: '6228282').tap { |t| describe_teacher(t) }
john_withers = Teacher.create!(trs_first_name: 'John', trs_last_name: 'Withers', corrected_name: 'Old Man Withers', trn: '8590123')
helen_mirren = Teacher.create!(trs_first_name: 'Helen', trs_last_name: 'Mirren', corrected_name: 'Dame Helen Mirren', trn: '0000007')

# these teachers map to records in TRS pre-prod
_robson_scottie = Teacher.create!(trs_first_name: 'Robson', trs_last_name: 'Scottie', trn: '3002582', **early_roll_out_mentor_attrs).tap { |t| describe_teacher(t) }
_muhammed_ali = Teacher.create!(trs_first_name: 'Muhammed', trs_last_name: 'Ali', trn: '3002580', **early_roll_out_mentor_attrs).tap { |t| describe_teacher(t) }

print_seed_info("Adding schools")

school_data = [
  { urn: 3_375_958, name: "Ackley Bridge" },
  { urn: 1_759_427, name: "Abbey Grove School" },
  { urn: 2_472_261, name: "Grange Hill" },
  { urn: 3_583_173, name: "Coal Hill School" },
  { urn: 5_279_293, name: "Malory Towers" },
  { urn: 2_921_596, name: "St Clare's School" },
  { urn: 2_976_163, name: "Brookfield School" },
  { urn: 4_594_193, name: "Crunchem Hall Primary School" },
  { urn: 6_384_201, name: "Greyfriars School" }
]

schools = school_data.map do |school_args|
  # FIXME: this is a bit nasty but gets the seeds working again
  GIAS::School.create!(school_args.merge(funding_eligibility: :eligible_for_fip,
                                         induction_eligibility: :eligible,
                                         local_authority_code: rand(20),
                                         establishment_number: school_args[:urn],
                                         type_name: school_args[:name] == 'Brookfield School' ? GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.sample : GIAS::Types::STATE_SCHOOL_TYPES.sample,
                                         in_england: true,
                                         section_41_approved: false))

  School.create!(school_args.except(:name))
end

schools_indexed_by_urn = schools.index_by(&:urn)

ackley_bridge = schools_indexed_by_urn.fetch(3_375_958)
abbey_grove_school = schools_indexed_by_urn.fetch(1_759_427)
mallory_towers = schools_indexed_by_urn.fetch(5_279_293)
brookfield_school = schools_indexed_by_urn.fetch(2_976_163)

print_seed_info("Adding appropriate bodies")

AppropriateBody.create!(body_type: 'national', name: AppropriateBodies::Search::ISTIP, local_authority_code: 50, dfe_sign_in_organisation_id: "203606a4-4199-46a9-84e4-56fbc5da2a36", dqt_id: "6ae042bb-c7ae-e311-b8ed-005056822391")
AppropriateBody.create!(body_type: 'teaching_school_hub', name: 'Canvas Teaching School Hub', local_authority_code: 109, establishment_number: 2367)
south_yorkshire_studio_hub = AppropriateBody.create!(body_type: 'teaching_school_hub', name: 'South Yorkshire Studio Hub', local_authority_code: 678, establishment_number: 9728)
AppropriateBody.create!(body_type: 'teaching_school_hub', name: 'Ochre Education Partnership', local_authority_code: 238, establishment_number: 6582)
umber_teaching_school_hub = AppropriateBody.create!(body_type: 'teaching_school_hub', name: 'Umber Teaching School Hub', local_authority_code: 957, establishment_number: 7361, dfe_sign_in_organisation_id: 'd245ec79-534e-4547-a7e4-ccd98803b627')
golden_leaf_teaching_school_hub = AppropriateBody.create!(body_type: 'teaching_school_hub', name: 'Golden Leaf Teaching School Hub', local_authority_code: 648, establishment_number: 3986)
AppropriateBody.create!(body_type: 'teaching_school_hub', name: 'Frame University London', local_authority_code: 832, establishment_number: 6864)
AppropriateBody.create!(body_type: 'teaching_school_hub', name: 'Easelcroft Teaching School Hub', local_authority_code: 573, establishment_number: 9273)
AppropriateBody.create!(body_type: 'teaching_school_hub', name: 'Vista College', local_authority_code: 418, establishment_number: 3735)

active_appropriate_bodies = [umber_teaching_school_hub, golden_leaf_teaching_school_hub]

print_seed_info("Adding lead providers")

grove_institute = LeadProvider.create!(name: 'Grove Institute').tap { |dp| describe_lead_provider(dp) }
LeadProvider.create!(name: 'Evergreen Network').tap { |dp| describe_lead_provider(dp) }
national_meadows_institute = LeadProvider.create!(name: 'National Meadows Institute').tap { |dp| describe_lead_provider(dp) }
LeadProvider.create!(name: 'Woodland Education Trust').tap { |dp| describe_lead_provider(dp) }
LeadProvider.create!(name: 'Teach Orchard').tap { |dp| describe_lead_provider(dp) }
LeadProvider.create!(name: 'Highland College University').tap { |dp| describe_lead_provider(dp) }
wildflower_trust = LeadProvider.create!(name: 'Wildflower Trust').tap { |dp| describe_lead_provider(dp) }
LeadProvider.create!(name: 'Pine Institute').tap { |dp| describe_lead_provider(dp) }

print_seed_info("Adding delivery partners")

DeliveryPartner.create!(name: 'Rise Teaching School Hub').tap { |dp| describe_delivery_partner(dp) }
DeliveryPartner.create!(name: 'Miller Teaching School Hub').tap { |dp| describe_delivery_partner(dp) }
grain_teaching_school_hub = DeliveryPartner.create!(name: 'Grain Teaching School Hub').tap { |dp| describe_delivery_partner(dp) }
artisan_education_group = DeliveryPartner.create!(name: 'Artisan Education Group').tap { |dp| describe_delivery_partner(dp) }
rising_minds = DeliveryPartner.create!(name: 'Rising Minds Network').tap { |dp| describe_delivery_partner(dp) }
DeliveryPartner.create!(name: 'Proving Potential Teaching School Hub').tap { |dp| describe_delivery_partner(dp) }
DeliveryPartner.create!(name: 'Harvest Academy').tap { |dp| describe_delivery_partner(dp) }

print_seed_info("Adding registration periods")

registration_period_2021 = RegistrationPeriod.create!(year: 2021, started_on: Date.new(2021, 6, 1), finished_on: Date.new(2022, 5, 31), enabled: false).tap { |ay| describe_registration_period(ay) }
registration_period_2022 = RegistrationPeriod.create!(year: 2022, started_on: Date.new(2022, 6, 1), finished_on: Date.new(2023, 5, 31), enabled: false).tap { |ay| describe_registration_period(ay) }
registration_period_2023 = RegistrationPeriod.create!(year: 2023, started_on: Date.new(2023, 6, 1), finished_on: Date.new(2024, 5, 31), enabled: true).tap { |ay| describe_registration_period(ay) }
registration_period_2024 = RegistrationPeriod.create!(year: 2024, started_on: Date.new(2024, 6, 1), finished_on: Date.new(2025, 5, 31), enabled: true).tap { |ay| describe_registration_period(ay) }
_registration_period_2025 = RegistrationPeriod.create!(year: 2025, started_on: Date.new(2025, 6, 1), finished_on: Date.new(2026, 5, 31), enabled: true).tap { |ay| describe_registration_period(ay) }

print_seed_info("Adding provider partnerships")

grove_artisan_partnership_2021 = SchoolPartnership.create!(
  registration_period: registration_period_2021,
  lead_provider: grove_institute,
  delivery_partner: artisan_education_group
).tap { |pp| describe_school_partnership(pp) }

SchoolPartnership.create!(
  registration_period: registration_period_2022,
  lead_provider: grove_institute,
  delivery_partner: artisan_education_group
).tap { |pp| describe_school_partnership(pp) }

grove_artisan_partnership_2023 = SchoolPartnership.create!(
  registration_period: registration_period_2023,
  lead_provider: grove_institute,
  delivery_partner: artisan_education_group
).tap { |pp| describe_school_partnership(pp) }

meadow_grain_partnership_2022 = SchoolPartnership.create!(
  registration_period: registration_period_2022,
  lead_provider: national_meadows_institute,
  delivery_partner: grain_teaching_school_hub
).tap { |pp| describe_school_partnership(pp) }

_meadow_grain_partnership_2023 = SchoolPartnership.create!(
  registration_period: registration_period_2023,
  lead_provider: national_meadows_institute,
  delivery_partner: grain_teaching_school_hub
).tap { |pp| describe_school_partnership(pp) }

_wildflower_rising_partnership_2023 = SchoolPartnership.create!(
  registration_period: registration_period_2023,
  lead_provider: wildflower_trust,
  delivery_partner: rising_minds
).tap { |pp| describe_school_partnership(pp) }

_wildflower_rising_partnership_2024 = SchoolPartnership.create!(
  registration_period: registration_period_2024,
  lead_provider: wildflower_trust,
  delivery_partner: rising_minds
).tap { |pp| describe_school_partnership(pp) }

print_seed_info("Adding teacher histories:")

print_seed_info("Emma Thompson (mentor)", indent: 2, colour: MENTOR_COLOUR)

emma_thompson_mentoring_at_abbey_grove = MentorAtSchoolPeriod.create!(
  teacher: emma_thompson,
  school: abbey_grove_school,
  email: 'emma.thompson@matilda.com',
  started_on: 3.years.ago
).tap { |sp| describe_mentor_at_school_period(sp) }

TrainingPeriod.create!(
  mentor_at_school_period: emma_thompson_mentoring_at_abbey_grove,
  started_on: 3.years.ago,
  finished_on: 140.weeks.ago,
  school_partnership: grove_artisan_partnership_2021
).tap { |tp| describe_training_period(tp) }

# 10 week break

TrainingPeriod.create!(
  mentor_at_school_period: emma_thompson_mentoring_at_abbey_grove,
  started_on: 130.weeks.ago,
  finished_on: nil,
  school_partnership: grove_artisan_partnership_2021
).tap { |tp| describe_training_period(tp) }

print_seed_info("Kate Winslet (ECT)", indent: 2, colour: ECT_COLOUR)

kate_winslet_ect_at_ackley_bridge = ECTAtSchoolPeriod.create!(
  teacher: kate_winslet,
  school: ackley_bridge,
  email: 'kate.winslet@titanic.com',
  started_on: 1.year.ago,
  lead_provider: nil,
  school_reported_appropriate_body: golden_leaf_teaching_school_hub,
  working_pattern: 'full_time',
  programme_type: 'school_led'
).tap { |sp| describe_ect_at_school_period(sp) }

TrainingPeriod.create!(
  ect_at_school_period: kate_winslet_ect_at_ackley_bridge,
  started_on: 1.year.ago,
  school_partnership: grove_artisan_partnership_2023
).tap { |tp| describe_training_period(tp) }

InductionPeriod.create!(
  teacher: kate_winslet,
  started_on: 3.years.ago,
  finished_on: 2.years.ago,
  number_of_terms: 3,
  appropriate_body: golden_leaf_teaching_school_hub,
  induction_programme: 'fip'
).tap { |ip| describe_induction_period(ip) }

InductionPeriod.create!(
  teacher: kate_winslet,
  started_on: 1.year.ago,
  appropriate_body: umber_teaching_school_hub,
  induction_programme: 'fip'
).tap { |ip| describe_induction_period(ip) }

print_seed_info("Hugh Laurie (mentor)", indent: 2, colour: MENTOR_COLOUR)

hugh_laurie_mentoring_at_abbey_grove = MentorAtSchoolPeriod.create!(
  teacher: hugh_laurie,
  school: abbey_grove_school,
  email: 'hugh.laurie@house.com',
  started_on: 2.years.ago
).tap { |sp| describe_mentor_at_school_period(sp) }

TrainingPeriod.create!(
  mentor_at_school_period: hugh_laurie_mentoring_at_abbey_grove,
  started_on: 2.years.ago,
  school_partnership: meadow_grain_partnership_2022
).tap { |tp| describe_training_period(tp) }

print_seed_info("Alan Rickman (ECT)", indent: 2, colour: ECT_COLOUR)

alan_rickman_ect_at_ackley_bridge = ECTAtSchoolPeriod.create!(
  teacher: alan_rickman,
  school: ackley_bridge,
  email: 'alan.rickman@diehard.com',
  started_on: 2.years.ago,
  lead_provider: wildflower_trust,
  school_reported_appropriate_body: golden_leaf_teaching_school_hub,
  working_pattern: 'part_time',
  programme_type: 'provider_led'
).tap { |sp| describe_ect_at_school_period(sp) }

ackley_bridge.update!(chosen_lead_provider: wildflower_trust,
                      chosen_appropriate_body: golden_leaf_teaching_school_hub,
                      chosen_programme_type: 'provider_led')

TrainingPeriod.create!(
  ect_at_school_period: alan_rickman_ect_at_ackley_bridge,
  started_on: 2.years.ago + 1.month,
  school_partnership: meadow_grain_partnership_2022
).tap { |tp| describe_training_period(tp) }

InductionPeriod.create!(
  teacher: alan_rickman,
  appropriate_body: golden_leaf_teaching_school_hub,
  started_on: 2.years.ago + 2.months,
  induction_programme: 'fip'
).tap { |ip| describe_induction_period(ip) }

InductionExtension.create!(
  teacher: alan_rickman,
  number_of_terms: 1.5
).tap { |ext| describe_extension(ext) }

active_appropriate_bodies.each do |appropriate_body|
  PendingInductionSubmission.create!(
    appropriate_body:,
    trn: alan_rickman.trn,
    date_of_birth: Date.new(1946, 2, 21),
    started_on: 1.month.ago,
    trs_first_name: alan_rickman.trs_first_name,
    trs_last_name: alan_rickman.trs_last_name
  ).tap { |is| describe_pending_induction_submission(is) }
end

print_seed_info("Hugh Grant (ECT)", indent: 2, colour: ECT_COLOUR)

hugh_grant_ect_at_abbey_grove = ECTAtSchoolPeriod.create!(
  teacher: hugh_grant,
  school: abbey_grove_school,
  email: 'hugh.grant@wonka.com',
  started_on: 2.years.ago,
  lead_provider: nil,
  school_reported_appropriate_body: golden_leaf_teaching_school_hub,
  working_pattern: 'part_time',
  programme_type: 'school_led'
).tap { |sp| describe_ect_at_school_period(sp) }

TrainingPeriod.create!(
  ect_at_school_period: hugh_grant_ect_at_abbey_grove,
  started_on: 2.years.ago,
  finished_on: 1.week.ago,
  school_partnership: grove_artisan_partnership_2021
).tap { |tp| describe_training_period(tp) }

InductionPeriod.create!(
  teacher: hugh_grant,
  appropriate_body: golden_leaf_teaching_school_hub,
  started_on: 2.years.ago + 3.days,
  finished_on: 1.week.ago,
  induction_programme: 'fip',
  number_of_terms: 3
).tap { |ip| describe_induction_period(ip) }

InductionExtension.create!(
  teacher: hugh_grant,
  number_of_terms: 1.5
).tap { |ext| describe_extension(ext) }

InductionExtension.create!(
  teacher: hugh_grant,
  number_of_terms: 1
).tap { |ext| describe_extension(ext) }

print_seed_info("Colin Firth (ECT)", indent: 2, colour: ECT_COLOUR)

colin_firth_ect_at_abbey_grove = ECTAtSchoolPeriod.create!(
  teacher: colin_firth,
  school: abbey_grove_school,
  email: 'colin.firth@aol.com',
  started_on: 2.years.ago,
  lead_provider: nil,
  school_reported_appropriate_body: golden_leaf_teaching_school_hub,
  working_pattern: 'full_time',
  programme_type: 'school_led'
).tap { |sp| describe_ect_at_school_period(sp) }

abbey_grove_school.update!(chosen_lead_provider: nil,
                           chosen_appropriate_body: golden_leaf_teaching_school_hub,
                           chosen_programme_type: 'school_led')

TrainingPeriod.create!(
  ect_at_school_period: colin_firth_ect_at_abbey_grove,
  started_on: 2.years.ago,
  finished_on: 1.week.ago,
  school_partnership: grove_artisan_partnership_2021
).tap { |tp| describe_training_period(tp) }

InductionPeriod.create!(
  teacher: colin_firth,
  appropriate_body: golden_leaf_teaching_school_hub,
  started_on: 2.years.ago + 3.days,
  finished_on: 1.week.ago,
  induction_programme: 'fip',
  number_of_terms: 3
).tap { |ip| describe_induction_period(ip) }

InductionExtension.create!(
  teacher: colin_firth,
  number_of_terms: 1.5
).tap { |ext| describe_extension(ext) }

InductionExtension.create!(
  teacher: colin_firth,
  number_of_terms: 1
).tap { |ext| describe_extension(ext) }

print_seed_info("Harriet Walter (mentor)", indent: 2, colour: MENTOR_COLOUR)

InductionPeriod.create!(
  appropriate_body: umber_teaching_school_hub,
  teacher: harriet_walter,
  started_on: 2.years.ago,
  finished_on: 1.year.ago,
  induction_programme: 'fip',
  number_of_terms: [1, 2, 3].sample
).tap { |ip| describe_induction_period(ip) }

InductionPeriod.create!(
  appropriate_body: golden_leaf_teaching_school_hub,
  teacher: harriet_walter,
  started_on: 1.year.ago,
  induction_programme: 'fip'
).tap { |ip| describe_induction_period(ip) }

InductionExtension.create!(
  teacher: harriet_walter,
  number_of_terms: 1.3
).tap { |ext| describe_extension(ext) }

InductionExtension.create!(
  teacher: harriet_walter,
  number_of_terms: 5
).tap { |ext| describe_extension(ext) }

print_seed_info("Imogen Stubbs (ECT)", indent: 2, colour: ECT_COLOUR)

InductionPeriod.create!(
  appropriate_body: golden_leaf_teaching_school_hub,
  teacher: imogen_stubbs,
  started_on: 18.months.ago,
  finished_on: 14.months.ago,
  induction_programme: 'fip',
  number_of_terms: 1
).tap { |ip| describe_induction_period(ip) }

InductionPeriod.create!(
  appropriate_body: golden_leaf_teaching_school_hub,
  teacher: imogen_stubbs,
  started_on: 14.months.ago,
  finished_on: nil,
  induction_programme: 'cip'
).tap { |ip| describe_induction_period(ip) }

imogen_stubbs_at_malory_towers = ECTAtSchoolPeriod.create!(
  teacher: imogen_stubbs,
  school: mallory_towers,
  email: 'imogen.stubbs@eriktheviking.com',
  started_on: 2.years.ago,
  lead_provider: nil,
  school_reported_appropriate_body: golden_leaf_teaching_school_hub,
  working_pattern: 'full_time',
  programme_type: 'school_led'
).tap { |sp| describe_ect_at_school_period(sp) }

TrainingPeriod.create!(
  ect_at_school_period: imogen_stubbs_at_malory_towers,
  started_on: 1.year.ago,
  school_partnership: meadow_grain_partnership_2022
).tap { |tp| describe_training_period(tp) }

InductionExtension.create!(
  teacher: imogen_stubbs,
  number_of_terms: 1
).tap { |ext| describe_extension(ext) }

print_seed_info("Gemma Jones (ECT)", indent: 2, colour: ECT_COLOUR)

InductionPeriod.create!(
  appropriate_body: umber_teaching_school_hub,
  teacher: gemma_jones,
  started_on: 20.months.ago,
  finished_on: nil,
  induction_programme: 'fip'
).tap { |ip| describe_induction_period(ip) }

gemma_jones_at_malory_towers = ECTAtSchoolPeriod.create!(
  teacher: gemma_jones,
  school: mallory_towers,
  email: 'gemma.jones@rocketman.com',
  started_on: 21.months.ago,
  lead_provider: wildflower_trust,
  school_reported_appropriate_body: golden_leaf_teaching_school_hub,
  working_pattern: 'part_time',
  programme_type: 'provider_led'
).tap { |sp| describe_ect_at_school_period(sp) }

mallory_towers.update!(chosen_lead_provider: wildflower_trust,
                       chosen_appropriate_body: golden_leaf_teaching_school_hub,
                       chosen_programme_type: 'provider_led')

TrainingPeriod.create!(
  ect_at_school_period: gemma_jones_at_malory_towers,
  started_on: 20.months.ago,
  school_partnership: meadow_grain_partnership_2022
).tap { |tp| describe_training_period(tp) }

InductionExtension.create!(
  teacher: gemma_jones,
  number_of_terms: 1.5
).tap { |ext| describe_extension(ext) }

print_seed_info("André Roussimoff (ECT)", indent: 2, colour: ECT_COLOUR)

andre_roussimoff_mentoring_at_ackley_bridge = MentorAtSchoolPeriod.create!(
  teacher: andre_roussimoff,
  school: ackley_bridge,
  email: 'andre.giant@wwf.com',
  started_on: 1.year.ago
).tap { |sp| describe_mentor_at_school_period(sp) }

TrainingPeriod.create!(
  mentor_at_school_period: andre_roussimoff_mentoring_at_ackley_bridge,
  started_on: 1.year.ago,
  school_partnership: meadow_grain_partnership_2022
).tap { |tp| describe_training_period(tp) }

print_seed_info("Anthony Hopkins (ECT)", indent: 2, colour: ECT_COLOUR)

anthony_hopkins_ect_at_brookfield_school = ECTAtSchoolPeriod.create!(
  teacher: anthony_hopkins,
  school: brookfield_school,
  email: 'anthony.hopkins@favabeans.com',
  lead_provider: national_meadows_institute,
  school_reported_appropriate_body: umber_teaching_school_hub,
  programme_type: 'provider_led',
  started_on: 2.years.ago,
  working_pattern: 'part_time'
).tap { |sp| describe_ect_at_school_period(sp) }

TrainingPeriod.create!(
  ect_at_school_period: anthony_hopkins_ect_at_brookfield_school,
  started_on: 2.years.ago,
  school_partnership: meadow_grain_partnership_2022
).tap { |tp| describe_training_period(tp) }

print_seed_info("Stephen Fry (ECT)", indent: 2, colour: ECT_COLOUR)

stephen_fry_ect_at_brookfield_school = ECTAtSchoolPeriod.create!(
  teacher: stephen_fry,
  school: brookfield_school,
  email: 'stephen.fry@sausage.com',
  started_on: 2.years.ago,
  lead_provider: national_meadows_institute,
  school_reported_appropriate_body: south_yorkshire_studio_hub,
  programme_type: 'provider_led',
  working_pattern: 'part_time'
).tap { |sp| describe_ect_at_school_period(sp) }

brookfield_school.update!(chosen_lead_provider: national_meadows_institute,
                          chosen_appropriate_body: south_yorkshire_studio_hub,
                          chosen_programme_type: 'provider_led')

TrainingPeriod.create!(
  ect_at_school_period: stephen_fry_ect_at_brookfield_school,
  started_on: 2.years.ago,
  school_partnership: meadow_grain_partnership_2022
).tap { |tp| describe_training_period(tp) }

print_seed_info("Harriet Walter (ECT) with multiple induction periods", indent: 2, colour: ECT_COLOUR)

ECTAtSchoolPeriod.create!(
  teacher: harriet_walter,
  school: brookfield_school,
  email: 'harriet-walter@history.com',
  started_on: 2.years.ago,
  lead_provider: national_meadows_institute,
  school_reported_appropriate_body: south_yorkshire_studio_hub,
  programme_type: 'provider_led'
).tap { |sp| describe_ect_at_school_period(sp) }

print_seed_info("Helen Mirren (mentor)", indent: 2, colour: MENTOR_COLOUR)

helen_mirren_mentoring_at_brookfield_school = MentorAtSchoolPeriod.create!(
  teacher: helen_mirren,
  school: brookfield_school,
  email: 'helen.mirren@titania.com',
  started_on: 2.years.ago
).tap { |sp| describe_mentor_at_school_period(sp) }

TrainingPeriod.create!(
  mentor_at_school_period: helen_mirren_mentoring_at_brookfield_school,
  started_on: 2.years.ago,
  school_partnership: meadow_grain_partnership_2022
).tap { |tp| describe_training_period(tp) }

print_seed_info("John Withers (mentor)", indent: 2, colour: MENTOR_COLOUR)

john_withers_mentoring_at_abbey_grove = MentorAtSchoolPeriod.create!(
  teacher: john_withers,
  school: abbey_grove_school,
  email: 'john.withers@amusementpark.com',
  started_on: 2.years.ago
).tap { |sp| describe_mentor_at_school_period(sp) }

TrainingPeriod.create!(
  mentor_at_school_period: john_withers_mentoring_at_abbey_grove,
  started_on: 2.years.ago,
  school_partnership: meadow_grain_partnership_2022
).tap { |tp| describe_training_period(tp) }

print_seed_info("Adding mentorships:")

MentorshipPeriod.create!(
  mentor: emma_thompson_mentoring_at_abbey_grove,
  mentee: hugh_grant_ect_at_abbey_grove,
  started_on: 2.years.ago,
  finished_on: 1.year.ago
).tap { |mp| describe_mentorship_period(mp) }

MentorshipPeriod.create!(
  mentor: hugh_laurie_mentoring_at_abbey_grove,
  mentee: hugh_grant_ect_at_abbey_grove,
  started_on: 1.year.ago,
  finished_on: nil
).tap { |mp| describe_mentorship_period(mp) }

MentorshipPeriod.create!(
  mentor: andre_roussimoff_mentoring_at_ackley_bridge,
  mentee: kate_winslet_ect_at_ackley_bridge,
  started_on: 1.year.ago,
  finished_on: nil
).tap { |mp| describe_mentorship_period(mp) }

MentorshipPeriod.create!(
  mentor: helen_mirren_mentoring_at_brookfield_school,
  mentee: stephen_fry_ect_at_brookfield_school,
  started_on: 1.year.ago,
  finished_on: nil
).tap { |mp| describe_mentorship_period(mp) }

print_seed_info("Adding persona users:")

YAML.load_file(Rails.root.join('config/personas.yml'))
    .select { |p| p['type'] == 'DfE staff' }
    .map { |p| { name: p['name'], email: p['email'] } }
    .each do |user_params|
  User.create!(**user_params)
      .tap { |user| user.dfe_roles.create! }
      .then { |user| describe_user(user) }
end

print_seed_info('Adding funding exemptions:')
