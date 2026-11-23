RSpec.describe Teachers::TRN::ECTAtSchoolPeriods::Merge do
  subject(:service) do
    described_class.call(
      periods:,
      destination:
    )
  end

  let(:period_type) { :ect_at_school_period }
  let(:traits) { [] }

  include_context "a mergeable period"

  describe "#call" do
    it_behaves_like "it merges periods"
    it_behaves_like "it moves non-overlapping training_periods"
    it_behaves_like "it merges overlapping training periods"
    it_behaves_like "it moves non-overlapping mentorship_periods"

    context "when an overlapping training-period group includes a zero-length period" do
      let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: 2025, school:) }
      let(:schedule) { FactoryBot.create(:schedule, contract_period: school_partnership.contract_period) }

      let!(:source_training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          school_partnership:,
          schedule:,
          ect_at_school_period: source_period,
          started_on: first_period_started_on,
          finished_on: first_period_finished_on
        )
      end

      let!(:destination_training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          school_partnership:,
          schedule:,
          ect_at_school_period: destination_period,
          started_on: second_period_started_on,
          finished_on: second_period_finished_on
        )
      end

      let!(:zero_length_training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          school_partnership:,
          schedule:,
          ect_at_school_period: source_period,
          started_on: second_period_started_on,
          finished_on: second_period_started_on
        )
      end

      it "moves the zero-length period to the destination parent without merging it" do
        service

        expect(zero_length_training_period.reload.ect_at_school_period).to eq(destination_period)
        expect(zero_length_training_period.started_on).to eq(second_period_started_on)
        expect(zero_length_training_period.finished_on).to eq(second_period_started_on)
        expect(destination_training_period.reload).to be_persisted
      end
    end

    context "when there are overlapping mentorship periods" do
      let(:mentor) do
        FactoryBot.create(:mentor_at_school_period,
                          :unfinished,
                          school:,
                          started_on: first_period_started_on)
      end

      let!(:source_mentorship_period) do
        FactoryBot.create(:mentorship_period,
                          mentee: source_period,
                          mentor:,
                          started_on: first_period_started_on,
                          finished_on: first_period_finished_on)
      end

      let!(:destination_mentorship_period) do
        FactoryBot.create(:mentorship_period,
                          mentee: destination_period,
                          mentor:,
                          started_on: second_period_started_on,
                          finished_on: second_period_finished_on)
      end

      it "calls the Merge service for overlapping mentorship periods" do
        allow(Teachers::TRN::MentorshipPeriods::Overlapping).to receive(:find).and_call_original

        expect(Teachers::TRN::MentorshipPeriods::Merge).to receive(:call).with(
          periods: contain_exactly(source_mentorship_period, destination_mentorship_period),
          destination:
        )

        service

        expect(Teachers::TRN::MentorshipPeriods::Overlapping).to have_received(:find).with(
          periods: contain_exactly(source_mentorship_period, destination_mentorship_period)
        )
      end

      it "changes the start date of the second period" do
        expect { service }.to change(destination_period, :started_on).to(first_period_started_on)
      end

      it "changes the end date of the second period" do
        expect { service }.to change(destination_period, :finished_on).to(first_period_finished_on)
      end

      it "deletes the source_mentorship_period" do
        service

        expect(MentorshipPeriod.exists?(source_mentorship_period.id)).to be(false)
      end
    end
  end
end
