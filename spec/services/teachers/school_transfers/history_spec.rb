RSpec.describe Teachers::SchoolTransfers::History do
  describe "#transfers" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:teacher_type) { :ect }

    context "when a teacher leaves school-led training at one school " \
            "and joins no known training at another school" do
      let(:ect_at_school_period1) do
        FactoryBot.create(
          :ect_at_school_period,
          started_on: 3.years.ago,
          finished_on: 1.week.ago,
          teacher:
        )
      end
      let(:lead_provider1) { FactoryBot.create(:lead_provider) }
      let(:active_lead_provider1) do
        FactoryBot.create(:active_lead_provider, lead_provider: lead_provider1)
      end
      let(:lead_provider_delivery_partnership1) do
        FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider1
        )
      end
      let(:school_partnership1) do
        FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership1,
          school: ect_at_school_period1.school
        )
      end
      let!(:training_period1) do
        FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: ect_at_school_period1.started_on,
          finished_on: 2.years.ago,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )
      end
      let!(:training_period2) do
        FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: 2.years.ago,
          finished_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )
      end
      let!(:training_period3) do
        FactoryBot.create(
          :training_period,
          :school_led,
          started_on: 1.year.ago,
          finished_on: ect_at_school_period1.finished_on,
          ect_at_school_period: ect_at_school_period1
        )
      end

      it "returns no transfers for lead provider #1" do
        history = described_class.new(
          teacher:,
          lead_provider: lead_provider1,
          teacher_type:
        )

        expect(history.transfers).to be_empty
      end
    end

    context "when a teacher leaves provider-led training at one school " \
            "and joins no known training at another school" do
      it "returns no transfers for lead provider #1" do
        teacher = FactoryBot.create(:teacher)
        ect_at_school_period1 = FactoryBot.create(
          :ect_at_school_period,
          started_on: 3.years.ago,
          finished_on: 1.week.ago,
          teacher:
        )
        lead_provider1 = FactoryBot.create(:lead_provider)
        active_lead_provider1 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider1
        )
        lead_provider_delivery_partnership1 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider1
        )
        school_partnership1 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership1,
          school: ect_at_school_period1.school
        )
        _training_period1 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: ect_at_school_period1.started_on,
          finished_on: 2.years.ago,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )

        _training_period2 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: 2.years.ago,
          finished_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )

        lead_provider2 = FactoryBot.create(:lead_provider)
        active_lead_provider2 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider2
        )
        lead_provider_delivery_partnership2 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider2
        )
        school_partnership2 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership2,
          school: ect_at_school_period1.school
        )
        _training_period3 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: 1.year.ago,
          finished_on: ect_at_school_period1.finished_on,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership2
        )

        history = Teachers::SchoolTransfers::History.new(
          teacher:,
          lead_provider: lead_provider1,
          teacher_type: :ect
        )

        expect(history.transfers).to be_empty
      end

      it "returns an unknown transfer for lead provider #2" do
        teacher = FactoryBot.create(:teacher)
        ect_at_school_period1 = FactoryBot.create(
          :ect_at_school_period,
          started_on: 3.years.ago,
          finished_on: 1.week.ago,
          teacher:
        )
        lead_provider1 = FactoryBot.create(:lead_provider)
        active_lead_provider1 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider1
        )
        lead_provider_delivery_partnership1 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider1
        )
        school_partnership1 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership1,
          school: ect_at_school_period1.school
        )
        _training_period1 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: ect_at_school_period1.started_on,
          finished_on: 2.years.ago,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )

        _training_period2 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: 2.years.ago,
          finished_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )

        lead_provider2 = FactoryBot.create(:lead_provider)
        active_lead_provider2 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider2
        )
        lead_provider_delivery_partnership2 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider2
        )
        school_partnership2 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership2,
          school: ect_at_school_period1.school
        )
        training_period3 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: 1.year.ago,
          finished_on: ect_at_school_period1.finished_on,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership2
        )

        history = Teachers::SchoolTransfers::History.new(
          teacher:,
          lead_provider: lead_provider2,
          teacher_type: :ect
        )

        expect(history.transfers.size).to eq(1)
        transfer = history.transfers.first
        expect(transfer).to be_a(Teachers::SchoolTransfers::History::Transfer)
        expect(transfer.type).to eq(:unknown)
        expect(transfer.status).to eq(:complete)
        expect(transfer.teacher_type).to eq(:ect)
        expect(transfer.leaving_training_period).to eq(training_period3)
        expect(transfer.joining_training_period).to be_nil
      end
    end

    context "when a teacher leaves provider-led training at one school " \
            "and joins provider-led training at another school" \
            "with the same lead provider" do
      it "returns a new_school transfer for lead provider #1" do
        teacher = FactoryBot.create(:teacher)
        ect_at_school_period1 = FactoryBot.create(
          :ect_at_school_period,
          started_on: 3.years.ago,
          finished_on: 2.years.ago,
          teacher:
        )
        lead_provider1 = FactoryBot.create(:lead_provider)
        active_lead_provider1 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider1
        )
        lead_provider_delivery_partnership1 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider1
        )
        school_partnership1 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership1,
          school: ect_at_school_period1.school
        )
        training_period1 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: ect_at_school_period1.started_on,
          finished_on: 2.years.ago,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )

        ect_at_school_period2 = FactoryBot.create(
          :ect_at_school_period,
          :ongoing,
          started_on: 2.years.ago,
          teacher:
        )
        training_period2 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: 2.years.ago,
          finished_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period2,
          school_partnership: school_partnership1
        )

        lead_provider2 = FactoryBot.create(:lead_provider)
        active_lead_provider2 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider2
        )
        lead_provider_delivery_partnership2 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider2
        )
        school_partnership2 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership2,
          school: ect_at_school_period2.school
        )
        _training_period3 = FactoryBot.create(
          :training_period,
          :provider_led,
          :ongoing,
          started_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period2,
          school_partnership: school_partnership2
        )

        history = Teachers::SchoolTransfers::History.new(
          teacher:,
          lead_provider: lead_provider1,
          teacher_type: :ect
        )

        expect(history.transfers.size).to eq(1)
        transfer = history.transfers.first
        expect(transfer).to be_a(Teachers::SchoolTransfers::History::Transfer)
        expect(transfer.type).to eq(:new_school)
        expect(transfer.status).to eq(:complete)
        expect(transfer.teacher_type).to eq(:ect)
        expect(transfer.leaving_training_period).to eq(training_period1)
        expect(transfer.joining_training_period).to eq(training_period2)
      end

      it "returns no transfers for lead provider #2" do
        teacher = FactoryBot.create(:teacher)
        ect_at_school_period1 = FactoryBot.create(
          :ect_at_school_period,
          started_on: 3.years.ago,
          finished_on: 2.years.ago,
          teacher:
        )
        lead_provider1 = FactoryBot.create(:lead_provider)
        active_lead_provider1 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider1
        )
        lead_provider_delivery_partnership1 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider1
        )
        school_partnership1 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership1,
          school: ect_at_school_period1.school
        )
        _training_period1 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: ect_at_school_period1.started_on,
          finished_on: 2.years.ago,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )

        ect_at_school_period2 = FactoryBot.create(
          :ect_at_school_period,
          :ongoing,
          started_on: 2.years.ago,
          teacher:
        )
        _training_period2 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: 2.years.ago,
          finished_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period2,
          school_partnership: school_partnership1
        )

        lead_provider2 = FactoryBot.create(:lead_provider)
        active_lead_provider2 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider2
        )
        lead_provider_delivery_partnership2 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider2
        )
        school_partnership2 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership2,
          school: ect_at_school_period2.school
        )
        _training_period3 = FactoryBot.create(
          :training_period,
          :provider_led,
          :ongoing,
          started_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period2,
          school_partnership: school_partnership2
        )

        history = Teachers::SchoolTransfers::History.new(
          teacher:,
          lead_provider: lead_provider2,
          teacher_type: :ect
        )

        expect(history.transfers).to be_empty
      end
    end

    context "when a teacher leaves provider-led training at one school " \
            "and joins provider-led training at another school" \
            "with a different lead provider" do
      it "returns a new_provider transfer for lead provider #1" do
        teacher = FactoryBot.create(:teacher)
        ect_at_school_period1 = FactoryBot.create(
          :ect_at_school_period,
          started_on: 3.years.ago,
          finished_on: 2.years.ago,
          teacher:
        )
        lead_provider1 = FactoryBot.create(:lead_provider)
        active_lead_provider1 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider1
        )
        lead_provider_delivery_partnership1 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider1
        )
        school_partnership1 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership1,
          school: ect_at_school_period1.school
        )
        training_period1 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: ect_at_school_period1.started_on,
          finished_on: 2.years.ago,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )

        ect_at_school_period2 = FactoryBot.create(
          :ect_at_school_period,
          :ongoing,
          started_on: 2.years.ago,
          teacher:
        )
        lead_provider2 = FactoryBot.create(:lead_provider)
        active_lead_provider2 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider2
        )
        lead_provider_delivery_partnership2 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider2
        )
        school_partnership2 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership2,
          school: ect_at_school_period2.school
        )
        training_period2 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: 2.years.ago,
          finished_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period2,
          school_partnership: school_partnership2
        )

        lead_provider3 = FactoryBot.create(:lead_provider)
        active_lead_provider3 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider3
        )
        lead_provider_delivery_partnership3 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider3
        )
        school_partnership3 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership3,
          school: ect_at_school_period2.school
        )
        _training_period3 = FactoryBot.create(
          :training_period,
          :provider_led,
          :ongoing,
          started_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period2,
          school_partnership: school_partnership3
        )

        history = Teachers::SchoolTransfers::History.new(
          teacher:,
          lead_provider: lead_provider1,
          teacher_type: :ect
        )

        expect(history.transfers.size).to eq(1)
        transfer = history.transfers.first
        expect(transfer).to be_a(Teachers::SchoolTransfers::History::Transfer)
        expect(transfer.type).to eq(:new_provider)
        expect(transfer.status).to eq(:complete)
        expect(transfer.teacher_type).to eq(:ect)
        expect(transfer.leaving_training_period).to eq(training_period1)
        expect(transfer.joining_training_period).to eq(training_period2)
      end

      it "returns a new_provider transfer for lead provider #2" do
        teacher = FactoryBot.create(:teacher)
        ect_at_school_period1 = FactoryBot.create(
          :ect_at_school_period,
          started_on: 3.years.ago,
          finished_on: 2.years.ago,
          teacher:
        )
        lead_provider1 = FactoryBot.create(:lead_provider)
        active_lead_provider1 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider1
        )
        lead_provider_delivery_partnership1 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider1
        )
        school_partnership1 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership1,
          school: ect_at_school_period1.school
        )
        training_period1 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: ect_at_school_period1.started_on,
          finished_on: 2.years.ago,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )

        ect_at_school_period2 = FactoryBot.create(
          :ect_at_school_period,
          :ongoing,
          started_on: 2.years.ago,
          teacher:
        )
        lead_provider2 = FactoryBot.create(:lead_provider)
        active_lead_provider2 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider2
        )
        lead_provider_delivery_partnership2 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider2
        )
        school_partnership2 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership2,
          school: ect_at_school_period2.school
        )
        training_period2 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: 2.years.ago,
          finished_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period2,
          school_partnership: school_partnership2
        )

        lead_provider3 = FactoryBot.create(:lead_provider)
        active_lead_provider3 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider3
        )
        lead_provider_delivery_partnership3 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider3
        )
        school_partnership3 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership3,
          school: ect_at_school_period2.school
        )
        _training_period3 = FactoryBot.create(
          :training_period,
          :ongoing,
          :provider_led,
          started_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period2,
          school_partnership: school_partnership3
        )

        history = Teachers::SchoolTransfers::History.new(
          teacher:,
          lead_provider: lead_provider2,
          teacher_type: :ect
        )

        expect(history.transfers.size).to eq(1)
        transfer = history.transfers.first
        expect(transfer).to be_a(Teachers::SchoolTransfers::History::Transfer)
        expect(transfer.type).to eq(:new_provider)
        expect(transfer.status).to eq(:complete)
        expect(transfer.teacher_type).to eq(:ect)
        expect(transfer.leaving_training_period).to eq(training_period1)
        expect(transfer.joining_training_period).to eq(training_period2)
      end

      it "returns no transfers for lead provider #3" do
        teacher = FactoryBot.create(:teacher)
        ect_at_school_period1 = FactoryBot.create(
          :ect_at_school_period,
          started_on: 3.years.ago,
          finished_on: 2.years.ago,
          teacher:
        )
        lead_provider1 = FactoryBot.create(:lead_provider)
        active_lead_provider1 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider1
        )
        lead_provider_delivery_partnership1 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider1
        )
        school_partnership1 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership1,
          school: ect_at_school_period1.school
        )
        _training_period1 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: ect_at_school_period1.started_on,
          finished_on: 2.years.ago,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )

        ect_at_school_period2 = FactoryBot.create(
          :ect_at_school_period,
          :ongoing,
          started_on: 2.years.ago,
          teacher:
        )
        lead_provider2 = FactoryBot.create(:lead_provider)
        active_lead_provider2 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider2
        )
        lead_provider_delivery_partnership2 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider2
        )
        school_partnership2 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership2,
          school: ect_at_school_period2.school
        )
        _training_period2 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: 2.years.ago,
          finished_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period2,
          school_partnership: school_partnership2
        )

        lead_provider3 = FactoryBot.create(:lead_provider)
        active_lead_provider3 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider3
        )
        lead_provider_delivery_partnership3 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider3
        )
        school_partnership3 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership3,
          school: ect_at_school_period2.school
        )
        _training_period3 = FactoryBot.create(
          :training_period,
          :ongoing,
          :provider_led,
          started_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period2,
          school_partnership: school_partnership3
        )

        history = Teachers::SchoolTransfers::History.new(
          teacher:,
          lead_provider: lead_provider3,
          teacher_type: :ect
        )

        expect(history.transfers).to be_empty
      end
    end

    context "when a teacher leaves provider-led training at one school " \
            "and joins school-led training at another school" do
      it "returns a new_provider transfer for lead provider #1" do
        teacher = FactoryBot.create(:teacher)
        ect_at_school_period1 = FactoryBot.create(
          :ect_at_school_period,
          started_on: 3.years.ago,
          finished_on: 2.years.ago,
          teacher:
        )
        lead_provider1 = FactoryBot.create(:lead_provider)
        active_lead_provider1 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider1
        )
        lead_provider_delivery_partnership1 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider1
        )
        school_partnership1 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership1,
          school: ect_at_school_period1.school
        )
        training_period1 = FactoryBot.create(
          :training_period,
          :provider_led,
          started_on: ect_at_school_period1.started_on,
          finished_on: 2.years.ago,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )

        ect_at_school_period2 = FactoryBot.create(
          :ect_at_school_period,
          :ongoing,
          started_on: 2.years.ago,
          teacher:
        )
        training_period2 = FactoryBot.create(
          :training_period,
          :ongoing,
          :school_led,
          started_on: ect_at_school_period2.started_on,
          ect_at_school_period: ect_at_school_period2
        )

        history = Teachers::SchoolTransfers::History.new(
          teacher:,
          lead_provider: lead_provider1,
          teacher_type: :ect
        )

        expect(history.transfers.size).to eq(1)
        transfer = history.transfers.first
        expect(transfer).to be_a(Teachers::SchoolTransfers::History::Transfer)
        expect(transfer.type).to eq(:new_provider)
        expect(transfer.status).to eq(:complete)
        expect(transfer.teacher_type).to eq(:ect)
        expect(transfer.leaving_training_period).to eq(training_period1)
        expect(transfer.joining_training_period).to eq(training_period2)
      end
    end

    context "when a teacher leaves school-led training at one school " \
            "and joins provider-led training at another school" do
      it "returns a new_provider transfer for lead provider #1" do
        teacher = FactoryBot.create(:teacher)
        ect_at_school_period1 = FactoryBot.create(
          :ect_at_school_period,
          started_on: 3.years.ago,
          finished_on: 2.years.ago,
          teacher:
        )
        training_period1 = FactoryBot.create(
          :training_period,
          :school_led,
          started_on: ect_at_school_period1.started_on,
          finished_on: 2.years.ago,
          ect_at_school_period: ect_at_school_period1
        )

        ect_at_school_period2 = FactoryBot.create(
          :ect_at_school_period,
          :ongoing,
          started_on: 2.years.ago,
          teacher:
        )
        lead_provider1 = FactoryBot.create(:lead_provider)
        active_lead_provider1 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider1
        )
        lead_provider_delivery_partnership1 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider1
        )
        school_partnership1 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership1,
          school: ect_at_school_period2.school
        )
        training_period2 = FactoryBot.create(
          :training_period,
          :ongoing,
          :provider_led,
          started_on: ect_at_school_period2.started_on,
          ect_at_school_period: ect_at_school_period2,
          school_partnership: school_partnership1
        )

        history = Teachers::SchoolTransfers::History.new(
          teacher:,
          lead_provider: lead_provider1,
          teacher_type: :ect
        )

        expect(history.transfers.size).to eq(1)
        transfer = history.transfers.first
        expect(transfer).to be_a(Teachers::SchoolTransfers::History::Transfer)
        expect(transfer.type).to eq(:new_provider)
        expect(transfer.status).to eq(:complete)
        expect(transfer.teacher_type).to eq(:ect)
        expect(transfer.leaving_training_period).to eq(training_period1)
        expect(transfer.joining_training_period).to eq(training_period2)
      end
    end

    context "when a teacher leaves school-led training at one school " \
            "and joins school-led training at another school" do
      it "returns no transfers for lead provider #1" do
        teacher = FactoryBot.create(:teacher)
        ect_at_school_period1 = FactoryBot.create(
          :ect_at_school_period,
          started_on: 3.years.ago,
          finished_on: 2.years.ago,
          teacher:
        )
        _training_period1 = FactoryBot.create(
          :training_period,
          :school_led,
          started_on: ect_at_school_period1.started_on,
          finished_on: 2.years.ago,
          ect_at_school_period: ect_at_school_period1
        )

        ect_at_school_period2 = FactoryBot.create(
          :ect_at_school_period,
          :ongoing,
          started_on: 2.years.ago,
          teacher:
        )
        _training_period2 = FactoryBot.create(
          :training_period,
          :school_led,
          started_on: ect_at_school_period2.started_on,
          finished_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period2
        )
        lead_provider1 = FactoryBot.create(:lead_provider)
        active_lead_provider1 = FactoryBot.create(
          :active_lead_provider,
          lead_provider: lead_provider1
        )
        lead_provider_delivery_partnership1 = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider1
        )
        school_partnership1 = FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: lead_provider_delivery_partnership1,
          school: ect_at_school_period2.school
        )
        _training_period3 = FactoryBot.create(
          :training_period,
          :ongoing,
          :provider_led,
          started_on: 1.year.ago,
          ect_at_school_period: ect_at_school_period2,
          school_partnership: school_partnership1
        )

        history = Teachers::SchoolTransfers::History.new(
          teacher:,
          lead_provider: lead_provider1,
          teacher_type: :ect
        )

        expect(history.transfers).to be_empty
      end
    end
  end
end
