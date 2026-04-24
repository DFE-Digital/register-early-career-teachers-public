RSpec.shared_examples "it is only valid two days after" do |base_date_proc|
  let(:base_date) { instance_exec(&base_date_proc) }

  context "when the date is before the period started" do
    let(:date) { base_date - 1.day }

    it { is_expected.not_to be_valid }
  end

  context "when the date is the same as the period started" do
    let(:date) { base_date  }

    it { is_expected.not_to be_valid }
  end

  context "when the date is one day after the period started" do
    let(:date) { base_date + 1.day }

    it { is_expected.not_to be_valid }
  end

  context "when the date is more than one day after the period started" do
    let(:date) { base_date + 2.days }

    it { is_expected.to be_valid }
  end
end

RSpec.shared_examples "all dates are valid" do |base_date_proc|
  let(:base_date) { instance_exec(&base_date_proc) }

  context "when the date is before the period started" do
    let(:date) { base_date - 1.day }

    it { is_expected.to be_valid }
  end

  context "when the date is the same as the period started" do
    let(:date) { base_date }

    it { is_expected.to be_valid }
  end

  context "when the date is after the period started" do
    let(:date) { base_date + 1.day }

    it { is_expected.to be_valid }
  end
end

RSpec.describe Schools::Validation::PeriodBoundary do
  subject { described_class.new(ect_at_school_period:, date:) }

  let(:date) { ect_at_school_period.started_on + 1.day }

  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: ect_at_school_period_started_on) }
  let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }

  around do |example|
    travel_to(Date.new(2025, 1, 1)) { example.run }
  end

  describe "#valid?" do
    context "when there is no date" do
      let(:date) { nil }

      it { is_expected.to be_valid }
    end

    context "when there is no ect_at_school_period" do
      let(:ect_at_school_period) { nil }
      let(:date) { Date.new(2024, 9, 1) }

      it { is_expected.to be_valid }
    end

    context "when there is an ect_at_school_period" do
      context "when there are no training periods" do
        it_behaves_like "it is only valid two days after", -> { ect_at_school_period.started_on }
      end

      context "when there is one training period" do
        let!(:training_period) do
          FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: training_period_started_on)
        end

        context "when the training period has the same start date as the ect at school period" do
          let(:training_period_started_on) { ect_at_school_period_started_on }

          context "when the periods started in the past" do
            let(:ect_at_school_period_started_on) { 1.day.ago }

            it_behaves_like "it is only valid two days after", -> { ect_at_school_period.started_on }
          end

          context "when the periods started today" do
            let(:ect_at_school_period_started_on) { Time.zone.today }

            it_behaves_like "it is only valid two days after", -> { ect_at_school_period.started_on }
          end

          context "when the periods start in the future" do
            let(:ect_at_school_period_started_on) { 1.day.from_now }

            it_behaves_like "it is only valid two days after", -> { ect_at_school_period.started_on }
          end
        end

        context "when the training period has a different start date to the ect at school period" do
          context "when the ect at school period started in the past" do
            let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }

            context "when the training period started in the past" do
              let(:training_period_started_on) { 1.day.ago }

              it_behaves_like "it is only valid two days after", -> { training_period_started_on }
            end

            context "when the training period started today" do
              let(:training_period_started_on) { Time.zone.today }

              it_behaves_like "it is only valid two days after", -> { training_period_started_on }
            end

            context "when the training period started in the future" do
              let(:training_period_started_on) { 1.day.from_now }

              it_behaves_like "all dates are valid", -> { training_period_started_on }
            end
          end

          context "when the ect at school period starts today" do
            # In this case the training period must start at least one day from now,
            # because it cannot start before the ECT period, or on the same day
            # In which case it does not affect the validations

            let(:ect_at_school_period_started_on) { Time.zone.today }

            context "when the training period starts one day from now" do
              let(:training_period_started_on) { 1.day.from_now }

              it_behaves_like "it is only valid two days after", -> { ect_at_school_period_started_on }
            end
          end

          context "when the ect at school period starts in the future" do
            # In this case the training period must start at least two days from now,
            # because it cannot start before the ECT period, or on the same day
            # In which case it does not affect the validations
            let(:ect_at_school_period_started_on) { 1.day.from_now }

            context "when the training period starts one day after the ect at school period" do
              let(:training_period_started_on) { 2.days.from_now }

              it_behaves_like "it is only valid two days after", -> { ect_at_school_period_started_on }
            end

            context "when the training period starts two days after the ect at school period" do
              let(:training_period_started_on) { 3.days.from_now }

              it_behaves_like "it is only valid two days after", -> { ect_at_school_period_started_on }
            end
          end
        end
      end

      context "when there are multiple training periods" do
        let!(:first_training_period) do
          FactoryBot.create(:training_period,
                            :ongoing,
                            ect_at_school_period:,
                            started_on: first_training_period_started_on,
                            finished_on: first_training_period_started_on + 1.day)
        end

        let!(:second_training_period) do
          FactoryBot.create(:training_period,
                            :ongoing,
                            ect_at_school_period:,
                            started_on: second_training_period_started_on)
        end

        let(:first_training_period_started_on) { Date.new(2024, 10, 1) }
        let(:second_training_period_started_on) { Date.new(2024, 12, 31) }

        context "the dates of the first training period do not affect the validation" do
          it_behaves_like "it is only valid two days after", -> { second_training_period_started_on }
        end
      end
    end
  end
end
