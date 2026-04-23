RSpec.shared_examples "it is only valid two days after" do
  context "when the date is before the period started" do
    let(:input_date) { base_date - 1.day }

    it { is_expected.not_to be_valid }
  end

  context "when the date is the same as the period started" do
    let(:input_date) { base_date }

    it { is_expected.not_to be_valid }
  end

  context "when the date is one day after the period started" do
    let(:input_date) { base_date + 1.day }

    it { is_expected.not_to be_valid }
  end

  context "when the date is more than one day after the period started" do
    let(:input_date) { base_date + 2.days }

    it { is_expected.to be_valid }
  end
end

RSpec.shared_examples "all dates are valid" do
  context "when the date is before the period started" do
    let(:input_date) { base_date - 1.day }

    it { is_expected.to be_valid }
  end

  context "when the date is the same as the period started" do
    let(:input_date) { base_date }

    it { is_expected.to be_valid }
  end

  context "when the date is after the period started" do
    let(:input_date) { base_date + 1.day }

    it { is_expected.to be_valid }
  end
end

RSpec.shared_examples "it clashes with the training period if the date is around" do
  context "when the date entered is before the training period started" do
    let(:input_date) { base_date - 1.day }

    it { is_expected.to eq(training_period) }
  end

  context "when the date entered is the same as the training period started" do
    let(:input_date) { base_date }

    it { is_expected.to eq(training_period) }
  end

  context "when the date entered is one day after the training period started" do
    let(:input_date) { base_date + 1.day }

    it { is_expected.to eq(training_period) }
  end

  context "when the date entered is more than one day after the training period started" do
    let(:input_date) { base_date + 2.days }

    it { is_expected.to be_nil }
  end
end

RSpec.shared_examples "it clashes with the ect at school period if the date is around" do
  context "when the date entered is before the ect at school period started" do
    let(:input_date) { base_date - 1.day }

    it { is_expected.to eq(ect_at_school_period) }
  end

  context "when the date entered is the same as the ect at school period started" do
    let(:input_date) { base_date }

    it { is_expected.to eq(ect_at_school_period) }
  end

  context "when the date entered is one day after the ect at school period started" do
    let(:input_date) { base_date + 1.day }

    it { is_expected.to eq(ect_at_school_period) }
  end

  context "when the date entered is more than one day after the ect at school period started" do
    let(:input_date) { base_date + 2.days }

    it { is_expected.to be_nil }
  end
end

RSpec.shared_examples "it does not clash with either period" do
  context "when the date entered is before the training period started" do
    let(:input_date) { base_date - 1.day }

    it { is_expected.to be_nil }
  end

  context "when the date entered is the same as the training period started" do
    let(:input_date) { base_date }

    it { is_expected.to be_nil }
  end

  context "when the date entered is one day after the training period started" do
    let(:input_date) { base_date + 1.day }

    it { is_expected.to be_nil }
  end
end

RSpec.describe Schools::Validation::PeriodBoundary do
  subject { described_class.new(ect_at_school_period:, input_date:) }

  let(:input_date) { ect_at_school_period.started_on + 1.day }

  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: ect_at_school_period_started_on) }
  let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }

  around do |example|
    travel_to(Date.new(2025, 1, 1)) { example.run }
  end

  describe "#valid?" do
    context "when there is no date" do
      let(:input_date) { nil }

      it { is_expected.to be_valid }
    end

    context "when there is no ect_at_school_period" do
      let(:ect_at_school_period) { nil }
      let(:input_date) { Date.new(2024, 9, 1) }

      it { is_expected.to be_valid }
    end

    context "when there is an ect_at_school_period" do
      context "when there are no training periods" do
        let(:base_date) { ect_at_school_period.started_on }

        it_behaves_like "it is only valid two days after"
      end

      context "when there is one training period" do
        let!(:training_period) do
          FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: training_period_started_on)
        end

        context "when the training period has the same start date as the ect at school period" do
          let(:training_period_started_on) { ect_at_school_period_started_on }

          context "when the periods started in the past" do
            let(:ect_at_school_period_started_on) { 1.day.ago }
            let(:base_date) { ect_at_school_period.started_on }

            it_behaves_like "it is only valid two days after"
          end

          context "when the periods started today" do
            let(:ect_at_school_period_started_on) { Time.zone.today }
            let(:base_date) { ect_at_school_period.started_on }

            it_behaves_like "it is only valid two days after"
          end

          context "when the periods start in the future" do
            let(:ect_at_school_period_started_on) { 1.day.from_now }
            let(:base_date) { ect_at_school_period.started_on }

            it_behaves_like "it is only valid two days after"
          end
        end

        context "when the training period has a different start date to the ect at school period" do
          context "when the ect at school period started in the past" do
            let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }

            context "when the training period started in the past" do
              let(:training_period_started_on) { 1.day.ago }
              let(:base_date) { training_period.started_on }

              it_behaves_like "it is only valid two days after"
            end

            context "when the training period started today" do
              let(:training_period_started_on) { Time.zone.today }
              let(:base_date) { training_period.started_on }

              it_behaves_like "it is only valid two days after"
            end

            context "when the training period started in the future" do
              let(:training_period_started_on) { 1.day.from_now }
              let(:base_date) { training_period.started_on }

              it_behaves_like "all dates are valid"
            end
          end

          context "when the ect at school period starts today" do
            # In this case the training period must start at least one day from now,
            # because it cannot start before the ECT period, or on the same day
            # In which case it does not affect the validations

            let(:ect_at_school_period_started_on) { Time.zone.today }

            context "when the training period starts one day from now" do
              let(:training_period_started_on) { 1.day.from_now }
              let(:base_date) { ect_at_school_period.started_on }

              it_behaves_like "it is only valid two days after"
            end
          end

          context "when the ect at school period starts in the future" do
            # In this case the training period must start at least two days from now,
            # because it cannot start before the ECT period, or on the same day
            # In which case it does not affect the validations
            let(:ect_at_school_period_started_on) { 1.day.from_now }

            context "when the training period starts one day after the ect at school period" do
              let(:training_period_started_on) { 2.days.from_now }
              let(:base_date) { ect_at_school_period.started_on }

              it_behaves_like "it is only valid two days after"
            end

            context "when the training period starts two days after the ect at school period" do
              let(:training_period_started_on) { 3.days.from_now }
              let(:base_date) { ect_at_school_period.started_on }

              it_behaves_like "it is only valid two days after"
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
          let(:base_date) { second_training_period.started_on }

          it_behaves_like "it is only valid two days after"
        end
      end
    end
  end

  describe "#invalid_period" do
    subject { described_class.new(ect_at_school_period:, input_date:).invalid_period }

    context "when there is no date" do
      let(:input_date) { nil }

      it { is_expected.to be_nil }
    end

    context "when there is no ect_at_school_period" do
      let(:ect_at_school_period) { nil }
      let(:input_date) { Date.new(2024, 9, 1) }

      it { is_expected.to be_nil }
    end

    context "when there is an ect_at_school_period" do
      let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }

      context "when there are no training periods" do
        let(:base_date) { Date.new(2024, 9, 1) }

        it_behaves_like "it clashes with the ect at school period if the date is around"
      end
    end

    context "when there is one training period" do
      let!(:training_period) do
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: training_period_started_on)
      end

      context "when the training period has the same start date as the ect at school period" do
        let(:training_period_started_on) { ect_at_school_period_started_on }

        context "when the periods started in the past" do
          let(:ect_at_school_period_started_on) { 1.day.ago }
          let(:base_date) { 1.day.ago }

          it_behaves_like "it clashes with the ect at school period if the date is around"
        end

        context "when the periods started today" do
          let(:ect_at_school_period_started_on) { Time.zone.today }
          let(:base_date) { Time.zone.today }

          it_behaves_like "it clashes with the ect at school period if the date is around"
        end

        context "when the periods start in the future" do
          let(:ect_at_school_period_started_on) { 1.day.from_now }
          let(:base_date) { 1.day.from_now }

          it_behaves_like "it clashes with the ect at school period if the date is around"
        end
      end

      context "when the training period has a different start date to the ect at school period" do
        let(:input_date) { Time.zone.today }

        context "when the ect at school period started in the past" do
          let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }

          context "when the training period started in the past" do
            let(:training_period_started_on) { 1.day.ago }
            let(:base_date) { 1.day.ago }

            it_behaves_like "it clashes with the training period if the date is around"
          end

          context "when the training period started today" do
            let(:training_period_started_on) { Time.zone.today }
            let(:base_date) { Time.zone.today }

            it_behaves_like "it clashes with the training period if the date is around"
          end

          context "when the training period started in the future" do
            let(:training_period_started_on) { 1.day.from_now }
            let(:base_date) { 1.day.from_now }

            it_behaves_like "it does not clash with either period"
          end
        end

        context "when the ect at school period starts today" do
          # In this case the training period must start at least one day from now,
          # because it cannot start before the ECT period, or on the same day
          # In which case it does not affect the validations

          let(:ect_at_school_period_started_on) { Time.zone.today }

          context "when the training period starts one day from now" do
            let(:training_period_started_on) { 1.day.from_now }
            let(:base_date) { Time.zone.today }

            it_behaves_like "it clashes with the ect at school period if the date is around"
          end
        end

        context "when the ect at school period starts in the future" do
          # In this case the training period must start at least two days from now,
          # because it cannot start before the ECT period, or on the same day
          # In which case it does not affect the validations
          let(:ect_at_school_period_started_on) { 1.day.from_now }

          context "when the training period starts one day after the ect at school period" do
            let(:training_period_started_on) { 2.days.from_now }
            let(:base_date) { 1.day.from_now }

            it_behaves_like "it clashes with the ect at school period if the date is around"
          end

          context "when the training period starts two days after the ect at school period" do
            let(:training_period_started_on) { 3.days.from_now }
            let(:base_date) { 1.day.from_now }

            it_behaves_like "it clashes with the ect at school period if the date is around"
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
      let(:second_training_period_started_on) { 1.day.ago }

      context "the dates of the first training period do not affect the validation" do
        let(:training_period) { second_training_period }
        let(:base_date) { 1.day.ago }

        it_behaves_like "it clashes with the training period if the date is around"
      end
    end
  end

  describe "#type" do
    subject { described_class.new(ect_at_school_period:, input_date:).type }

    context "when the invalid period is an ECT at school period" do
      let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }
      let(:input_date) { Date.new(2024, 8, 1) }

      it { is_expected.to eq("teaching") }
    end

    context "when the invalid period is a training period" do
      let!(:training_period) do
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: training_period_started_on)
      end

      let(:training_period_started_on) { Date.new(2024, 10, 1) }
      let(:input_date) { Date.new(2024, 9, 30) }

      it { is_expected.to eq("their latest training") }
    end

    context "when the date is before the start of both periods" do
      let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }
      let!(:training_period) do
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: Date.new(2024, 10, 1))
      end
      let(:input_date) { Date.new(2024, 8, 1) }

      it { is_expected.to eq("teaching") }
    end
  end

  describe "#started_on_formatted" do
    subject { described_class.new(ect_at_school_period:, input_date:).started_on_formatted }

    context "when the invalid period is an ECT at school period" do
      let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }
      let(:input_date) { Date.new(2024, 8, 1) }

      it { is_expected.to eq("1 September 2024") }
    end

    context "when the invalid period is a training period" do
      let!(:training_period) do
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: training_period_started_on)
      end

      let(:training_period_started_on) { Date.new(2024, 10, 1) }
      let(:input_date) { Date.new(2024, 9, 30) }

      it { is_expected.to eq("1 October 2024") }
    end

    context "when the date is before the start of both periods" do
      let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }
      let!(:training_period) do
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: Date.new(2024, 10, 1))
      end

      let(:input_date) { Date.new(2024, 8, 1) }

      it "returns the start date of the ect at school period" do
        expect(subject).to eq("1 September 2024")
      end
    end

    context "when there are no invalid periods" do
      let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }
      let!(:training_period) do
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: Date.new(2024, 10, 1))
      end
      let(:input_date) { Date.new(2024, 11, 1) }

      it { is_expected.to be_nil }
    end
  end

  describe "#earliest_valid_input_date_formatted" do
    subject { described_class.new(ect_at_school_period:, input_date:).earliest_valid_input_date_formatted }

    context "when the invalid period is an ECT at school period" do
      let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }
      let(:input_date) { Date.new(2024, 8, 1) }

      it { is_expected.to eq("2 September 2024") }
    end

    context "when the invalid period is a training period" do
      let!(:training_period) do
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: training_period_started_on)
      end

      let(:training_period_started_on) { Date.new(2024, 10, 1) }
      let(:input_date) { Date.new(2024, 9, 30) }

      it { is_expected.to eq("2 October 2024") }
    end

    context "when the date is before the start of both periods" do
      let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }
      let!(:training_period) do
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: Date.new(2024, 10, 1))
      end

      let(:input_date) { Date.new(2024, 8, 1) }

      it "returns the earliest valid date based on the training period" do
        expect(subject).to eq("2 September 2024")
      end
    end

    context "when there are no invalid periods" do
      let(:ect_at_school_period_started_on) { Date.new(2024, 9, 1) }
      let!(:training_period) do
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: Date.new(2024, 10, 1))
      end
      let(:input_date) { Date.new(2024, 11, 1) }

      it { is_expected.to be_nil }
    end
  end
end
