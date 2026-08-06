# Shared response shape for the v4 claim / close endpoints — the induction
# period in its current state.
class API::V4::InductionPeriodSerializer < Blueprinter::Base
  field(:trn) { |induction_period| induction_period.teacher.trn }
  field(:full_name) { |induction_period| ::Teachers::Name.new(induction_period.teacher).full_name }

  # ongoing | pass | fail | release (released = finished with no pass/fail outcome)
  field(:status) do |induction_period|
    if induction_period.finished_on.nil?
      "ongoing"
    else
      induction_period.outcome.presence || "release"
    end
  end

  field(:started_on)
  field(:finished_on)
  field(:training_programme)
  field(:number_of_terms)

  field(:created_at)
  field(:updated_at)
end
