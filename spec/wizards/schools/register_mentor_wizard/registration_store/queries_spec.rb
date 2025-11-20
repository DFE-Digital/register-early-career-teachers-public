RSpec.describe Schools::RegisterMentorWizard::RegistrationStore::Queries do
  subject(:queries) { described_class.new(registration_store:) }

  let(:teacher) { FactoryBot.create(:teacher, trn:) }
  let(:trn) { "3002586" }
  let(:school) { FactoryBot.create(:school) }
  let(:store) { {} }
  let(:registration_store) do
    Struct.new(:trn, :school_urn, :lead_provider_id, :started_on, :start_date, :store)
          .new(trn, school_urn, lead_provider_id, started_on, start_date, store)
  end
  let(:school_urn) { school.urn }
  let(:lead_provider_id) { nil }
  let(:started_on) { nil }
  let(:start_date) { nil }

  describe "#active_record_at_school" do
    let!(:ongoing_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school:) }

    it "returns the ongoing mentor period for the school" do
      expect(queries.active_record_at_school).to eq(ongoing_period)
    end
  end

  describe "#school" do
    it "returns the school for the stored URN" do
      expect(queries.school).to eq(school)
    end

    context "when no school urn is stored" do
      let(:school_urn) { nil }

      it "returns nil" do
        expect(queries.school).to be_nil
      end
    end
  end

  describe "#lead_provider" do
    context "when a lead provider id has been stored" do
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:lead_provider_id) { lead_provider.id }

      it "returns the lead provider" do
        expect(queries.lead_provider).to eq(lead_provider)
      end
    end

    context "when no id has been stored" do
      let(:lead_provider_id) { nil }

      it "returns nil" do
        expect(queries.lead_provider).to be_nil
      end
    end
  end

  describe "#previous_training_period" do
    let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:) }
    let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:, started_on: Date.new(2025, 3, 1)) }

    it "returns the latest training period for the mentor" do
      expect(queries.previous_training_period).to eq(training_period)
    end
  end

  describe "#lead_providers_within_contract_period" do
    context "when no contract period is returned" do
      it "returns an empty array" do
        expect(queries.lead_providers_within_contract_period).to eq([])
      end
    end

    context "when a contract period is found" do
      let(:contract_period) { FactoryBot.create(:contract_period, year: 2026) }
      let(:started_on) { (contract_period.started_on + 1.day) }
      let!(:lead_provider) { FactoryBot.create(:lead_provider) }
      let!(:another_lead_provider) { FactoryBot.create(:lead_provider) }

      before do
        FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:)
        FactoryBot.create(:active_lead_provider, contract_period:, lead_provider: another_lead_provider)
      end

      it "returns the active lead providers for that period" do
        ids = queries.lead_providers_within_contract_period.map(&:id)

        expect(ids).to contain_exactly(lead_provider.id, another_lead_provider.id)
      end
    end
  end

  describe "#mentor_at_school_periods" do
    let!(:first_period) { FactoryBot.create(:mentor_at_school_period, teacher:) }
    let!(:second_period) { FactoryBot.create(:mentor_at_school_period, teacher:) }

    it "returns all mentor periods for the stored TRN" do
      expect(queries.mentor_at_school_periods).to contain_exactly(first_period, second_period)
    end
  end

  describe "#previous_school_mentor_at_school_periods" do
    let(:other_school) { FactoryBot.create(:school) }
    let!(:current_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school:) }
    let!(:finished_recently) do
      FactoryBot.create(:mentor_at_school_period,
                        teacher:,
                        school: other_school,
                        started_on: 2.years.ago,
                        finished_on: 6.months.ago)
    end
    let!(:ongoing_other_school) do
      FactoryBot.create(:mentor_at_school_period,
                        :ongoing,
                        teacher:,
                        school: other_school,
                        started_on: finished_recently.finished_on + 1.day)
    end
    let(:start_date) { 1.year.ago }

    it "returns mentor periods from other schools that are ongoing or recently finished" do
      expect(queries.previous_school_mentor_at_school_periods).to contain_exactly(ongoing_other_school, finished_recently)
    end
  end

  describe "#contract_period" do
    context "when started_on is supplied" do
      let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
      let(:started_on) { (contract_period.started_on + 3.days).to_s }

      it "returns the period containing the provided date" do
        expect(queries.contract_period).to eq(contract_period)
      end
    end
  end

  describe "#ect" do
    context "when an ect id is stored" do
      let(:ect) { FactoryBot.create(:ect_at_school_period) }
      let(:store) { { "ect_id" => ect.id } }

      it "returns the ECT at school period" do
        expect(queries.ect).to eq(ect)
      end
    end

    context "when no ect id is stored" do
      it "returns nil" do
        expect(queries.ect).to be_nil
      end
    end
  end

  describe "#ect_training_service" do
    let(:store) { { "ect_id" => ect.id } }
    let(:ect) { FactoryBot.create(:ect_at_school_period) }

    it "returns the instantiated training service" do
      service = queries.ect_training_service

      expect(service).to be_a(ECTAtSchoolPeriods::CurrentTraining)
      expect(service.ect_at_school_period).to eq(ect)
    end
  end
end
