class Teachers::InductionStatus
  attr_reader :teacher, :induction_periods, :trs_induction_status

  Status = Data.define(:name, :colour) do
    def to_h = { text: name, colour: }
  end

  def initialize(teacher:, induction_periods:, trs_induction_status:)
    @teacher = teacher
    @induction_periods = induction_periods
    @trs_induction_status = trs_induction_status
  end

  def status_tag_kwargs = determine_status.to_h
  def induction_status = determine_status.name
  def induction_status_colour = determine_status.colour

  def completed?
    trs_induction_status.in?(%w[Exempt Passed Failed FailedInWales])
  end

private

  def determine_status
    case induction_info
    in { trs_induction_status: 'RequiredToComplete' }
      required_to_complete
    in { trs_induction_status: 'Exempt' }
      exempt
    in { trs_induction_status: 'InProgress', has_an_open_induction_period: true }
      in_progress
    in { trs_induction_status: 'InProgress' }
      paused
    in { trs_induction_status: 'Failed' }
      failed
    in { trs_induction_status: 'Passed' }
      passed
    in { trs_induction_status: 'FailedInWales' }
      failed_in_wales
    in { trs_induction_status: 'None' }
      none
    else
      unknown
    end
  end

  def induction_info
    { trs_induction_status:, has_an_open_induction_period: }
  end

  def has_an_open_induction_period
    induction_periods&.any?(&:ongoing?)
  end

  def exempt = Status.new(name: 'Exempt', colour: 'green')
  def failed = Status.new(name: 'Failed', colour: 'red')
  def failed_in_wales = Status.new(name: 'Failed in Wales', colour: 'red')
  def in_progress = Status.new(name: 'In progress', colour: 'blue')
  def none = Status.new(name: 'None', colour: 'grey')
  def passed = Status.new(name: 'Passed', colour: 'green')
  def paused = Status.new(name: 'Induction paused', colour: 'pink')
  def required_to_complete = Status.new(name: 'Required to complete', colour: 'yellow')
  def unknown = Status.new(name: 'Unknown', colour: 'grey')
end
