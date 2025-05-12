class Teachers::InductionStatus
  attr_reader :teacher, :induction_periods, :trs_induction_status

  def initialize(teacher:, induction_periods:, trs_induction_status:)
    @teacher = teacher
    @induction_periods = induction_periods
    @trs_induction_status = trs_induction_status
  end

  def status_tag_kwargs
    case induction_info
    in { teacher_with_induction_periods_present: false, trs_induction_status: 'RequiredToComplete' }
      required_to_complete
    in { teacher_with_induction_periods_present: false, trs_induction_status: 'Exempt' }
      exempt
    in { has_an_open_induction_period: false, teacher_with_induction_periods_present: false, trs_induction_status: 'InProgress' }
      paused
    in { has_an_open_induction_period: true, teacher_with_induction_periods_present: false, trs_induction_status: 'InProgress' }
      in_progress
    in { teacher_with_induction_periods_present: false, trs_induction_status: 'Failed' }
      failed
    in { teacher_with_induction_periods_present: false, trs_induction_status: 'Passed' }
      passed
    in { teacher_with_induction_periods_present: false, trs_induction_status: 'FailedInWales' }
      failed_in_wales
    in { teacher_with_induction_periods_present: false, trs_induction_status: 'None' }
      none
    else
      unknown
    end
  end

  def induction_status = status_tag_kwargs.fetch(:text)
  def induction_status_colour = status_tag_kwargs.fetch(:colour)

  def completed?
    %w[
      Exempt
      Passed
      Failed
      FailedInWales
    ].include?(trs_induction_status)
  end

private

  def induction_info
    {
      has_an_open_induction_period: has_any_open_induction_periods?,
      has_an_induction_outcome: has_an_induction_outcome?,
      teacher_with_induction_periods_present: teacher.present? && induction_periods.present?,
      induction_outcome:,
      trs_induction_status:,
    }
  end

  def has_any_open_induction_periods?
    induction_periods&.any?(&:ongoing?)
  end

  def has_an_induction_outcome?
    induction_periods&.any? { |ip| ip.outcome.present? }
  end

  def induction_outcome
    return unless (period_with_outcome = induction_periods&.find { |ip| ip.outcome.present? })

    period_with_outcome.outcome
  end

  def exempt = { text: 'Exempt', colour: 'green' }
  def failed = { text: 'Failed', colour: 'red' }
  def failed_in_wales = { text: 'Failed in Wales', colour: 'red' }
  def in_progress = { text: 'In progress', colour: 'blue' }
  def none = { text: 'None', colour: 'grey' }
  def passed = { text: 'Passed', colour: 'green' }
  def paused = { text: 'Induction paused', colour: 'pink' }
  def required_to_complete = { text: 'Required to complete', colour: 'yellow' }
  def unknown = { text: 'Unknown', colour: 'grey' }
end
