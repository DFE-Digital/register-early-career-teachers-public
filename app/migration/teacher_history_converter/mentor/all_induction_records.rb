class TeacherHistoryConverter::Mentor::AllInductionRecords
  include TeacherHistoryConverter::CalculatedAttributes

  attr_reader :trn, :profile_id, :induction_records, :states, :transfers, :exclude_training_periods

  def initialize(trn:, profile_id:, induction_records:, states:, transfers:, exclude_training_periods: false)
    @trn = trn
    @profile_id = profile_id
    @induction_records = induction_records
    @states = states
    @transfers = transfers
    @exclude_training_periods = exclude_training_periods
  end

  # Returns [ECF2TeacherHistory::MentorAtSchoolPeriod[], String[]]
  def mentor_at_school_periods
    @mentor_at_school_periods ||= build_mentor_at_school_periods
  end

private

  def build_mentor_at_school_periods
    school_periods = []
    last_school_period = nil
    last_training_period = nil

    induction_records.sort_by { |ir| [ir.start_date, ir.created_at] }.each do |induction_record|
      started_on = induction_record.start_date
      finished_on = induction_record.end_date

      if last_school_period.nil? || last_school_period.school != induction_record.school
        # this is a new mentor_at_school_period
        # with a new training_period

        # check for overlaps if the last_school_period exists
        if last_school_period.present?
          # check school period and nested training and mentorship period for overlapping dates
          check_and_fix_all_overlaps(school_periods, last_school_period, started_on)
        end

        last_training_period = build_training_period(induction_record, started_on:, finished_on:) unless exclude_training_periods

        last_school_period = ECF2TeacherHistory::MentorAtSchoolPeriod.new(
          started_on:,
          finished_on:,
          school: induction_record.school,
          email: induction_record.preferred_identity_email,
          training_periods: [last_training_period].compact
        )
        school_periods << last_school_period
      else
        # extend school period
        last_school_period.finished_on = finished_on
        last_school_period.email = induction_record.preferred_identity_email

        if exclude_training_periods == false
          if training_period_changed?(last_training_period, induction_record)
            # this is a new training_period
            # check for overlaps
            check_and_fix_period_overlaps(last_training_period, started_on) if last_training_period.present?

            last_training_period = build_training_period(induction_record, started_on:, finished_on:)
            last_school_period.training_periods << last_training_period if last_training_period.present?
          elsif last_training_period.present?
            # extend training period
            # we should check for withdrawn here and ensure we close it or not overwrite the finished_at
            withdrawal_data = withdrawal_data(
              training_status: induction_record.training_status,
              lead_provider_id: training_provider_info&.lead_provider_info&.ecf1_id
            )

            last_training_period.finished_on = if withdrawal_data.withdrawn_at.present?
                                                 last_training_period.withdrawn_at = withdrawal_data.withdrawn_at
                                                 last_training_period.withdrawal_reason = withdrawal_data.withdrawal_reason

                                                 if last_training_period.finished_on.blank?
                                                   [last_training_period.started_on + 1.day, withdrawal_data.withdrawn_at.to_date].max
                                                 else
                                                   [finished_on, withdrawal_data.withdrawn_at.to_date].compact.max
                                                 end
                                               else
                                                 finished_on
                                               end
          end
        end
      end
    end

    school_periods
  end

  def training_period_changed?(training_period, induction_record)
    return true if training_period.blank?
    return true if training_period.withdrawn_at.present?

    training_period.training_programme != convert_training_programme_name(induction_record.training_programme) ||
      training_period&.lead_provider_info != induction_record&.training_provider_info&.lead_provider_info ||
      training_period&.delivery_partner_info != induction_record&.training_provider_info&.delivery_partner_info ||
      training_period.contract_period_year != induction_record&.training_provider_info&.cohort_year
  end

  def check_and_fix_all_overlaps(school_periods, current_school_period, next_period_started_on)
    if next_period_started_on <= current_school_period.started_on + 1.day
      # stub the school period and nested periods
      num_periods_needed = [1, current_school_period.training_periods.count].compact.max

      # stub before 1st period (this might be the same as current_school_period)
      first_period = school_periods.min_by(&:started_on)
      # need 2 days per period
      modified_started_on = first_period.started_on - (num_periods_needed * 2.days)
      modified_finished_on = first_period.started_on - 1.day

      current_school_period.started_on = modified_started_on
      current_school_period.finished_on = modified_finished_on
      current_school_period.training_periods.each_with_index do |training_period, idx|
        training_period.started_on = modified_started_on + (idx * 2.days)
        training_period.finished_on = modified_started_on + 1.day + (idx * 2.days)
      end
    else
      check_and_fix_period_overlaps(current_school_period, next_period_started_on)
      current_school_period.training_periods.each { check_and_fix_period_overlaps(it, next_period_started_on) }
    end
  end

  def check_and_fix_period_overlaps(period, next_period_started_on)
    if period.finished_on.blank? || period.finished_on >= next_period_started_on
      period.finished_on = next_period_started_on - 1.day
    end
  end

  # def process(mentor_at_school_periods, induction_record)
  #   started_on = induction_record.start_date
  #   finished_on = induction_record.end_date

  #   # we do not want to add training periods for ERO mentors (unless they have paid or clawed_back declarations)
  #   training_period = build_training_period(induction_record, { started_on:, finished_on: }) unless exclude_training_periods

  #   mentor_at_school_periods.unshift(
  #     ECF2TeacherHistory::MentorAtSchoolPeriod.new(
  #       started_on:,
  #       finished_on:,
  #       school: induction_record.school,
  #       email: induction_record.preferred_identity_email,
  #       training_periods: [training_period].compact
  #     )
  #   )
  # end

  def build_training_period(induction_record, overrides = {})
    training_programme = convert_training_programme_name(induction_record.training_programme)
    return if training_programme != "provider_led"

    training_provider_info = induction_record.training_provider_info

    raise(StandardError, "No training provider info for #{induction_record.induction_record_id}") if training_provider_info.nil?

    training_attrs = {
      started_on: induction_record.start_date,
      finished_on: induction_record.end_date,
      created_at: induction_record.created_at,
      school: induction_record.school,
      training_programme:,
      lead_provider_info: training_provider_info&.lead_provider_info,
      delivery_partner_info: training_provider_info&.delivery_partner_info,
      contract_period_year: training_provider_info&.cohort_year,
      is_ect: false,
      ecf_start_induction_record_id: induction_record.induction_record_id,
      schedule_info: induction_record.schedule_info,
      api_transfer_updated_at: transfers[training_provider_info.lead_provider_info.ecf1_id],
      combination: build_combination(induction_record:, training_programme:),
      **withdrawal_data(
        training_status: induction_record.training_status,
        lead_provider_id: training_provider_info&.lead_provider_info&.ecf1_id
      )
    }.merge(overrides)

    # if the period is ongoing but has been withdrawn by the provider we should close the period
    if training_attrs[:finished_on].blank? && training_attrs[:withdrawn_at].present?
      training_attrs[:finished_on] = [training_attrs[:started_on] + 1.day, training_attrs[:withdrawn_at].to_date].max
    end

    ECF2TeacherHistory::TrainingPeriod.new(**training_attrs)
  end

  def build_combination(induction_record:, **overrides)
    ECF2TeacherHistory::Combination
      .from_induction_record(trn:, profile_id:, profile_type: "mentor", induction_record:, **overrides)
  end

  def withdrawal_data(training_status:, lead_provider_id:)
    TeacherHistoryConverter::WithdrawalData.new(training_status:, states:, lead_provider_id:).withdrawal_data
  end
end
