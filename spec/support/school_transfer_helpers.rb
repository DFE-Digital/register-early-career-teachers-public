module SchoolTransferHelpers
private

  def build_ignored_transfer_for_finished_school_period(teacher:, lead_provider:, type: :ect)
    school_period1 = create_school_period(teacher, from: 1.year.ago, to: 1.week.ago, type:)
    add_training_period(school_period1, programme_type: :provider_led, from: 1.year.ago, to: 9.months.ago, with: lead_provider)
    add_training_period(school_period1, programme_type: :provider_led, from: 9.months.ago, to: 3.months.ago, with: lead_provider)
    add_training_period(school_period1, programme_type: :school_led, from: 3.months.ago, to: 1.week.ago)
  end

  def build_unknown_transfer_for_finished_school_period(teacher:, lead_provider:, type: :ect)
    school_period1 = create_school_period(teacher, from: 1.year.ago, to: 1.week.ago, type:)
    original_lead_provider = FactoryBot.create(:lead_provider)
    add_training_period(school_period1, programme_type: :provider_led, from: 1.year.ago, to: 9.months.ago, with: original_lead_provider)
    add_training_period(school_period1, programme_type: :provider_led, from: 9.months.ago, to: 3.months.ago, with: original_lead_provider)
    add_training_period(school_period1, programme_type: :provider_led, from: 3.months.ago, to: 1.week.ago, with: lead_provider)
  end

  def build_new_school_transfer(teacher:, lead_provider:, type: :ect)
    school_period1 = create_school_period(teacher, from: 1.year.ago, to: 6.months.ago, type:)
    add_training_period(school_period1, programme_type: :provider_led, from: 1.year.ago, to: 6.months.ago, with: lead_provider)
    school_period2 = create_school_period(teacher, from: 6.months.ago, type:)
    add_training_period(school_period2, programme_type: :provider_led, from: 6.months.ago, to: 3.months.ago, with: lead_provider)
    latest_lead_provider = FactoryBot.create(:lead_provider)
    add_training_period(school_period2, programme_type: :provider_led, from: 3.months.ago, with: latest_lead_provider)
  end

  def build_new_provider_transfer(teacher:, leaving_lead_provider: nil, joining_lead_provider: nil, type: :ect)
    unless leaving_lead_provider || joining_lead_provider
      raise ArgumentError, "Need either leaving_lead_provider or joining_lead_provider"
    end

    school_period1 = create_school_period(teacher, from: 1.year.ago, to: 6.months.ago, type:)
    school_period2 = create_school_period(teacher, from: 6.months.ago, type:)

    if leaving_lead_provider && joining_lead_provider
      add_training_period(school_period1, programme_type: :provider_led, from: 1.year.ago, to: 6.months.ago, with: leaving_lead_provider)
      add_training_period(school_period2, programme_type: :provider_led, from: 6.months.ago, to: 3.months.ago, with: joining_lead_provider)
      latest_lead_provider = FactoryBot.create(:lead_provider)
      add_training_period(school_period2, programme_type: :provider_led, from: 3.months.ago, with: latest_lead_provider)
    elsif leaving_lead_provider
      add_training_period(school_period1, programme_type: :provider_led, from: 1.year.ago, to: 6.months.ago, with: leaving_lead_provider)
      add_training_period(school_period2, programme_type: :school_led, from: 6.months.ago, to: 3.months.ago)
    elsif joining_lead_provider
      add_training_period(school_period1, programme_type: :school_led, from: 1.year.ago, to: 6.months.ago)
      add_training_period(school_period2, programme_type: :provider_led, from: 6.months.ago, to: 3.months.ago, with: joining_lead_provider)
    end
  end

  def build_ignored_transfer(teacher:, lead_provider:, type: :ect)
    school_period1 = create_school_period(teacher, from: 1.year.ago, to: 6.months.ago, type:)
    add_training_period(school_period1, programme_type: :school_led, from: 1.year.ago, to: 6.months.ago)
    school_period2 = create_school_period(teacher, from: 6.months.ago, type:)
    add_training_period(school_period2, programme_type: :school_led, from: 6.months.ago, to: 1.week.ago)
    add_training_period(school_period2, programme_type: :provider_led, from: 1.week.ago, with: lead_provider)
  end

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
