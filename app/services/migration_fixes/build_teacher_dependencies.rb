class MigrationFixes::BuildTeacherDependencies
  attr_reader :teacher

  def initialize(teacher:)
    @teacher = teacher
  end

  def dependencies
    @dependencies ||= build_dependency_list
  end

private

  def build_dependency_list
    list = {}

    teacher.ect_at_school_periods.each_with_index do |school_period, idx|
      ect_list = list[:ect_at_school_periods] ||= {}
      label = "ect_at_school_period_#{idx + 1}"
      ect_list[school_period.id.to_s] = { label:, data: school_period }

      school_period_dependencies(school_period, list)
    end

    teacher.mentor_at_school_periods.each_with_index do |school_period, idx|
      mentor_list = list[:mentor_at_school_periods] ||= {}
      label = "mentor_at_school_period_#{idx + 1}"
      mentor_list[school_period.id.to_s] = { label:, data: school_period }

      school_period_dependencies(school_period, list)
    end

    list
  end

  def school_dependencies(school, list)
    school_list = list[:schools] ||= {}

    return list if school_list[school.id.to_s].present?

    school_list[school.id.to_s] = { label: "school_#{school_list.count + 1}", data: school }

    list
  end

  def school_period_dependencies(school_period, list)
    school_dependencies(school_period.school, list)

    school_period.training_periods.each do |training_period|
      list = training_period_dependencies(training_period, list)
    end

    list
  end

  def training_period_dependencies(training_period, list)
    tp_list = list[:training_periods] ||= {}

    if tp_list[training_period.id.to_s].blank?
      tp_list[training_period.id.to_s] = { label: "training_period_#{tp_list.count + 1}", data: training_period }
    end

    if training_period.expression_of_interest.present?
      list = active_lead_provider_dependencies(training_period.expression_of_interest, list)
    end

    if training_period.schedule.present?
      schedule_list = list[:schedules] ||= {}
      schedule = training_period.schedule

      if schedule_list[schedule.id.to_s].blank?
        schedule_list[training_period.schedule_id.to_s] = { label: "schedule_#{schedule_list.count + 1}", data: schedule }
        list = contract_period_dependencies(schedule.contract_period, list)
      end
    end

    if training_period.school_partnership.present?
      list = school_partnership_dependencies(training_period.school_partnership, list)
    end

    list
  end

  def school_partnership_dependencies(school_partnership, list)
    school_partnership_list = list[:school_partnerships] ||= {}
    return list if school_partnership_list.has_key?(school_partnership.id.to_s)

    school_partnership_list[school_partnership.id.to_s] = { label: "school_partnership_#{school_partnership_list.count + 1}", data: school_partnership }

    list = school_dependencies(school_partnership.school, list)

    list = provider_partnership_dependencies(school_partnership.lead_provider_delivery_partnership, list)
  end

  def provider_partnership_dependencies(partnership, list)
    lpdp_list = list[:lead_provider_delivery_partnerships] ||= {}
    return list if lpdp_list[partnership.id.to_s].present?

    lpdp_list[partnership.id.to_s] = { label: "lpdp_#{lpdp_list.count + 1}", data: partnership }

    list = active_lead_provider_dependencies(partnership.active_lead_provider, list)

    dp_list = list[:delivery_partners] ||= {}
    delivery_partner = partnership.delivery_partner
    if dp_list[delivery_partner.id.to_s].blank?
      dp_list[delivery_partner.id.to_s] = { label: "delivery_partner_#{dp_list.count + 1}", data: delivery_partner }
    end

    list
  end

  def active_lead_provider_dependencies(alp, list)
    alp_list = list[:active_lead_providers] ||= {}
    return list if alp_list[alp.id.to_s].present?

    alp_list[alp.id.to_s] = { label: "active_lead_provider_#{alp_list.count + 1}", data: alp }

    lp_list = list[:lead_providers] ||= {}
    lead_provider = alp.lead_provider
    lp_list[lead_provider.id.to_s] = { label: "lead_provider_#{lp_list.count + 1}", data: lead_provider }
    
    contract_period_dependencies(alp.contract_period, list)
  end

  def contract_period_dependencies(contract_period, list)
    cp_list = list[:contract_periods] ||= {}
    return list if cp_list[contract_period.year.to_s].present?

    cp_list[contract_period.year.to_s] = { label: "contract_period_#{contract_period.year}", data:  contract_period }
    list
  end
end
