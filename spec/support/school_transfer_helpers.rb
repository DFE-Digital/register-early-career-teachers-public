module SchoolTransferHelpers
private

  def create_school_period(teacher, from:, to: nil, type: :ect)
    FactoryBot.create(
      :"#{type}_at_school_period",
      started_on: from,
      finished_on: to,
      teacher:
    )
  end

  def add_training_period(school_period, programme_type:, from:, to: nil, with: nil)
    type = if school_period.is_a?(ECTAtSchoolPeriod)
             :ect
           else
             :mentor
           end

    case programme_type
    when :provider_led
      FactoryBot.create(
        :training_period,
        :"for_#{type}",
        :provider_led,
        started_on: from,
        finished_on: to,
        "#{type}_at_school_period" => school_period,
        school_partnership: school_partnership_between(
          lead_provider: with,
          school: school_period.school
        )
      )
    when :school_led
      FactoryBot.create(
        :training_period,
        :"for_#{type}",
        :school_led,
        started_on: from,
        finished_on: to,
        "#{type}_at_school_period" => school_period
      )
    end
  end

  def school_partnership_between(lead_provider:, school:)
    existing_school_partnership = SchoolPartnership
      .includes(:active_lead_provider)
      .joins(:active_lead_provider)
      .find_by(active_lead_provider: { lead_provider: }, school:)

    unless existing_school_partnership
      lead_provider_delivery_partnership = FactoryBot.create(
        :lead_provider_delivery_partnership,
        active_lead_provider: FactoryBot.create(
          :active_lead_provider,
          lead_provider:
        )
      )
      school_partnership = FactoryBot.create(
        :school_partnership,
        lead_provider_delivery_partnership:,
        school:
      )
    end

    existing_school_partnership.presence || school_partnership
  end
end
