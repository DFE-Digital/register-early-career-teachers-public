ECT_COLOUR = :magenta
MENTOR_COLOUR = :yellow

def describe_extension(ext)
  suffix = "(extension)"

  print_seed_info("* had their induction extended by #{ext.number_of_terms} #{suffix}", indent: 4)
end

def teacher_name(teacher)
  Teachers::Name.new(teacher).full_name
end

def describe_period_duration(period)
  case
  when period.started_on.future?
    "from #{period.started_on}"
  when period.finished_on
    "between #{period.started_on} and #{period.finished_on}"
  else
    "since #{period.started_on}"
  end
end

def describe_mentorship_period(mp)
  mentor_name = Colourize.text("#{mp.mentor.teacher.trs_first_name} #{mp.mentor.teacher.trs_last_name}", MENTOR_COLOUR)
  ect_name = Colourize.text("#{mp.mentee.teacher.trs_first_name} #{mp.mentee.teacher.trs_last_name}", ECT_COLOUR)

  print_seed_info("#{mentor_name} mentoring #{ect_name} at #{mp.mentor.school.gias_school.name} #{describe_period_duration(mp)}", indent: 2)
end

def describe_pending_induction_submission(pending_induction_submission)
  suffix = "(pending_induction_submission)"

  print_seed_info("* has one pending induction submission from #{pending_induction_submission.appropriate_body.name} #{suffix}", indent: 4)
end

def describe_induction_period(ip)
  suffix = "(induction period)"

  print_seed_info("* is having their induction overseen by #{ip.appropriate_body.name} (AB) #{describe_period_duration(ip)} #{suffix}", indent: 4)

  author_attributes = {
    author_email: "fkend@appropriate-body.org",
    author_name: "Felicity Kendall",
    author_type: "appropriate_body_user",
  }

  FactoryBot.create(
    :event,
    event_type: "induction_period_opened",
    induction_period: ip,
    teacher: ip.teacher,
    appropriate_body: ip.appropriate_body,
    heading: "#{teacher_name(ip.teacher)} was claimed by #{ip.appropriate_body.name}",
    happened_at: ip.started_on.at_midday + rand(-300..300).minutes,
    **author_attributes
  )

  if ip.finished_on
    FactoryBot.create(
      :event,
      event_type: "induction_period_closed",
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
  prefix = (tp.started_on.future?) ? "will be" : "was"

  case
  when tp.provider_led_training_programme? && tp.school_partnership.present?
    suffix = "(training period - provider-led)"
    lpdp = tp.school_partnership.lead_provider_delivery_partnership
    lead_provider_name = lpdp.active_lead_provider.lead_provider.name
    delivery_partner_name = lpdp.delivery_partner.name
    print_seed_info("* #{prefix} trained by #{lead_provider_name} (LP) and #{delivery_partner_name} (DP) #{describe_period_duration(tp)} #{suffix}", indent: 4)
  when tp.provider_led_training_programme? && tp.expression_of_interest.present?
    suffix = "(training period - provider-led)"
    lead_provider_name = tp.expression_of_interest.lead_provider.name
    print_seed_info("* #{prefix} trained by #{lead_provider_name} (LP) #{describe_period_duration(tp)} providing the EOI is accepted #{suffix}", indent: 4)
  when tp.school_led_training_programme?
    suffix = "(training period - school-led)"
    print_seed_info("* #{prefix} trained #{describe_period_duration(tp)} #{suffix}", indent: 4)
  end
end

def describe_ect_at_school_period(sp)
  suffix = "(ECT at school period)"

  print_seed_info("* has been an ECT at #{sp.school.name} #{describe_period_duration(sp)} #{suffix}", indent: 4)
end

def describe_mentor_at_school_period(sp)
  suffix = "(mentor at school period)"

  print_seed_info("* was a mentor at #{sp.school.name} #{describe_period_duration(sp)} #{suffix}", indent: 4)
end

def create_same_school_mentorship!(mentor:, mentee:, started_on:, finished_on:)
  FactoryBot.create(
    :mentorship_period,
    mentor:,
    mentee:,
    started_on:,
    finished_on:
  ).tap { |mp| describe_mentorship_period(mp) }
end

ambition_institute = LeadProvider.find_by!(name: "Ambition Institute")
teach_first = LeadProvider.find_by!(name: "Teach First")
best_practice_network = LeadProvider.find_by!(name: "Best Practice Network")
capita = LeadProvider.find_by!(name: "Capita")

abbey_grove_school = School.find_by!(urn: 1_759_427)
ackley_bridge = School.find_by!(urn: 3_375_958)
mallory_towers = School.find_by!(urn: 5_279_293)
brookfield_school = School.find_by!(urn: 2_976_163)

artisan_education_group = DeliveryPartner.find_by!(name: "Artisan Education Group")
grain_teaching_school_hub = DeliveryPartner.find_by!(name: "Grain Teaching School Hub")
capita_delivery_partner = DeliveryPartner.find_by!(name: "Capita Delivery Partner")

south_yorkshire_studio_hub = AppropriateBody.find_by!(name: "South Yorkshire Studio Hub")
golden_leaf_teaching_school_hub = AppropriateBody.find_by!(name: "Golden Leaf Teaching School Hub")
umber_teaching_school_hub = AppropriateBody.find_by!(name: "Umber Teaching School Hub")
active_appropriate_bodies = [umber_teaching_school_hub, golden_leaf_teaching_school_hub]

def find_or_create_school_partnership!(school:, delivery_partner:, lead_provider:, contract_period:)
  active_lead_provider = ActiveLeadProvider.find_by!(
    lead_provider:,
    contract_period_year: contract_period.year
  )

  lead_provider_delivery_partnership = LeadProviderDeliveryPartnership.find_or_create_by!(
    active_lead_provider:,
    delivery_partner:
  )

  SchoolPartnership.find_or_create_by!(
    school:,
    lead_provider_delivery_partnership:
  )
end

cp_2021 = ContractPeriod.find_by!(year: 2021)
cp_2022 = ContractPeriod.find_by!(year: 2022)
cp_2023 = ContractPeriod.find_by!(year: 2023)
cp_2024 = ContractPeriod.find_by!(year: 2024)
cp_2025 = ContractPeriod.find_by!(year: 2025)

ambition_artisan_2022 = ActiveLeadProvider.find_by!(contract_period: cp_2022, lead_provider: ambition_institute)
ambition_artisan_2023 = ActiveLeadProvider.find_by!(contract_period: cp_2023, lead_provider: ambition_institute)
teach_first_grain_2022 = ActiveLeadProvider.find_by!(contract_period: cp_2022, lead_provider: teach_first)
teach_first_grain_2025 = ActiveLeadProvider.find_by!(contract_period: cp_2025, lead_provider: teach_first)

# Abbey Grove — Ambition / Artisan
ambition_artisan_abbey_grove_2022 = find_or_create_school_partnership!(
  school: abbey_grove_school,
  lead_provider: ambition_institute,
  delivery_partner: artisan_education_group,
  contract_period: cp_2022
)

teach_first_artisan_abbey_grove_2022 = find_or_create_school_partnership!(
  school: abbey_grove_school,
  lead_provider: teach_first,
  delivery_partner: artisan_education_group,
  contract_period: cp_2022
)

ambition_artisan_abbey_grove_2025 = find_or_create_school_partnership!(
  school: abbey_grove_school,
  lead_provider: ambition_institute,
  delivery_partner: artisan_education_group,
  contract_period: cp_2025
)

# Abbey Grove — Teach First / Grain

teach_first_grain_abbey_grove_2025 = find_or_create_school_partnership!(
  school: abbey_grove_school,
  lead_provider: teach_first,
  delivery_partner: grain_teaching_school_hub,
  contract_period: cp_2025
)

teach_first_grain_abbey_grove_2024 = find_or_create_school_partnership!(
  school: abbey_grove_school,
  lead_provider: teach_first,
  delivery_partner: grain_teaching_school_hub,
  contract_period: cp_2024
)

# Ackley Bridge — Ambition / Artisan

ambition_artisan_brookfield_2023 = find_or_create_school_partnership!(
  school: brookfield_school,
  lead_provider: ambition_institute,
  delivery_partner: artisan_education_group,
  contract_period: cp_2023
)

# Ackley Bridge — Teach First / Grain
teach_first_grain_ackley_bridge_2022 = find_or_create_school_partnership!(
  school: ackley_bridge,
  lead_provider: teach_first,
  delivery_partner: grain_teaching_school_hub,
  contract_period: cp_2022
)

# Mallory Towers — Teach First / Grain

teach_first_grain_mallory_towers_2024 = find_or_create_school_partnership!(
  school: mallory_towers,
  lead_provider: teach_first,
  delivery_partner: grain_teaching_school_hub,
  contract_period: cp_2024
)

# Brookfield — Teach First / Grain
teach_first_grain_brookfield_2021 = find_or_create_school_partnership!(
  school: brookfield_school,
  lead_provider: teach_first,
  delivery_partner: grain_teaching_school_hub,
  contract_period: cp_2021
)

teach_first_grain_brookfield_2022 = find_or_create_school_partnership!(
  school: brookfield_school,
  lead_provider: teach_first,
  delivery_partner: grain_teaching_school_hub,
  contract_period: cp_2022
)

# Brookfield — Capita
capita_brookfield_2022 = find_or_create_school_partnership!(
  school: brookfield_school,
  lead_provider: capita,
  delivery_partner: capita_delivery_partner,
  contract_period: cp_2022
)

# NB: define teachers in ./db/seeds/teachers.rb
alan_rickman = Teacher.find_by!(trn: "0000006")
alastair_sim = Teacher.find_by!(trn: "0000024")
andre_roussimoff = Teacher.find_by!(trn: "0000015")
anthony_hopkins = Teacher.find_by!(trn: "0000018")
colin_firth = Teacher.find_by!(trn: "0000007")
dominic_west = Teacher.find_by!(trn: "0000014")
emma_thompson = Teacher.find_by!(trn: "0000004")
frankie_howard = Teacher.find_by!(trn: "0000033")
gemma_jones = Teacher.find_by!(trn: "0000017")
george_cole = Teacher.find_by!(trn: "0000032")
harriet_walter = Teacher.find_by!(trn: "0000010")
hattie_jacques = Teacher.find_by!(trn: "0000029")
helen_mirren = Teacher.find_by!(trn: "0000020")
hugh_grant = Teacher.find_by!(trn: "0000012")
hugh_laurie = Teacher.find_by!(trn: "0000011")
imogen_stubbs = Teacher.find_by!(trn: "0000016")
jane_smith = Teacher.find_by!(trn: "0000030")
joan_sims = Teacher.find_by!(trn: "0000028")
john_withers = Teacher.find_by!(trn: "0000019")
joyce_grenfell = Teacher.find_by!(trn: "0000031")
kate_winslet = Teacher.find_by!(trn: "0000005")
margaret_rutherford = Teacher.find_by!(trn: "0000025")
naruto_uzumaki = Teacher.find_by!(trn: "0000034")
peter_davison = Teacher.find_by!(trn: "0000021")
sid_james = Teacher.find_by!(trn: "0000027")
stephen_fry = Teacher.find_by!(trn: "0000013")
terry_thomas = Teacher.find_by!(trn: "0000026")

print_seed_info("Emma Thompson (mentor)", indent: 2, colour: MENTOR_COLOUR)

emma_thompson_mentoring_at_abbey_grove = FactoryBot.create(:mentor_at_school_period,
                                                           teacher: emma_thompson,
                                                           school: abbey_grove_school,
                                                           email: "emma.thompson@matilda.com",
                                                           started_on: Date.new(2022, 9, 1),
                                                           finished_on: nil).tap { |sp| describe_mentor_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_mentor,
                  :with_schedule,
                  mentor_at_school_period: emma_thompson_mentoring_at_abbey_grove,
                  started_on: Date.new(2022, 9, 1),
                  finished_on: Date.new(2023, 2, 20),
                  expression_of_interest: ambition_artisan_2022,
                  school_partnership: ambition_artisan_abbey_grove_2022,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

# 10 week break
april_2022_schedule = Schedule.find_by(contract_period_year: 2022, identifier: "ecf-standard-april")
FactoryBot.create(:training_period,
                  :for_mentor,
                  schedule: april_2022_schedule,
                  mentor_at_school_period: emma_thompson_mentoring_at_abbey_grove,
                  started_on: Date.new(2023, 5, 1),
                  finished_on: nil,
                  school_partnership: ambition_artisan_abbey_grove_2022,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("Kate Winslet (ECT)", indent: 2, colour: ECT_COLOUR)

kate_winslet_ect_at_ackley_bridge = FactoryBot.create(:ect_at_school_period,
                                                      teacher: kate_winslet,
                                                      school: ackley_bridge,
                                                      email: "kate.winslet@titanic.com",
                                                      started_on: Date.new(2021, 9, 1),
                                                      finished_on: nil,
                                                      school_reported_appropriate_body: golden_leaf_teaching_school_hub,
                                                      working_pattern: "full_time").tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :school_led,
                  ect_at_school_period: kate_winslet_ect_at_ackley_bridge,
                  started_on: Date.new(2021, 9, 1),
                  finished_on: nil,
                  expression_of_interest: nil,
                  school_partnership: nil).tap { |tp| describe_training_period(tp) }

FactoryBot.create(:induction_period,
                  teacher: kate_winslet,
                  started_on: Date.new(2021, 9, 1),
                  finished_on: Date.new(2024, 9, 1),
                  number_of_terms: 3,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  induction_programme: "fip",
                  training_programme: "school_led").tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_period,
                  teacher: kate_winslet,
                  started_on: Date.new(2024, 9, 1),
                  finished_on: nil,
                  appropriate_body: umber_teaching_school_hub,
                  induction_programme: "fip",
                  training_programme: "school_led",
                  number_of_terms: nil).tap { |ip| describe_induction_period(ip) }

print_seed_info("Hugh Laurie (mentor)", indent: 2, colour: MENTOR_COLOUR)

hugh_laurie_mentoring_at_abbey_grove = FactoryBot.create(:mentor_at_school_period,
                                                         teacher: hugh_laurie,
                                                         school: abbey_grove_school,
                                                         email: "hugh.laurie@house.com",
                                                         started_on: Date.new(2022, 9, 1),
                                                         finished_on: nil).tap { |sp| describe_mentor_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_mentor,
                  :with_schedule,
                  mentor_at_school_period: hugh_laurie_mentoring_at_abbey_grove,
                  started_on: Date.new(2022, 9, 1),
                  finished_on: nil,
                  expression_of_interest: teach_first_grain_2022,
                  school_partnership: teach_first_artisan_abbey_grove_2022,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("Alan Rickman (ECT)", indent: 2, colour: ECT_COLOUR)

alan_rickman_ect_at_ackley_bridge = FactoryBot.create(:ect_at_school_period,
                                                      teacher: alan_rickman,
                                                      school: ackley_bridge,
                                                      email: "alan.rickman@diehard.com",
                                                      started_on: Date.new(2022, 9, 1),
                                                      finished_on: nil,
                                                      school_reported_appropriate_body: golden_leaf_teaching_school_hub,
                                                      working_pattern: "part_time").tap { |sp| describe_ect_at_school_period(sp) }

ackley_bridge.update!(last_chosen_lead_provider: best_practice_network,
                      last_chosen_appropriate_body: golden_leaf_teaching_school_hub,
                      last_chosen_training_programme: "provider_led")

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: alan_rickman_ect_at_ackley_bridge,
                  started_on: Date.new(2022, 10, 1),
                  finished_on: nil,
                  school_partnership: teach_first_grain_ackley_bridge_2022,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

FactoryBot.create(:induction_period,
                  teacher: alan_rickman,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  started_on: Date.new(2022, 11, 1),
                  finished_on: nil,
                  induction_programme: "fip",
                  training_programme: "provider_led",
                  number_of_terms: nil).tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_extension,
                  teacher: alan_rickman,
                  number_of_terms: 1.5).tap { |ext| describe_extension(ext) }

active_appropriate_bodies.each do |appropriate_body|
  FactoryBot.create(:pending_induction_submission,
                    appropriate_body:,
                    trn: alan_rickman.trn,
                    date_of_birth: Date.new(1946, 2, 21),
                    started_on: Date.new(2023, 9, 1),
                    finished_on: nil,
                    trs_first_name: alan_rickman.trs_first_name,
                    trs_last_name: alan_rickman.trs_last_name).tap { |is| describe_pending_induction_submission(is) }
end

print_seed_info("Hugh Grant (ECT)", indent: 2, colour: ECT_COLOUR)

hugh_grant_ect_at_abbey_grove = FactoryBot.create(:ect_at_school_period,
                                                  teacher: hugh_grant,
                                                  school: abbey_grove_school,
                                                  email: "hugh.grant@wonka.com",
                                                  started_on: Date.new(2021, 9, 1),
                                                  finished_on: nil,
                                                  school_reported_appropriate_body: golden_leaf_teaching_school_hub,
                                                  working_pattern: "part_time").tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :school_led,
                  ect_at_school_period: hugh_grant_ect_at_abbey_grove,
                  started_on: Date.new(2021, 9, 1),
                  finished_on: nil,
                  expression_of_interest: nil,
                  school_partnership: nil).tap { |tp| describe_training_period(tp) }

FactoryBot.create(:induction_period,
                  teacher: hugh_grant,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  started_on: Date.new(2021, 9, 4),
                  finished_on: Date.new(2022, 5, 1),
                  induction_programme: "fip",
                  training_programme: "provider_led",
                  number_of_terms: 3).tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_extension,
                  teacher: hugh_grant,
                  number_of_terms: 1.5).tap { |ext| describe_extension(ext) }

FactoryBot.create(:induction_extension,
                  teacher: hugh_grant,
                  number_of_terms: 1).tap { |ext| describe_extension(ext) }

print_seed_info("Colin Firth (ECT)", indent: 2, colour: ECT_COLOUR)

colin_firth_ect_at_abbey_grove = FactoryBot.create(:ect_at_school_period,
                                                   teacher: colin_firth,
                                                   school: abbey_grove_school,
                                                   email: "colin.firth@aol.com",
                                                   started_on: Date.new(2022, 9, 1),
                                                   finished_on: nil,
                                                   school_reported_appropriate_body: golden_leaf_teaching_school_hub,
                                                   working_pattern: "full_time").tap { |sp| describe_ect_at_school_period(sp) }

abbey_grove_school.update!(last_chosen_lead_provider: nil,
                           last_chosen_appropriate_body: golden_leaf_teaching_school_hub,
                           last_chosen_training_programme: "school_led")

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: colin_firth_ect_at_abbey_grove,
                  started_on: Date.new(2022, 9, 1),
                  finished_on: nil,
                  school_partnership: ambition_artisan_abbey_grove_2022,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

FactoryBot.create(:induction_period,
                  teacher: colin_firth,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  started_on: Date.new(2022, 9, 4),
                  finished_on: Date.new(2023, 6, 1),
                  induction_programme: "fip",
                  training_programme: "provider_led",
                  number_of_terms: 3).tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_extension,
                  teacher: colin_firth,
                  number_of_terms: 1.5).tap { |ext| describe_extension(ext) }

FactoryBot.create(:induction_extension,
                  teacher: colin_firth,
                  number_of_terms: 1).tap { |ext| describe_extension(ext) }

print_seed_info("Harriet Walter (mentor)", indent: 2, colour: MENTOR_COLOUR)

FactoryBot.create(:induction_period,
                  appropriate_body: umber_teaching_school_hub,
                  teacher: harriet_walter,
                  started_on: Date.new(2023, 9, 1),
                  finished_on: Date.new(2024, 8, 1),
                  induction_programme: "fip",
                  training_programme: "provider_led",
                  number_of_terms: [1, 2, 3].sample).tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_period,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  teacher: harriet_walter,
                  started_on: Date.new(2024, 8, 1),
                  finished_on: nil,
                  induction_programme: "fip",
                  training_programme: "provider_led",
                  number_of_terms: nil).tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_extension,
                  teacher: harriet_walter,
                  number_of_terms: 1.3).tap { |ext| describe_extension(ext) }

FactoryBot.create(:induction_extension,
                  teacher: harriet_walter,
                  number_of_terms: 5).tap { |ext| describe_extension(ext) }

print_seed_info("Imogen Stubbs (ECT)", indent: 2, colour: ECT_COLOUR)

FactoryBot.create(:induction_period,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  teacher: imogen_stubbs,
                  started_on: Date.new(2024, 9, 1),
                  finished_on: Date.new(2024, 11, 1),
                  induction_programme: "fip",
                  training_programme: "provider_led",
                  number_of_terms: 1).tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_period,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  teacher: imogen_stubbs,
                  started_on: Date.new(2024, 11, 1),
                  finished_on: nil,
                  induction_programme: "cip",
                  training_programme: "school_led",
                  number_of_terms: nil).tap { |ip| describe_induction_period(ip) }

imogen_stubbs_at_mallory_towers = FactoryBot.create(:ect_at_school_period,
                                                    teacher: imogen_stubbs,
                                                    school: mallory_towers,
                                                    email: "imogen.stubbs@eriktheviking.com",
                                                    started_on: Date.new(2024, 9, 1),
                                                    finished_on: nil,
                                                    school_reported_appropriate_body: golden_leaf_teaching_school_hub,
                                                    working_pattern: "full_time").tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: imogen_stubbs_at_mallory_towers,
                  started_on: Date.new(2024, 12, 1),
                  finished_on: nil,
                  school_partnership: teach_first_grain_mallory_towers_2024,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

FactoryBot.create(:induction_extension,
                  teacher: imogen_stubbs,
                  number_of_terms: 1).tap { |ext| describe_extension(ext) }

print_seed_info("Gemma Jones (ECT)", indent: 2, colour: ECT_COLOUR)

FactoryBot.create(:induction_period,
                  appropriate_body: umber_teaching_school_hub,
                  teacher: gemma_jones,
                  started_on: Date.new(2023, 9, 1),
                  finished_on: nil,
                  induction_programme: "fip",
                  training_programme: "provider_led",
                  number_of_terms: nil).tap { |ip| describe_induction_period(ip) }

gemma_jones_at_mallory_towers = FactoryBot.create(:ect_at_school_period,
                                                  teacher: gemma_jones,
                                                  school: mallory_towers,
                                                  email: "gemma.jones@rocketman.com",
                                                  started_on: Date.new(2024, 8, 1),
                                                  finished_on: nil,
                                                  school_reported_appropriate_body: golden_leaf_teaching_school_hub,
                                                  working_pattern: "part_time").tap { |sp| describe_ect_at_school_period(sp) }

mallory_towers.update!(last_chosen_lead_provider: best_practice_network,
                       last_chosen_appropriate_body: golden_leaf_teaching_school_hub,
                       last_chosen_training_programme: "provider_led")

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: gemma_jones_at_mallory_towers,
                  started_on: Date.new(2024, 9, 1),
                  finished_on: nil,
                  school_partnership: teach_first_grain_mallory_towers_2024,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

FactoryBot.create(:induction_extension,
                  teacher: gemma_jones,
                  number_of_terms: 1.5).tap { |ext| describe_extension(ext) }

print_seed_info("André Roussimoff (mentor)", indent: 2, colour: MENTOR_COLOUR)

andre_roussimoff_mentoring_at_ackley_bridge = FactoryBot.create(:mentor_at_school_period,
                                                                teacher: andre_roussimoff,
                                                                school: ackley_bridge,
                                                                email: "andre.giant@wwf.com",
                                                                started_on: Date.new(2022, 9, 1),
                                                                finished_on: nil).tap { |sp| describe_mentor_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_mentor,
                  :with_schedule,
                  mentor_at_school_period: andre_roussimoff_mentoring_at_ackley_bridge,
                  started_on: Date.new(2022, 9, 1),
                  finished_on: nil,
                  school_partnership: teach_first_grain_ackley_bridge_2022,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("Anthony Hopkins (ECT)", indent: 2, colour: ECT_COLOUR)

anthony_hopkins_ect_at_brookfield_school = FactoryBot.create(:ect_at_school_period,
                                                             teacher: anthony_hopkins,
                                                             school: brookfield_school,
                                                             email: "anthony.hopkins@favabeans.com",
                                                             school_reported_appropriate_body: umber_teaching_school_hub,
                                                             started_on: Date.new(2022, 9, 1),
                                                             finished_on: nil,
                                                             working_pattern: "part_time").tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: anthony_hopkins_ect_at_brookfield_school,
                  started_on: Date.new(2022, 9, 1),
                  finished_on: nil,
                  school_partnership: capita_brookfield_2022,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("Stephen Fry (ECT)", indent: 2, colour: ECT_COLOUR)

stephen_fry_ect_at_brookfield_school = FactoryBot.create(:ect_at_school_period,
                                                         teacher: stephen_fry,
                                                         school: brookfield_school,
                                                         email: "stephen.fry@sausage.com",
                                                         started_on: Date.new(2021, 9, 1),
                                                         finished_on: nil,
                                                         school_reported_appropriate_body: south_yorkshire_studio_hub,
                                                         working_pattern: "part_time").tap { |sp| describe_ect_at_school_period(sp) }

brookfield_school.update!(last_chosen_lead_provider: teach_first,
                          last_chosen_appropriate_body: south_yorkshire_studio_hub,
                          last_chosen_training_programme: "provider_led")

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: stephen_fry_ect_at_brookfield_school,
                  started_on: Date.new(2021, 9, 1),
                  finished_on: nil,
                  school_partnership: teach_first_grain_brookfield_2021,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("Harriet Walter (ECT) with multiple induction periods", indent: 2, colour: ECT_COLOUR)

harriet_walter_ect_at_brookfield_school = FactoryBot.create(:ect_at_school_period,
                                                            teacher: harriet_walter,
                                                            school: brookfield_school,
                                                            email: "harriet-walter@history.com",
                                                            started_on: Date.new(2022, 9, 1),
                                                            finished_on: nil,
                                                            school_reported_appropriate_body: south_yorkshire_studio_hub).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: harriet_walter_ect_at_brookfield_school,
                  started_on: Date.new(2022, 9, 1),
                  finished_on: nil,
                  school_partnership: teach_first_grain_brookfield_2022,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("Helen Mirren (mentor)", indent: 2, colour: MENTOR_COLOUR)

helen_mirren_mentoring_at_brookfield_school = FactoryBot.create(:mentor_at_school_period,
                                                                teacher: helen_mirren,
                                                                school: brookfield_school,
                                                                started_on: Date.new(2021, 9, 1),
                                                                finished_on: nil).tap { |sp| describe_mentor_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_mentor,
                  :with_schedule,
                  mentor_at_school_period: helen_mirren_mentoring_at_brookfield_school,
                  started_on: Date.new(2021, 9, 1),
                  finished_on: nil,
                  school_partnership: teach_first_grain_brookfield_2021,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("John Withers (mentor)", indent: 2, colour: MENTOR_COLOUR)

john_withers_mentoring_at_abbey_grove = FactoryBot.create(:mentor_at_school_period,
                                                          teacher: john_withers,
                                                          school: abbey_grove_school,
                                                          email: "john.withers@amusementpark.com",
                                                          started_on: Date.new(2022, 9, 1),
                                                          finished_on: nil).tap { |sp| describe_mentor_at_school_period(sp) }

john_withers_training_period = FactoryBot.create(:training_period,
                                                 :for_mentor,
                                                 :with_schedule,
                                                 mentor_at_school_period: john_withers_mentoring_at_abbey_grove,
                                                 started_on: Date.new(2022, 9, 1),
                                                 finished_on: nil,
                                                 school_partnership: teach_first_artisan_abbey_grove_2022,
                                                 training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

john_withers_declaration_date = john_withers_training_period.schedule.milestones.find_by(declaration_type: :started).start_date
FactoryBot.create(:declaration, declaration_type: :started, declaration_date: john_withers_declaration_date, training_period: john_withers_training_period)

print_seed_info("Dominic West (ECT)", indent: 2, colour: ECT_COLOUR)

dominic_west_ect_at_brookfield_school = FactoryBot.create(:ect_at_school_period,
                                                          teacher: dominic_west,
                                                          school: brookfield_school,
                                                          email: "dominic-west@history.com",
                                                          started_on: Date.new(2023, 9, 1),
                                                          finished_on: nil,
                                                          school_reported_appropriate_body: south_yorkshire_studio_hub).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: dominic_west_ect_at_brookfield_school,
                  started_on: Date.new(2023, 9, 1),
                  finished_on: nil,
                  school_partnership: ambition_artisan_brookfield_2023,
                  expression_of_interest: ambition_artisan_2023,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("Peter Davison (ECT)", indent: 2, colour: ECT_COLOUR)

peter_davison_at_abbey_grove_school = FactoryBot.create(:ect_at_school_period,
                                                        teacher: peter_davison,
                                                        school: abbey_grove_school,
                                                        email: "pd@tardis.bbc",
                                                        started_on: 2.weeks.from_now,
                                                        finished_on: nil,
                                                        school_reported_appropriate_body: south_yorkshire_studio_hub).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: peter_davison_at_abbey_grove_school,
                  started_on: 2.weeks.from_now,
                  finished_on: nil,
                  school_partnership: teach_first_grain_abbey_grove_2025,
                  training_programme: "provider_led",
                  expression_of_interest: teach_first_grain_2025).tap { |tp| describe_training_period(tp) }

print_seed_info("Naruto Uzumaki (ECT, invalid LP)", indent: 2, colour: ECT_COLOUR)

naruto_ect_at_brookfield = FactoryBot.create(
  :ect_at_school_period,
  teacher: naruto_uzumaki,
  school: brookfield_school,
  email: "naruto.uzumaki@konoha.com",
  started_on: Date.new(2023, 9, 1),
  finished_on: nil,
  school_reported_appropriate_body: south_yorkshire_studio_hub
).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(
  :training_period,
  :for_ect,
  :with_schedule,
  ect_at_school_period: naruto_ect_at_brookfield,
  started_on: Date.new(2023, 9, 1),
  finished_on: nil,
  school_partnership: capita_brookfield_2022,
  training_programme: "provider_led"
).tap { |tp| describe_training_period(tp) }

print_seed_info("Alastair Sim (ECT) school-led with no schedule", indent: 2, colour: ECT_COLOUR)

alastair_sim_ect_at_abbey_grove = FactoryBot.create(:ect_at_school_period,
                                                    teacher: alastair_sim,
                                                    school: abbey_grove_school,
                                                    email: "alastair.sim@st-trinians.org.uk",
                                                    started_on: Date.new(2025, 9, 1),
                                                    finished_on: nil,
                                                    school_reported_appropriate_body: golden_leaf_teaching_school_hub)

FactoryBot.create(:training_period,
                  :for_ect,
                  :school_led,
                  ect_at_school_period: alastair_sim_ect_at_abbey_grove,
                  started_on: Date.new(2025, 9, 1),
                  finished_on: nil,
                  expression_of_interest: nil,
                  school_partnership: nil).tap { |tp| describe_training_period(tp) }

print_seed_info("Margaret Rutherford (ECT) school-led with no schedule", indent: 2, colour: ECT_COLOUR)

margaret_rutherford_ect_at_abbey_grove_school = FactoryBot.create(:ect_at_school_period,
                                                                  teacher: margaret_rutherford,
                                                                  school: abbey_grove_school,
                                                                  email: "margaret.rutherford@st-trinians.org.uk",
                                                                  started_on: Date.new(2025, 7, 1),
                                                                  finished_on: nil,
                                                                  school_reported_appropriate_body: south_yorkshire_studio_hub).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :school_led,
                  ect_at_school_period: margaret_rutherford_ect_at_abbey_grove_school,
                  started_on: Date.new(2025, 7, 1),
                  finished_on: nil,
                  expression_of_interest: nil,
                  school_partnership: nil).tap { |tp| describe_training_period(tp) }

print_seed_info("Terry Thomas (ECT) provider-led with schedule ecf-standard-september", indent: 2, colour: ECT_COLOUR)

terry_thomas_ect_at_abbey_grove_school = FactoryBot.create(:ect_at_school_period,
                                                           teacher: terry_thomas,
                                                           school: abbey_grove_school,
                                                           email: "terry.thomas@lifemanship-college.com",
                                                           started_on: Date.new(2025, 8, 1),
                                                           finished_on: nil,
                                                           school_reported_appropriate_body: south_yorkshire_studio_hub).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: terry_thomas_ect_at_abbey_grove_school,
                  started_on: Date.new(2025, 8, 1),
                  finished_on: nil,
                  school_partnership: teach_first_grain_abbey_grove_2025,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("Sid James (ECT) provider-led with schedule ecf-standard-september", indent: 2, colour: ECT_COLOUR)

sid_james_ect_at_abbey_grove_school = FactoryBot.create(:ect_at_school_period,
                                                        teacher: sid_james,
                                                        school: abbey_grove_school,
                                                        email: "sid.james@st-trinians.org.uk",
                                                        started_on: Date.new(2025, 6, 1),
                                                        finished_on: nil,
                                                        school_reported_appropriate_body: south_yorkshire_studio_hub).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: sid_james_ect_at_abbey_grove_school,
                  started_on: Date.new(2025, 6, 1),
                  finished_on: nil,
                  school_partnership: teach_first_grain_abbey_grove_2025,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("Joyce Grenfell (mentor)", indent: 2, colour: MENTOR_COLOUR)

FactoryBot.create(:mentor_at_school_period,
                  teacher: joyce_grenfell,
                  school: ackley_bridge,
                  email: "joyce.grenfell@st-trinians.co.uk",
                  started_on: Date.new(2025, 7, 1),
                  finished_on: nil).tap { |sp| describe_mentor_at_school_period(sp) }

print_seed_info("George Cole (mentor)", indent: 2, colour: MENTOR_COLOUR)

george_cole_at_mallory_towers = FactoryBot.create(:mentor_at_school_period,
                                                  teacher: george_cole,
                                                  school: mallory_towers,
                                                  email: "george.cole@st-trinians.co.uk",
                                                  started_on: Date.new(2025, 6, 15),
                                                  finished_on: nil).tap { |sp| describe_mentor_at_school_period(sp) }

print_seed_info("Frankie Howard (ECT)", indent: 2, colour: ECT_COLOUR)

frankie_howard_at_abbey_grove = FactoryBot.create(:ect_at_school_period,
                                                  teacher: frankie_howard,
                                                  school: abbey_grove_school,
                                                  email: "frankie.howard@st-trinians.co.uk",
                                                  started_on: Date.new(2025, 7, 1),
                                                  finished_on: nil).tap { |sp| describe_ect_at_school_period(sp) }

print_seed_info("Joan Sims (ECT) provider-led with schedule ecf-standard-september", indent: 2, colour: ECT_COLOUR)

joan_sims_ect_at_abbey_grove_school = FactoryBot.create(:ect_at_school_period,
                                                        teacher: joan_sims,
                                                        school: abbey_grove_school,
                                                        email: "joan.sims@st-trinians.org.uk",
                                                        started_on: Date.new(2025, 9, 1),
                                                        finished_on: nil,
                                                        school_reported_appropriate_body: south_yorkshire_studio_hub).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: joan_sims_ect_at_abbey_grove_school,
                  started_on: Date.new(2025, 9, 1),
                  finished_on: nil,
                  school_partnership: ambition_artisan_abbey_grove_2025,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("Hattie Jacques (ECT) provider-led with schedule ecf-standard-september", indent: 2, colour: ECT_COLOUR)

hattie_jacques_ect_at_abbey_grove_school = FactoryBot.create(:ect_at_school_period,
                                                             teacher: hattie_jacques,
                                                             school: abbey_grove_school,
                                                             email: "hattie.jacques@st-trinians.org.uk",
                                                             started_on: Date.new(2025, 9, 5),
                                                             finished_on: nil,
                                                             school_reported_appropriate_body: south_yorkshire_studio_hub).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: hattie_jacques_ect_at_abbey_grove_school,
                  started_on: Date.new(2025, 9, 5),
                  finished_on: nil,
                  school_partnership: ambition_artisan_abbey_grove_2025,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("Jane Smith (ECT) provider-led with schedule ecf-standard-september", indent: 2, colour: ECT_COLOUR)

jane_smith_ect_at_abbey_grove_school = FactoryBot.create(:ect_at_school_period,
                                                         teacher: jane_smith,
                                                         school: abbey_grove_school,
                                                         email: "jane.smith@st-trinians.org.uk",
                                                         started_on: Date.new(2024, 9, 5),
                                                         finished_on: nil,
                                                         school_reported_appropriate_body: south_yorkshire_studio_hub).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: jane_smith_ect_at_abbey_grove_school,
                  started_on: Date.new(2024, 9, 5),
                  finished_on: Date.new(2025, 9, 5),
                  school_partnership: teach_first_grain_abbey_grove_2024,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  :with_schedule,
                  ect_at_school_period: jane_smith_ect_at_abbey_grove_school,
                  started_on: Date.new(2025, 9, 5),
                  finished_on: nil,
                  school_partnership: ambition_artisan_abbey_grove_2025,
                  training_programme: "provider_led").tap { |tp| describe_training_period(tp) }

print_seed_info("Adding mentorships:")

create_same_school_mentorship!(
  mentor: emma_thompson_mentoring_at_abbey_grove,
  mentee: hugh_grant_ect_at_abbey_grove,
  started_on: Date.new(2023, 9, 1),
  finished_on: Date.new(2024, 9, 1)
)

create_same_school_mentorship!(
  mentor: hugh_laurie_mentoring_at_abbey_grove,
  mentee: hugh_grant_ect_at_abbey_grove,
  started_on: Date.new(2024, 9, 1),
  finished_on: nil
)

create_same_school_mentorship!(
  mentor: andre_roussimoff_mentoring_at_ackley_bridge,
  mentee: kate_winslet_ect_at_ackley_bridge,
  started_on: Date.new(2022, 9, 1),
  finished_on: nil
)

create_same_school_mentorship!(
  mentor: helen_mirren_mentoring_at_brookfield_school,
  mentee: stephen_fry_ect_at_brookfield_school,
  started_on: Date.new(2021, 9, 1),
  finished_on: nil
)

create_same_school_mentorship!(
  mentor: john_withers_mentoring_at_abbey_grove,
  mentee: joan_sims_ect_at_abbey_grove_school,
  started_on: Date.new(2025, 9, 15),
  finished_on: nil
)

create_same_school_mentorship!(
  mentor: john_withers_mentoring_at_abbey_grove,
  mentee: hattie_jacques_ect_at_abbey_grove_school,
  started_on: Date.new(2025, 9, 25),
  finished_on: nil
)

create_same_school_mentorship!(
  mentor: hugh_laurie_mentoring_at_abbey_grove,
  mentee: frankie_howard_at_abbey_grove,
  started_on: Date.new(2026, 2, 15),
  finished_on: nil
)

create_same_school_mentorship!(
  mentor: george_cole_at_mallory_towers,
  mentee: imogen_stubbs_at_mallory_towers,
  started_on: Date.new(2025, 7, 15),
  finished_on: nil
)
