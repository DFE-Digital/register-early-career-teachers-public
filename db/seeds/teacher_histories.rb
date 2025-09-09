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
    author_email: 'fkend@appropriate-body.org',
    author_name: 'Felicity Kendall',
    author_type: 'appropriate_body_user',
  }

  FactoryBot.create(
    :event,
    event_type: 'induction_period_opened',
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
  prefix = (tp.started_on.future?) ? 'will be' : 'was'

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

  print_seed_info("* was a mentor at #{sp.school.name} from #{sp.started_on} #{describe_period_duration(sp)} #{suffix}", indent: 4)
end

ambition_institute = LeadProvider.find_by!(name: 'Ambition Institute')
teach_first = LeadProvider.find_by!(name: 'Teach First')
best_practice_network = LeadProvider.find_by!(name: 'Best Practice Network')

abbey_grove_school = School.find_by!(urn: 1_759_427)
ackley_bridge = School.find_by!(urn: 3_375_958)
mallory_towers = School.find_by!(urn: 5_279_293)
brookfield_school = School.find_by!(urn: 2_976_163)

artisan_education_group = DeliveryPartner.find_by!(name: 'Artisan Education Group')
grain_teaching_school_hub = DeliveryPartner.find_by!(name: 'Grain Teaching School Hub')

south_yorkshire_studio_hub = AppropriateBody.find_by!(name: 'South Yorkshire Studio Hub')
golden_leaf_teaching_school_hub = AppropriateBody.find_by!(name: 'Golden Leaf Teaching School Hub')
umber_teaching_school_hub = AppropriateBody.find_by!(name: 'Umber Teaching School Hub')
active_appropriate_bodies = [umber_teaching_school_hub, golden_leaf_teaching_school_hub]

def find_school_partnership(delivery_partner:, lead_provider:, contract_period:)
  SchoolPartnership
    .eager_load(lead_provider_delivery_partnership: [:delivery_partner, { active_lead_provider: %i[lead_provider contract_period] }])
    .find_by!(
      lead_provider_delivery_partnership: { delivery_partner:, active_lead_providers: { lead_provider:, contract_period: } }
    )
end

cp_2022 = ContractPeriod.find_by(year: 2022)
cp_2023 = ContractPeriod.find_by(year: 2023)
_cp_2024 = ContractPeriod.find_by(year: 2024)
cp_2025 = ContractPeriod.find_by(year: 2025)

ambition_artisan_2022 = ActiveLeadProvider.find_by!(contract_period: cp_2022, lead_provider: ambition_institute)
ambition_artisan_2023 = ActiveLeadProvider.find_by!(contract_period: cp_2023, lead_provider: ambition_institute)
teach_first_grain_2022 = ActiveLeadProvider.find_by!(contract_period: cp_2022, lead_provider: teach_first)
teach_first_grain_2025 = ActiveLeadProvider.find_by!(contract_period: cp_2025, lead_provider: teach_first)

ambition_artisan_partnership_2022 = find_school_partnership(
  lead_provider: ambition_institute,
  delivery_partner: artisan_education_group,
  contract_period: ContractPeriod.find_by!(year: 2022)
)
ambition_artisan_partnership_2023 = find_school_partnership(
  lead_provider: ambition_institute,
  delivery_partner: artisan_education_group,
  contract_period: ContractPeriod.find_by!(year: 2023)
)
teach_first_grain_partnership_2022 = find_school_partnership(
  contract_period: ContractPeriod.find_by!(year: 2022),
  lead_provider: teach_first,
  delivery_partner: grain_teaching_school_hub
)
teach_first_grain_partnership_2025 = find_school_partnership(
  contract_period: ContractPeriod.find_by!(year: 2025),
  lead_provider: teach_first,
  delivery_partner: grain_teaching_school_hub
)

print_seed_info("Emma Thompson (mentor)", indent: 2, colour: MENTOR_COLOUR)

emma_thompson = Teacher.find_by!(trs_first_name: 'Emma', trs_last_name: 'Thompson')
emma_thompson_mentoring_at_abbey_grove = FactoryBot.create(:mentor_at_school_period,
                                                           teacher: emma_thompson,
                                                           school: abbey_grove_school,
                                                           email: 'emma.thompson@matilda.com',
                                                           started_on: 3.years.ago,
                                                           finished_on: nil).tap { |sp| describe_mentor_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_mentor,
                  mentor_at_school_period: emma_thompson_mentoring_at_abbey_grove,
                  started_on: 3.years.ago,
                  finished_on: 140.weeks.ago,
                  expression_of_interest: ambition_artisan_2022,
                  school_partnership: ambition_artisan_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

# 10 week break

FactoryBot.create(:training_period,
                  :for_mentor,
                  mentor_at_school_period: emma_thompson_mentoring_at_abbey_grove,
                  started_on: 130.weeks.ago,
                  finished_on: nil,
                  school_partnership: ambition_artisan_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

print_seed_info("Kate Winslet (ECT)", indent: 2, colour: ECT_COLOUR)

kate_winslet = Teacher.find_by!(trs_first_name: 'Kate', trs_last_name: 'Winslet')
kate_winslet_ect_at_ackley_bridge = FactoryBot.create(:ect_at_school_period,
                                                      teacher: kate_winslet,
                                                      school: ackley_bridge,
                                                      email: 'kate.winslet@titanic.com',
                                                      started_on: 1.year.ago,
                                                      finished_on: nil,
                                                      school_reported_appropriate_body: golden_leaf_teaching_school_hub,
                                                      working_pattern: 'full_time').tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  ect_at_school_period: kate_winslet_ect_at_ackley_bridge,
                  started_on: 1.year.ago,
                  finished_on: nil,
                  expression_of_interest: nil,
                  school_partnership: nil,
                  training_programme: 'school_led').tap { |tp| describe_training_period(tp) }

FactoryBot.create(:induction_period,
                  teacher: kate_winslet,
                  started_on: 3.years.ago,
                  finished_on: 2.years.ago,
                  number_of_terms: 3,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  induction_programme: 'fip',
                  training_programme: 'school_led').tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_period,
                  teacher: kate_winslet,
                  started_on: 1.year.ago,
                  finished_on: nil,
                  appropriate_body: umber_teaching_school_hub,
                  induction_programme: 'fip',
                  training_programme: 'school_led',
                  number_of_terms: nil).tap { |ip| describe_induction_period(ip) }

print_seed_info("Hugh Laurie (mentor)", indent: 2, colour: MENTOR_COLOUR)

hugh_laurie = Teacher.find_by!(trs_first_name: 'Hugh', trs_last_name: 'Laurie')
hugh_laurie_mentoring_at_abbey_grove = FactoryBot.create(:mentor_at_school_period,
                                                         teacher: hugh_laurie,
                                                         school: abbey_grove_school,
                                                         email: 'hugh.laurie@house.com',
                                                         started_on: 2.years.ago,
                                                         finished_on: nil).tap { |sp| describe_mentor_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_mentor,
                  mentor_at_school_period: hugh_laurie_mentoring_at_abbey_grove,
                  started_on: 2.years.ago,
                  finished_on: nil,
                  expression_of_interest: teach_first_grain_2022,
                  school_partnership: teach_first_grain_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

print_seed_info("Alan Rickman (ECT)", indent: 2, colour: ECT_COLOUR)

alan_rickman = Teacher.find_by!(trs_first_name: 'Alan', trs_last_name: 'Rickman')
alan_rickman_ect_at_ackley_bridge = FactoryBot.create(:ect_at_school_period,
                                                      teacher: alan_rickman,
                                                      school: ackley_bridge,
                                                      email: 'alan.rickman@diehard.com',
                                                      started_on: 2.years.ago,
                                                      finished_on: nil,
                                                      school_reported_appropriate_body: golden_leaf_teaching_school_hub,
                                                      working_pattern: 'part_time').tap { |sp| describe_ect_at_school_period(sp) }

ackley_bridge.update!(last_chosen_lead_provider: best_practice_network,
                      last_chosen_appropriate_body: golden_leaf_teaching_school_hub,
                      last_chosen_training_programme: 'provider_led')

FactoryBot.create(:training_period,
                  :for_ect,
                  ect_at_school_period: alan_rickman_ect_at_ackley_bridge,
                  started_on: 2.years.ago + 1.month,
                  finished_on: nil,
                  school_partnership: teach_first_grain_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

FactoryBot.create(:induction_period,
                  teacher: alan_rickman,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  started_on: 2.years.ago + 2.months,
                  finished_on: nil,
                  induction_programme: 'fip',
                  training_programme: 'provider_led',
                  number_of_terms: nil).tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_extension,
                  teacher: alan_rickman,
                  number_of_terms: 1.5).tap { |ext| describe_extension(ext) }

active_appropriate_bodies.each do |appropriate_body|
  FactoryBot.create(:pending_induction_submission,
                    appropriate_body:,
                    trn: alan_rickman.trn,
                    date_of_birth: Date.new(1946, 2, 21),
                    started_on: 1.month.ago,
                    finished_on: nil,
                    trs_first_name: alan_rickman.trs_first_name,
                    trs_last_name: alan_rickman.trs_last_name).tap { |is| describe_pending_induction_submission(is) }
end

print_seed_info("Hugh Grant (ECT)", indent: 2, colour: ECT_COLOUR)

hugh_grant = Teacher.find_by!(trs_first_name: 'Hugh', trs_last_name: 'Grant')
hugh_grant_ect_at_abbey_grove = FactoryBot.create(:ect_at_school_period,
                                                  teacher: hugh_grant,
                                                  school: abbey_grove_school,
                                                  email: 'hugh.grant@wonka.com',
                                                  started_on: 2.years.ago,
                                                  finished_on: nil,
                                                  school_reported_appropriate_body: golden_leaf_teaching_school_hub,
                                                  working_pattern: 'part_time').tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  ect_at_school_period: hugh_grant_ect_at_abbey_grove,
                  started_on: 2.years.ago,
                  finished_on: nil,
                  expression_of_interest: nil,
                  school_partnership: nil,
                  training_programme: 'school_led').tap { |tp| describe_training_period(tp) }

FactoryBot.create(:induction_period,
                  teacher: hugh_grant,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  started_on: 2.years.ago + 3.days,
                  finished_on: 1.week.ago,
                  induction_programme: 'fip',
                  training_programme: 'provider_led',
                  number_of_terms: 3).tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_extension,
                  teacher: hugh_grant,
                  number_of_terms: 1.5).tap { |ext| describe_extension(ext) }

FactoryBot.create(:induction_extension,
                  teacher: hugh_grant,
                  number_of_terms: 1).tap { |ext| describe_extension(ext) }

print_seed_info("Colin Firth (ECT)", indent: 2, colour: ECT_COLOUR)

colin_firth = Teacher.find_by!(trs_first_name: 'Colin', trs_last_name: 'Firth')
colin_firth_ect_at_abbey_grove = FactoryBot.create(:ect_at_school_period,
                                                   teacher: colin_firth,
                                                   school: abbey_grove_school,
                                                   email: 'colin.firth@aol.com',
                                                   started_on: 2.years.ago,
                                                   finished_on: nil,
                                                   school_reported_appropriate_body: golden_leaf_teaching_school_hub,
                                                   working_pattern: 'full_time').tap { |sp| describe_ect_at_school_period(sp) }

abbey_grove_school.update!(last_chosen_lead_provider: nil,
                           last_chosen_appropriate_body: golden_leaf_teaching_school_hub,
                           last_chosen_training_programme: 'school_led')

FactoryBot.create(:training_period,
                  :for_ect,
                  ect_at_school_period: colin_firth_ect_at_abbey_grove,
                  started_on: 2.years.ago,
                  finished_on: nil,
                  school_partnership: ambition_artisan_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

FactoryBot.create(:induction_period,
                  teacher: colin_firth,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  started_on: 2.years.ago + 3.days,
                  finished_on: 1.week.ago,
                  induction_programme: 'fip',
                  training_programme: 'provider_led',
                  number_of_terms: 3).tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_extension,
                  teacher: colin_firth,
                  number_of_terms: 1.5).tap { |ext| describe_extension(ext) }

FactoryBot.create(:induction_extension,
                  teacher: colin_firth,
                  number_of_terms: 1).tap { |ext| describe_extension(ext) }

print_seed_info("Harriet Walter (mentor)", indent: 2, colour: MENTOR_COLOUR)

harriet_walter = Teacher.find_by!(trs_first_name: 'Harriet', trs_last_name: 'Walter')
FactoryBot.create(:induction_period,
                  appropriate_body: umber_teaching_school_hub,
                  teacher: harriet_walter,
                  started_on: 2.years.ago,
                  finished_on: 1.year.ago,
                  induction_programme: 'fip',
                  training_programme: 'provider_led',
                  number_of_terms: [1, 2, 3].sample).tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_period,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  teacher: harriet_walter,
                  started_on: 1.year.ago,
                  finished_on: nil,
                  induction_programme: 'fip',
                  training_programme: 'provider_led',
                  number_of_terms: nil).tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_extension,
                  teacher: harriet_walter,
                  number_of_terms: 1.3).tap { |ext| describe_extension(ext) }

FactoryBot.create(:induction_extension,
                  teacher: harriet_walter,
                  number_of_terms: 5).tap { |ext| describe_extension(ext) }

print_seed_info("Imogen Stubbs (ECT)", indent: 2, colour: ECT_COLOUR)

imogen_stubbs = Teacher.find_by!(trs_first_name: 'Imogen', trs_last_name: 'Stubbs')
FactoryBot.create(:induction_period,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  teacher: imogen_stubbs,
                  started_on: 18.months.ago,
                  finished_on: 14.months.ago,
                  induction_programme: 'fip',
                  training_programme: 'provider_led',
                  number_of_terms: 1).tap { |ip| describe_induction_period(ip) }

FactoryBot.create(:induction_period,
                  appropriate_body: golden_leaf_teaching_school_hub,
                  teacher: imogen_stubbs,
                  started_on: 14.months.ago,
                  finished_on: nil,
                  induction_programme: 'cip',
                  training_programme: 'school_led',
                  number_of_terms: nil).tap { |ip| describe_induction_period(ip) }

imogen_stubbs_at_malory_towers = FactoryBot.create(:ect_at_school_period,
                                                   teacher: imogen_stubbs,
                                                   school: mallory_towers,
                                                   email: 'imogen.stubbs@eriktheviking.com',
                                                   started_on: 2.years.ago,
                                                   finished_on: nil,
                                                   school_reported_appropriate_body: golden_leaf_teaching_school_hub,
                                                   working_pattern: 'full_time').tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  ect_at_school_period: imogen_stubbs_at_malory_towers,
                  started_on: 1.year.ago,
                  finished_on: nil,
                  school_partnership: teach_first_grain_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

FactoryBot.create(:induction_extension,
                  teacher: imogen_stubbs,
                  number_of_terms: 1).tap { |ext| describe_extension(ext) }

print_seed_info("Gemma Jones (ECT)", indent: 2, colour: ECT_COLOUR)

gemma_jones = Teacher.find_by!(trs_first_name: 'Gemma', trs_last_name: 'Jones')
FactoryBot.create(:induction_period,
                  appropriate_body: umber_teaching_school_hub,
                  teacher: gemma_jones,
                  started_on: 20.months.ago,
                  finished_on: nil,
                  induction_programme: 'fip',
                  training_programme: 'provider_led',
                  number_of_terms: nil).tap { |ip| describe_induction_period(ip) }

gemma_jones_at_malory_towers = FactoryBot.create(:ect_at_school_period,
                                                 teacher: gemma_jones,
                                                 school: mallory_towers,
                                                 email: 'gemma.jones@rocketman.com',
                                                 started_on: 21.months.ago,
                                                 finished_on: nil,
                                                 school_reported_appropriate_body: golden_leaf_teaching_school_hub,
                                                 working_pattern: 'part_time').tap { |sp| describe_ect_at_school_period(sp) }

mallory_towers.update!(last_chosen_lead_provider: best_practice_network,
                       last_chosen_appropriate_body: golden_leaf_teaching_school_hub,
                       last_chosen_training_programme: 'provider_led')

FactoryBot.create(:training_period,
                  :for_ect,
                  ect_at_school_period: gemma_jones_at_malory_towers,
                  started_on: 20.months.ago,
                  finished_on: nil,
                  school_partnership: teach_first_grain_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

FactoryBot.create(:induction_extension,
                  teacher: gemma_jones,
                  number_of_terms: 1.5).tap { |ext| describe_extension(ext) }

print_seed_info("André Roussimoff (ECT)", indent: 2, colour: ECT_COLOUR)

andre_roussimoff = Teacher.find_by!(trs_first_name: 'André', trs_last_name: 'Roussimoff')
andre_roussimoff_mentoring_at_ackley_bridge = FactoryBot.create(:mentor_at_school_period,
                                                                teacher: andre_roussimoff,
                                                                school: ackley_bridge,
                                                                email: 'andre.giant@wwf.com',
                                                                started_on: 1.year.ago,
                                                                finished_on: nil).tap { |sp| describe_mentor_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_mentor,
                  mentor_at_school_period: andre_roussimoff_mentoring_at_ackley_bridge,
                  started_on: 1.year.ago,
                  finished_on: nil,
                  school_partnership: teach_first_grain_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

print_seed_info("Anthony Hopkins (ECT)", indent: 2, colour: ECT_COLOUR)

anthony_hopkins = Teacher.find_by!(trs_first_name: 'Anthony', trs_last_name: 'Hopkins')
anthony_hopkins_ect_at_brookfield_school = FactoryBot.create(:ect_at_school_period,
                                                             teacher: anthony_hopkins,
                                                             school: brookfield_school,
                                                             email: 'anthony.hopkins@favabeans.com',
                                                             school_reported_appropriate_body: umber_teaching_school_hub,
                                                             started_on: 2.years.ago,
                                                             finished_on: nil,
                                                             working_pattern: 'part_time').tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  ect_at_school_period: anthony_hopkins_ect_at_brookfield_school,
                  started_on: 2.years.ago,
                  finished_on: nil,
                  school_partnership: teach_first_grain_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

print_seed_info("Stephen Fry (ECT)", indent: 2, colour: ECT_COLOUR)

stephen_fry = Teacher.find_by!(trs_first_name: 'Stephen', trs_last_name: 'Fry')
stephen_fry_ect_at_brookfield_school = FactoryBot.create(:ect_at_school_period,
                                                         teacher: stephen_fry,
                                                         school: brookfield_school,
                                                         email: 'stephen.fry@sausage.com',
                                                         started_on: 2.years.ago,
                                                         finished_on: nil,
                                                         school_reported_appropriate_body: south_yorkshire_studio_hub,
                                                         working_pattern: 'part_time').tap { |sp| describe_ect_at_school_period(sp) }

brookfield_school.update!(last_chosen_lead_provider: teach_first,
                          last_chosen_appropriate_body: south_yorkshire_studio_hub,
                          last_chosen_training_programme: 'provider_led')

FactoryBot.create(:training_period,
                  :for_ect,
                  ect_at_school_period: stephen_fry_ect_at_brookfield_school,
                  started_on: 2.years.ago,
                  finished_on: nil,
                  school_partnership: teach_first_grain_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

print_seed_info("Harriet Walter (ECT) with multiple induction periods", indent: 2, colour: ECT_COLOUR)

harriet_walter_ect_at_brookfield_school = FactoryBot.create(:ect_at_school_period,
                                                            teacher: harriet_walter,
                                                            school: brookfield_school,
                                                            email: 'harriet-walter@history.com',
                                                            started_on: 2.years.ago,
                                                            finished_on: nil,
                                                            school_reported_appropriate_body: south_yorkshire_studio_hub).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  ect_at_school_period: harriet_walter_ect_at_brookfield_school,
                  started_on: 2.years.ago,
                  finished_on: nil,
                  school_partnership: teach_first_grain_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

print_seed_info("Helen Mirren (mentor)", indent: 2, colour: MENTOR_COLOUR)

helen_mirren = Teacher.find_by!(trs_first_name: 'Helen', trs_last_name: 'Mirren')
helen_mirren_mentoring_at_brookfield_school = FactoryBot.create(:mentor_at_school_period,
                                                                teacher: helen_mirren,
                                                                school: brookfield_school,
                                                                email: 'helen.mirren@titania.com',
                                                                started_on: 2.years.ago,
                                                                finished_on: nil).tap { |sp| describe_mentor_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_mentor,
                  mentor_at_school_period: helen_mirren_mentoring_at_brookfield_school,
                  started_on: 2.years.ago,
                  finished_on: nil,
                  school_partnership: teach_first_grain_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

print_seed_info("John Withers (mentor)", indent: 2, colour: MENTOR_COLOUR)

john_withers = Teacher.find_by!(trs_first_name: 'John', trs_last_name: 'Withers')
john_withers_mentoring_at_abbey_grove = FactoryBot.create(:mentor_at_school_period,
                                                          teacher: john_withers,
                                                          school: abbey_grove_school,
                                                          email: 'john.withers@amusementpark.com',
                                                          started_on: 2.years.ago,
                                                          finished_on: nil).tap { |sp| describe_mentor_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_mentor,
                  mentor_at_school_period: john_withers_mentoring_at_abbey_grove,
                  started_on: 2.years.ago,
                  finished_on: nil,
                  school_partnership: teach_first_grain_partnership_2022,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

print_seed_info("Dominic West (ECT)", indent: 2, colour: ECT_COLOUR)

dominic_west = Teacher.find_by!(trs_first_name: 'Dominic', trs_last_name: 'West')
dominic_west_ect_at_brookfield_school = FactoryBot.create(:ect_at_school_period,
                                                          teacher: dominic_west,
                                                          school: brookfield_school,
                                                          email: 'harriet-walter@history.com',
                                                          started_on: 18.months.ago,
                                                          finished_on: nil,
                                                          school_reported_appropriate_body: south_yorkshire_studio_hub).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  ect_at_school_period: dominic_west_ect_at_brookfield_school,
                  started_on: 18.months.ago,
                  finished_on: nil,
                  school_partnership: ambition_artisan_partnership_2023,
                  expression_of_interest: ambition_artisan_2023,
                  training_programme: 'provider_led').tap { |tp| describe_training_period(tp) }

print_seed_info("Peter Davison (ECT)", indent: 2, colour: ECT_COLOUR)

peter_davison = Teacher.find_by!(trs_first_name: 'Peter', trs_last_name: 'Davison')
peter_davison_at_abbey_grove_school = FactoryBot.create(:ect_at_school_period,
                                                        teacher: peter_davison,
                                                        school: abbey_grove_school,
                                                        email: 'pd@tardis.bbc',
                                                        started_on: 2.weeks.from_now,
                                                        finished_on: nil,
                                                        school_reported_appropriate_body: south_yorkshire_studio_hub).tap { |sp| describe_ect_at_school_period(sp) }

FactoryBot.create(:training_period,
                  :for_ect,
                  ect_at_school_period: peter_davison_at_abbey_grove_school,
                  started_on: 2.weeks.from_now,
                  finished_on: nil,
                  school_partnership: teach_first_grain_partnership_2025,
                  training_programme: 'provider_led',
                  expression_of_interest: teach_first_grain_2025).tap { |tp| describe_training_period(tp) }

print_seed_info("Adding mentorships:")

FactoryBot.create(:mentorship_period,
                  mentor: emma_thompson_mentoring_at_abbey_grove,
                  mentee: hugh_grant_ect_at_abbey_grove,
                  started_on: 2.years.ago,
                  finished_on: 1.year.ago).tap { |mp| describe_mentorship_period(mp) }

FactoryBot.create(:mentorship_period,
                  mentor: hugh_laurie_mentoring_at_abbey_grove,
                  mentee: hugh_grant_ect_at_abbey_grove,
                  started_on: 1.year.ago,
                  finished_on: nil).tap { |mp| describe_mentorship_period(mp) }

FactoryBot.create(:mentorship_period,
                  mentor: andre_roussimoff_mentoring_at_ackley_bridge,
                  mentee: kate_winslet_ect_at_ackley_bridge,
                  started_on: 1.year.ago,
                  finished_on: nil).tap { |mp| describe_mentorship_period(mp) }

FactoryBot.create(:mentorship_period,
                  mentor: helen_mirren_mentoring_at_brookfield_school,
                  mentee: stephen_fry_ect_at_brookfield_school,
                  started_on: 1.year.ago,
                  finished_on: nil).tap { |mp| describe_mentorship_period(mp) }
