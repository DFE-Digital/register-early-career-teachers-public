class ControllerWithFilterByRegistrationPeriod
  include API::FilterByRegistrationPeriod

  public :registration_period_start_years

  def initialize(registration_period_param:)
    @registration_period_param = registration_period_param
  end

private

  def params
    {
      filter: {
        cohort: @registration_period_param,
      },
    }
  end
end

RSpec.describe API::FilterByRegistrationPeriod do
  let(:expected_registration_period_start_years) { "2022,2025" }

  let(:registration_period_param) { "2022,2025" }

  let(:instance) { ControllerWithFilterByRegistrationPeriod.new(registration_period_param:) }

  describe "#registration_period_start_years" do
    subject { instance.registration_period_start_years }

    it { is_expected.to eq(expected_registration_period_start_years) }

    context "when the registration_period filter is not present" do
      let(:registration_period_param) { nil }

      it { is_expected.to be_nil }
    end
  end
end
