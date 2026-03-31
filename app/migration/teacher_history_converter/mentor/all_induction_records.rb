class TeacherHistoryConverter::Mentor::AllInductionRecords
  include TeacherHistoryConverter::CalculatedAttributes
  include TeacherHistoryConverter::SetFinishedOn

  attr_reader :trn, :profile_id, :induction_records, :states, :transfers, :exclude_training_periods, :mentor_completion_date, :school_mentors

  def initialize(trn:, profile_id:, induction_records:, states:, transfers:, school_mentors:, mentor_completion_date: nil, exclude_training_periods: false)
    @trn = trn
    @profile_id = profile_id
    @induction_records = induction_records
    @states = states
    @transfers = transfers
    @mentor_completion_date = mentor_completion_date
    @school_mentors = school_mentors
    @exclude_training_periods = exclude_training_periods
  end

  # Returns [ECF2TeacherHistory::MentorAtSchoolPeriod[], String[]]
  def mentor_at_school_periods
    @mentor_at_school_periods ||= build_mentor_at_school_periods
  end

private

  def build_mentor_at_school_periods
    @school_periods = []
    @current__school_period = nil
    @current_training_period = nil

    induction_records.sort_by { |ir| [ir.start_date, ir.created_at] }.each do |induction_record|
      if changes_school?(induction_record:)
        add_school_period(induction_record:)
      else
        extend_school_period(induction_record:)
      end
    end

    @school_periods += pooled_mentor_at_school_periods(excluded_schools: @school_periods.map(&:school).map(&:urn))
  end

  def pooled_mentor_at_school_periods(excluded_schools:)
    school_mentors.reject { excluded_schools.include?(it.school[:urn]) }.map do |school_mentor|
      ECF2TeacherHistory::MentorAtSchoolPeriod.new(
        started_on: school_mentor.created_at.to_date,
        finished_on: nil,
        school: school_mentor.school,
        email: school_mentor.preferred_identity_email
      )
    end
  end

  def add_school_period(induction_record:)
    started_on = induction_record.start_date
    finished_on = induction_record.end_date

    # check any previous school period, training and mentorship period for overlapping dates
    check_and_fix_all_overlaps(started_on)

    @current_training_period = build_training_period(induction_record, started_on:, finished_on:) unless exclude_training_periods

    @current_school_period = ECF2TeacherHistory::MentorAtSchoolPeriod.new(
      started_on:,
      finished_on:,
      school: induction_record.school,
      email: induction_record.preferred_identity_email,
      training_periods: [@current_training_period].compact
    )

    @school_periods << @current_school_period
  end

  def extend_school_period(induction_record:)
    return if exclude_training_periods

    @current_school_period.finished_on = induction_record.end_date
    @current_school_period.email = induction_record.preferred_identity_email

    if changes_training_period?(induction_record:)
      # ignore if this induction_record is withdrawn or deferred and ongoing
      # as this means it's the final record and wasn't pre-washed
      unless ongoing_withdrawal_or_deferral?(induction_record:)
        # this is a new training_period
        # check for overlaps
        check_and_fix_period_overlaps(@current_training_period, started_on) if @current_training_period.present?

        # we do not want to create or extend training periods if the induction records are withdrawn/deferred
        # and the previous period was similarly withdrawn/deferred
        @current_training_period = build_training_period(induction_record, started_on:, finished_on:)
        @current_school_period.training_periods << @current_training_period if @current_training_period.present?
      end
    elsif @current_training_period.present? && not_withdrawn_or_deferred?
      state_changed_at = induction_record.end_date
      lead_provider_id = induction_record.training_provider_info&.lead_provider_info&.ecf1_id

      withdrawal_data = withdrawal_data(state_changed_at:, lead_provider_id:)
      deferral_data = deferral_data(state_changed_at:, lead_provider_id:)

      if withdrawal_data[:withdrawn_at].present?
        @current_training_period.withdrawn_at = withdrawal_data[:withdrawn_at]
        @current_training_period.withdrawal_reason = withdrawal_data[:withdrawal_reason]
      end

      if deferral_data[:deferred_at].present?
        @current_training_period.deferred_at = deferral_data[:deferred_at]
        @current_training_period.deferral_reason = deferral_data[:deferral_reason]
      end

      @current_training_period.finished_on = mentor_finished_on(
        start_date: started_on,
        end_date: finished_on,
        withdrawal_date: withdrawal_data[:withdrawn_at]&.to_date,
        deferral_date: deferral_data[:deferred_at]&.to_date,
        mentor_completion_date:
      )
    end
  end

  def build_training_period(induction_record, overrides = {})
    # do not add training periods after the mentor completion date
    return if mentor_completion_date.present? && induction_record.start_date > mentor_completion_date

    training_programme = convert_training_programme_name(induction_record.training_programme)
    return if training_programme != "provider_led"

    training_provider_info = induction_record.training_provider_info

    raise(StandardError, "No training provider info for #{induction_record.induction_record_id}") if training_provider_info.nil?

    state_changed_at = induction_record.end_date
    lead_provider_id = induction_record.training_provider_info.lead_provider_info&.ecf1_id
    withdrawal_data = withdrawal_data(state_changed_at:, lead_provider_id:)
    deferral_data = deferral_data(state_changed_at:, lead_provider_id:)

    if overrides[:finished_on].blank?
      overrides[:finished_on] = mentor_finished_on(
        start_date: induction_record.start_date,
        end_date: induction_record.end_date,
        withdrawal_date: withdrawal_data[:withdrawn_at]&.to_date,
        deferral_date: deferral_data[:deferred_at]&.to_date,
        mentor_completion_date:
      )
    end

    training_attrs = {
      started_on: induction_record.start_date,
      finished_on: induction_record.end_date,
      created_at: induction_record.created_at,
      school: induction_record.school,
      training_programme:,
      lead_provider_info: training_provider_info&.lead_provider_info,
      delivery_partner_info: training_provider_info&.delivery_partner_info,
      contract_period_year: training_provider_info&.cohort_year || induction_record.cohort_year,
      is_ect: false,
      ecf_start_induction_record_id: induction_record.induction_record_id,
      schedule_info: induction_record.schedule_info,
      api_transfer_updated_at: transfers[training_provider_info.lead_provider_info.ecf1_id],
      combination: build_combination(induction_record:, training_programme:),
      **withdrawal_data,
      **deferral_data
    }.merge(overrides)

    ECF2TeacherHistory::TrainingPeriod.new(**training_attrs)
  end

  def withdrawn_or_deferred?
    @current_training_period.withdrawn_at.present? || @current_training_period.deferred_at.present?
  end

  def not_withdrawn_or_deferred?
    !withdrawn_or_deferred?
  end

  def changes_training_period?(induction_record:)
    return true if @current_training_period.blank?

    return false if continuation_of_withdrawn_or_deferred_state?(induction_record:)

    return true if @current_training_period.withdrawn_at.present?
    return true if @current_training_period.deferred_at.present?

    @current_training_period.training_programme != convert_training_programme_name(induction_record.training_programme) ||
      @current_training_period&.lead_provider_info != induction_record&.training_provider_info&.lead_provider_info ||
      @current_training_period&.delivery_partner_info != induction_record&.training_provider_info&.delivery_partner_info ||
      @current_training_period.contract_period_year != induction_record&.training_provider_info&.cohort_year
  end

  def changes_school?(induction_record:)
    @current_school_period.nil? || @current_school_period.school != induction_record.school
  end

  # if the next induction record is the continuation of a withdrawn or deferred state for a LP/DP
  # then we should not create a new training_period
  def continuation_of_withdrawn_or_deferred_state?(induction_record:)
    return false if @current_training_period.blank?

    training_status = induction_record.training_status
    return false unless training_status.in? %(withdrawn deferred)

    return false if training_status == "withdrawn" && @current_training_period.withdrawn_at.blank?
    return false if training_status == "deferred" && @current_training_period.deferred_at.blank?

    return false if induction_record.training_provider_info&.lead_provider_info != @current_training_period.lead_provider_info

    induction_record.training_provider_info&.delivery_partner_info == @current_training_period.delivery_partner_info
  end

  def check_and_fix_all_overlaps(next_period_started_on)
    return if @current_school_period.blank?

    if next_period_started_on <= @current_school_period.started_on + 1.day
      # stub the school period and nested periods
      num_periods_needed = [1, @current_school_period.training_periods.count].compact.max

      # stub before 1st period (this might be the same as current_school_period)
      first_period = @school_periods.min_by(&:started_on)
      # need 2 days per period
      modified_started_on = first_period.started_on - (num_periods_needed * 2.days)
      modified_finished_on = first_period.started_on - 1.day

      @current_school_period.started_on = modified_started_on
      @current_school_period.finished_on = modified_finished_on
      @current_school_period.training_periods.each_with_index do |training_period, idx|
        training_period.started_on = modified_started_on + (idx * 2.days)
        training_period.finished_on = modified_started_on + 1.day + (idx * 2.days)
      end
    else
      check_and_fix_period_overlaps(@current_school_period, next_period_started_on)
      @current_school_period.training_periods.each { check_and_fix_period_overlaps(it, next_period_started_on) }
    end
  end

  def check_and_fix_period_overlaps(period, next_period_started_on)
    if period.finished_on.blank? || period.finished_on >= next_period_started_on
      period.finished_on = next_period_started_on - 1.day
    end
  end

  def build_combination(induction_record:, **overrides)
    ECF2TeacherHistory::Combination
      .from_induction_record(trn:, profile_id:, profile_type: "mentor", induction_record:, **overrides)
  end

  def ongoing_withdrawal_or_deferral?(induction_record:)
    induction_record.end_date.blank? && induction_record.training_status.in?(%w[withdrawn deferred])
  end

  def withdrawal_data(state_changed_at:, lead_provider_id:)
    TeacherHistoryConverter::PremiumWithdrawalData.new(state_changed_at:, states:, lead_provider_id:).withdrawal_data
  end

  def deferral_data(state_changed_at:, lead_provider_id:)
    TeacherHistoryConverter::PremiumDeferralData.new(state_changed_at:, states:, lead_provider_id:).deferral_data
  end
end
