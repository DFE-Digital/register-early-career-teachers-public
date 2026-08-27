# TRS status decorator.
# Optional teacher param overrides `InProgress` if no ongoing induction is found
class Induction::Status
  attr_reader :trs_induction_status,
              :teacher

  StatusColour = Data.define(:name, :colour) do
    def to_h = { text: name, colour: }
  end

  def initialize(trs_induction_status:, teacher: nil)
    @trs_induction_status = trs_induction_status
    @teacher = teacher
  end

  def status_tag_kwargs = determine_status.to_h
  def induction_status = determine_status.name
  def induction_status_colour = determine_status.colour

private

  def determine_status
    case induction_info
    in { trs_induction_status: "RequiredToComplete" }
      required_to_complete
    in { trs_induction_status: "Exempt" }
      exempt
    in { trs_induction_status: "InProgress", ongoing_induction_period: true }
      in_progress
    in { trs_induction_status: "InProgress", ongoing_induction_period: false }
      paused
    in { trs_induction_status: "Failed" }
      failed
    in { trs_induction_status: "Passed" }
      passed
    in { trs_induction_status: "FailedInWales" }
      failed_in_wales
    in { trs_induction_status: "None" }
      none
    else
      unknown
    end
  end

  def induction_info
    {
      trs_induction_status:,
      ongoing_induction_period: teacher&.ongoing_induction_period.present?
    }
  end

  def exempt = StatusColour.new(name: "Exempt", colour: "green")
  def failed = StatusColour.new(name: "Failed", colour: "red")
  def failed_in_wales = StatusColour.new(name: "Failed in Wales", colour: "red")
  def in_progress = StatusColour.new(name: "In progress", colour: "blue")
  def none = StatusColour.new(name: "None", colour: "grey")
  def passed = StatusColour.new(name: "Passed", colour: "green")
  def paused = StatusColour.new(name: "Induction paused", colour: "magenta")
  def required_to_complete = StatusColour.new(name: "Required to complete", colour: "yellow")
  def unknown = StatusColour.new(name: "Unknown", colour: "grey")
end
