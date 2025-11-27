# rubocop:disable RSpec/InstanceVariable
RSpec.describe Teachers::SchoolTransfers::History do
  include SchoolTransferHelpers

  describe "#transfers" do
    let(:teacher) { FactoryBot.create(:teacher) }

    context "when there are no transfers" do
      let(:lead_provider) { FactoryBot.create(:lead_provider) }

      before do
        school_period1 = create_school_period(teacher, from: 2.years.ago)
        add_training_period(school_period1, from: 2.years.ago, programme_type: :provider_led, with: lead_provider)
      end

      it "returns no transfers" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider.id
        )

        expect(history.transfers).to be_empty
      end
    end

    context "when the teacher has no training periods" do
      let(:lead_provider) { FactoryBot.create(:lead_provider) }

      it "returns no transfers" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider.id
        )

        expect(history.transfers).to be_empty
      end
    end

    context "when a teacher leaves school-led training at one school and has " \
            "not yet started training at another school" do
      let(:lead_provider1) { FactoryBot.create(:lead_provider) }

      before do
        school_period1 = create_school_period(teacher, from: 3.years.ago, to: 1.week.ago)
        add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :provider_led, with: lead_provider1)
        add_training_period(school_period1, from: 2.years.ago, to: 1.year.ago, programme_type: :provider_led, with: lead_provider1)
        add_training_period(school_period1, from: 1.year.ago, to: 1.week.ago, programme_type: :school_led)
      end

      it "returns no transfers for lead provider #1" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider1.id
        )

        expect(history.transfers).to be_empty
      end
    end

    context "when a teacher leaves provider-led training at one school " \
            "but has not completed their training" do
      let(:lead_provider1) { FactoryBot.create(:lead_provider) }
      let(:lead_provider2) { FactoryBot.create(:lead_provider) }

      before do
        school_period1 = create_school_period(teacher, from: 3.years.ago, to: 1.week.ago)
        add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :provider_led, with: lead_provider1)
        add_training_period(school_period1, from: 2.years.ago, to: 1.year.ago, programme_type: :provider_led, with: lead_provider1)
        @training_period3 = add_training_period(school_period1, from: 1.year.ago, to: 1.week.ago, programme_type: :provider_led, with: lead_provider2)
      end

      it "returns no transfers for lead provider #1" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider1.id
        )

        expect(history.transfers).to be_empty
      end

      it "returns an unknown transfer for lead provider #2" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider2.id
        )

        expect(history.transfers.size).to eq(1)
        transfer = history.transfers.first
        expect(transfer).to be_a(Teachers::SchoolTransfers::Transfer)
        expect(transfer.type).to eq(:unknown)
        expect(transfer.status).to eq(:complete)
        expect(transfer).to be_for_ect
        expect(transfer).not_to be_for_mentor
        expect(transfer.leaving_training_period).to eq(@training_period3)
        expect(transfer.joining_training_period).to be_nil
      end
    end

    context "when a teacher leaves provider-led training at one school " \
            "and has completed their training" do
      let(:lead_provider1) { FactoryBot.create(:lead_provider) }
      let(:lead_provider2) { FactoryBot.create(:lead_provider) }

      before do
        school_period1 = create_school_period(teacher, from: 3.years.ago, to: 1.week.ago)
        add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :provider_led, with: lead_provider1)
        add_training_period(school_period1, from: 2.years.ago, to: 1.year.ago, programme_type: :provider_led, with: lead_provider1)
        @training_period3 = add_training_period(school_period1, from: 1.year.ago, to: 1.week.ago, programme_type: :provider_led, with: lead_provider2)
        record_completed_induction(teacher, school_period1)
      end

      it "returns no transfers for lead provider #1" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider1.id
        )

        expect(history.transfers).to be_empty
      end

      it "returns no transfers for lead provider #2" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider2.id
        )

        expect(history.transfers).to be_empty
      end
    end

    context "when a teacher leaves provider-led training at one school " \
            "and joins provider-led training at another school" \
            "with the same lead provider" do
      let(:lead_provider1) { FactoryBot.create(:lead_provider) }
      let(:lead_provider2) { FactoryBot.create(:lead_provider) }

      before do
        school_period1 = create_school_period(teacher, from: 3.years.ago, to: 2.years.ago)
        @training_period1 = add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :provider_led, with: lead_provider1)
        school_period2 = create_school_period(teacher, from: 2.years.ago)
        @training_period2 = add_training_period(school_period2, from: 2.years.ago, to: 1.year.ago, programme_type: :provider_led, with: lead_provider1)
        add_training_period(school_period2, from: 1.year.ago, programme_type: :provider_led, with: lead_provider2)
      end

      it "returns a new_school transfer for lead provider #1" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider1.id
        )

        expect(history.transfers.size).to eq(1)
        transfer = history.transfers.first
        expect(transfer).to be_a(Teachers::SchoolTransfers::Transfer)
        expect(transfer.type).to eq(:new_school)
        expect(transfer.status).to eq(:complete)
        expect(transfer).to be_for_ect
        expect(transfer).not_to be_for_mentor
        expect(transfer.leaving_training_period).to eq(@training_period1)
        expect(transfer.joining_training_period).to eq(@training_period2)
      end

      it "returns no transfers for lead provider #2" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider2.id
        )

        expect(history.transfers).to be_empty
      end
    end

    context "when a teacher leaves provider-led training at one school " \
            "and joins provider-led training at another school" \
            "with a different lead provider" do
      let(:lead_provider1) { FactoryBot.create(:lead_provider) }
      let(:lead_provider2) { FactoryBot.create(:lead_provider) }
      let(:lead_provider3) { FactoryBot.create(:lead_provider) }

      before do
        school_period1 = create_school_period(teacher, from: 3.years.ago, to: 2.years.ago)
        @training_period1 = add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :provider_led, with: lead_provider1)
        school_period2 = create_school_period(teacher, from: 2.years.ago)
        @training_period2 = add_training_period(school_period2, from: 2.years.ago, to: 1.year.ago, programme_type: :provider_led, with: lead_provider2)
        add_training_period(school_period2, from: 1.year.ago, programme_type: :provider_led, with: lead_provider3)
      end

      it "returns a new_provider transfer for lead provider #1" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider1.id
        )

        expect(history.transfers.size).to eq(1)
        transfer = history.transfers.first
        expect(transfer).to be_a(Teachers::SchoolTransfers::Transfer)
        expect(transfer.type).to eq(:new_provider)
        expect(transfer.status).to eq(:complete)
        expect(transfer).to be_for_ect
        expect(transfer).not_to be_for_mentor
        expect(transfer.leaving_training_period).to eq(@training_period1)
        expect(transfer.joining_training_period).to eq(@training_period2)
      end

      it "returns a new_provider transfer for lead provider #2" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider2.id
        )

        expect(history.transfers.size).to eq(1)
        transfer = history.transfers.first
        expect(transfer).to be_a(Teachers::SchoolTransfers::Transfer)
        expect(transfer.type).to eq(:new_provider)
        expect(transfer.status).to eq(:complete)
        expect(transfer).to be_for_ect
        expect(transfer).not_to be_for_mentor
        expect(transfer.leaving_training_period).to eq(@training_period1)
        expect(transfer.joining_training_period).to eq(@training_period2)
      end

      it "returns no transfers for lead provider #3" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider3.id
        )

        expect(history.transfers).to be_empty
      end
    end

    context "when a teacher leaves provider-led training at one school " \
            "and joins school-led training at another school" do
      let(:lead_provider1) { FactoryBot.create(:lead_provider) }

      before do
        school_period1 = create_school_period(teacher, from: 3.years.ago, to: 2.years.ago)
        @training_period1 = add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :provider_led, with: lead_provider1)
        school_period2 = create_school_period(teacher, from: 2.years.ago)
        @training_period2 = add_training_period(school_period2, from: 2.years.ago, programme_type: :school_led)
      end

      it "returns a new_provider transfer for lead provider #1" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider1.id
        )

        expect(history.transfers.size).to eq(1)
        transfer = history.transfers.first
        expect(transfer).to be_a(Teachers::SchoolTransfers::Transfer)
        expect(transfer.type).to eq(:new_provider)
        expect(transfer.status).to eq(:complete)
        expect(transfer).to be_for_ect
        expect(transfer).not_to be_for_mentor
        expect(transfer.leaving_training_period).to eq(@training_period1)
        expect(transfer.joining_training_period).to eq(@training_period2)
      end
    end

    context "when a teacher leaves school-led training at one school " \
            "and joins provider-led training at another school" do
      let(:lead_provider1) { FactoryBot.create(:lead_provider) }

      before do
        school_period1 = create_school_period(teacher, from: 3.years.ago, to: 2.years.ago)
        @training_period1 = add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :school_led)
        school_period2 = create_school_period(teacher, from: 2.years.ago)
        @training_period2 = add_training_period(school_period2, from: 2.years.ago, programme_type: :provider_led, with: lead_provider1)
      end

      it "returns a new_provider transfer for lead provider #1" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider1.id
        )

        expect(history.transfers.size).to eq(1)
        transfer = history.transfers.first
        expect(transfer).to be_a(Teachers::SchoolTransfers::Transfer)
        expect(transfer.type).to eq(:new_provider)
        expect(transfer.status).to eq(:complete)
        expect(transfer).to be_for_ect
        expect(transfer).not_to be_for_mentor
        expect(transfer.leaving_training_period).to eq(@training_period1)
        expect(transfer.joining_training_period).to eq(@training_period2)
      end
    end

    context "when a teacher leaves school-led training at one school " \
            "and joins school-led training at another school" do
      let(:lead_provider1) { FactoryBot.create(:lead_provider) }

      before do
        school_period1 = create_school_period(teacher, from: 3.years.ago, to: 2.years.ago)
        add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :school_led)
        school_period2 = create_school_period(teacher, from: 2.years.ago)
        add_training_period(school_period2, from: 2.years.ago, to: 1.year.ago, programme_type: :school_led)
        add_training_period(school_period2, from: 1.year.ago, programme_type: :provider_led, with: lead_provider1)
      end

      it "returns no transfers for lead provider #1" do
        history = described_class.new(
          school_periods: teacher.ect_at_school_periods,
          lead_provider_id: lead_provider1.id
        )

        expect(history.transfers).to be_empty
      end
    end
  end

private

  def record_completed_induction(teacher, school_period)
    FactoryBot.create(
      :induction_period,
      :pass,
      teacher:,
      started_on: school_period.started_on,
      finished_on: school_period.finished_on
    )
  end
end
# rubocop:enable RSpec/InstanceVariable
