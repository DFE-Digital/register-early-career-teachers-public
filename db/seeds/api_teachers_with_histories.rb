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

  print_seed_info("* was a mentor at #{sp.school.name} from #{sp.started_on} #{describe_period_duration(sp)} #{suffix}", indent: 4)
end

def random_school_partnership(active_lead_provider:, excluding_school: nil)
  SchoolPartnership
    .includes(lead_provider_delivery_partnership: :active_lead_provider)
    .where(lead_provider_delivery_partnership: { active_lead_provider: })
    .where.not(school: excluding_school)
    .order("RANDOM()")
    .first!
end

def create_teacher(attrs:)
  traits = attrs.delete(:traits) || []
  FactoryBot.build(:teacher, :with_realistic_name, *traits, attrs).tap do
    random_date = rand(1..100).days.ago
    it.update!(
      created_at: random_date,
      updated_at: random_date,
      api_updated_at: random_date,
      api_unfunded_mentor_updated_at: random_date
    )
  end
end

# Create extra participants for API review app testing
# - 5x participants for each lead provider and contract period
print_seed_info("Adding extra participants for API testing:")

teachers = [
  { types: %i[ect], traits: %i[with_uplifts with_teacher_id_change], frozen_year: 2021 },
  { types: %i[ect], traits: %i[with_uplifts], frozen_year: 2022 },
  { types: %i[ect mentor], traits: %i[with_teacher_id_change] },

  { types: %i[mentor], traits: %i[with_teacher_id_change], frozen_year: 2021 },
  { types: %i[mentor], traits: %i[] },
]

ActiveLeadProvider.find_each do |active_lead_provider|
  contract_period = active_lead_provider.contract_period

  teachers.each do |attrs|
    attrs = attrs.deep_dup
    trainee_types = attrs.delete(:types)
    frozen_year = attrs.delete(:frozen_year)

    teacher = create_teacher(attrs:)
    full_name = "#{teacher.trs_first_name} #{teacher.trs_last_name}"

    trainee_types.each do |trainee_type|
      print_seed_info("#{full_name} (#{trainee_type.upcase})", indent: 2, colour: (trainee_type == :ect ? :magenta : :yellow))

      if frozen_year && contract_period.year == 2024
        teacher.update!("#{trainee_type}_payments_frozen_year": frozen_year)
      end

      started_on = Date.new(contract_period.year, 9, 1) + rand(1..100).days

      school_partnership = random_school_partnership(active_lead_provider:)

      at_school_period = FactoryBot.create(
        :"#{trainee_type}_at_school_period",
        school: school_partnership.school,
        teacher:,
        started_on:,
        finished_on: nil
      ).tap { |sp| send(:"describe_#{trainee_type}_at_school_period", sp) }

      schedule = if trainee_type == :mentor
                   Schedule
                    .where(contract_period:)
                    .order("RANDOM()")
                    .first
                 else
                   Schedule
                    .excluding_replacement_schedules
                    .where(contract_period:)
                    .order("RANDOM()")
                    .first
                 end

      FactoryBot.create(
        :training_period,
        :"for_#{trainee_type}",
        :provider_led,
        :with_schedule,
        "#{trainee_type}_at_school_period": at_school_period,
        started_on: at_school_period.started_on,
        finished_on: at_school_period.finished_on,
        schedule:,
        school_partnership:
      ).tap { |tp| describe_training_period(tp) }
    end
  end
end
