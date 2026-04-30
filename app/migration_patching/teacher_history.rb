class TeacherHistory
  attr_reader :teacher,
              :ect_at_school_periods,
              :mentor_at_school_periods,
              :ecf2_ect_combination_summaries,
              :ecf2_mentor_combination_summaries,
              :ecf2_mentorship_summaries,
              :training_periods,
              :mentorship_periods,
              :migration_mode

  def initialize(teacher:, ect_at_school_periods: [], mentor_at_school_periods: [])
    @teacher = teacher
    @ect_at_school_periods = ect_at_school_periods
    @mentor_at_school_periods = mentor_at_school_periods
  end

  def self.build(teacher:)
    # build the objects
    teacher_data = teacher_data(teacher:)
    ect_periods = ect_periods(ect_at_school_periods: teacher.ect_at_school_periods)
    mentor_periods = mentor_periods(mentor_at_school_periods: teacher.mentor_at_school_periods)

    new(teacher: teacher_data, ect_at_school_periods: ect_periods, mentor_at_school_periods: mentor_periods)
  end

  def to_h
    {
      teacher: {
        ect_at_school_periods: ect_at_school_periods.map(&:to_h),
        mentor_at_school_periods: mentor_at_school_periods.map(&:to_h),
        **teacher.to_h,
      }
    }
  end

private

  def self.teacher_data(teacher:)
    teacher.attributes.symbolize_keys
  end

  def self.ect_periods(ect_at_school_periods:)
    ect_at_school_periods.map do |school_period|
      school_period.attributes.symbolize_keys.merge(
        training_periods: school_period.training_periods.map do |training_period|
          training_data(training_period:)
        end
      )
    end
  end

  def self.mentor_periods(mentor_at_school_periods:)
    mentor_at_school_periods.map do |school_period|
      school_period.attributes.symbolize_keys.merge(
        training_periods: school_period.training_periods.map do |training_period|
          training_data(training_period:)
        end
      )
    end
  end

  def self.training_data(training_period:)
    attrs = training_period.attributes.symbolize_keys.slice(:id,
                                                            :started_on,
                                                            :finished_on,
                                                            :training_programme,
                                                            :deferred_at,
                                                            :deferral_reason,
                                                            :withdrawn_at,
                                                            :withdrawal_reason
                                                           )

    attrs[:school_partnership] = school_partnership_data(school_partnership: training_period.school_partnership)
    attrs[:expression_of_interest] = eoi_data(active_lead_provider: training_period.expression_of_interest)
    attrs[:schedule] = schedule_data(schedule: training_period.schedule)

    attrs.except(:school_partnership_id,
                 :schedule_id,
                 :expression_of_interest_id,
                 :ect_at_school_period_id,
                 :mentor_at_school_period_id)
  end

  def self.school_partnership_data(school_partnership:)
    return nil if school_partnership.blank?
    
    school = school_partnership.school
    lead_provider = school_partnership.lead_provider
    delivery_partner = school_partnership.delivery_partner
    contract_period = school_partnership.contract_period

    {
      school: { urn: school.urn, name: school.name },
      lead_provider: { name: lead_provider.name },
      delivery_partner: { name: delivery_partner.name },
      contract_period_year: contract_period.year,
    }
  end

  def self.eoi_data(active_lead_provider:)
    return nil if active_lead_provider.blank?

    {
      lead_provider: { name: active_lead_provider.lead_provider.name },
      contract_period_year: active_lead_provider.contract_period_year,
    }
  end

  def self.schedule_data(schedule:)
    return nil if schedule.blank?

    {
      identifier: schedule.identifier,
      contract_period_year: schedule.contract_period_year,
    }
  end
end
