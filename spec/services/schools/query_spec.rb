RSpec.describe Schools::Query do
  describe "#schools" do
    subject(:query) { described_class.new(**query_params) }

    let(:query_params) do
      {
        contract_period_year:,
      }
    end

    context "when no params is sent" do
      it "returns no schools" do
        expect(described_class.new.schools).to be_empty
      end
    end

    it "returns all eligible schools" do
      school = FactoryBot.create(:school, :eligible)
      contract_period_year = FactoryBot.create(:contract_period).id

      expect(described_class.new(contract_period_year:).schools).to eq([school])
    end

    context "when there is existing partnerships" do
      let(:school1) { FactoryBot.create(:school, :eligible) }
      let(:school2) { FactoryBot.create(:school, :ineligible) }
      let!(:school1_partnership) { FactoryBot.create(:school_partnership, school: school1) }
      let!(:school2_partnership) { FactoryBot.create(:school_partnership, school: school2, lead_provider_delivery_partnership: school1_partnership.lead_provider_delivery_partnership) }
      let(:contract_period_year) { school1_partnership.contract_period.id }

      it "returns all schools" do
        expect(described_class.new(contract_period_year:).schools).to contain_exactly(school1, school2)
      end
    end

    it "orders schools by `created_at` date in ascending order" do
      school1 = FactoryBot.create(:school, :eligible, created_at: 2.days.ago)
      school2 = FactoryBot.create(:school, :eligible, created_at: 1.day.ago)
      school3 = FactoryBot.create(:school, :eligible, created_at: Time.zone.now)
      contract_period_year = FactoryBot.create(:contract_period).id

      expect(described_class.new(contract_period_year:).schools).to contain_exactly(school1, school2, school3)
    end

    describe "filtering" do
      describe "by `contract_period_year`" do
        let!(:school1) { FactoryBot.create(:school, :eligible) }
        let!(:school2) { FactoryBot.create(:school) }
        let!(:school3) { FactoryBot.create(:school) }

        let(:another_contract_period) { FactoryBot.create(:contract_period) }
        let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period: another_contract_period) }
        let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
        let!(:school_partnership) { FactoryBot.create(:school_partnership, school: school3, lead_provider_delivery_partnership:) }
        let(:contract_period_year) { another_contract_period.id }

        let(:query_params) do
          {
            contract_period_year:,
          }
        end

        it "filters by `contract_period_year`" do
          expect(query.schools).to contain_exactly(school1, school3)
        end

        context "when `contract_period_year` param is omitted" do
          it "returns no schools" do
            expect(described_class.new.schools).to be_empty
          end
        end

        context "when no `contract_period_year` is found" do
          let!(:contract_period_year) { "0000" }

          it "returns no schools" do
            expect(query.schools).to be_empty
          end
        end

        context "when `contract_period_year` param is blank" do
          let!(:contract_period_year) { " " }

          it "returns no schools" do
            expect(query.schools).to be_empty
          end
        end

        context "when the schools has metadata" do
          let!(:school1) { FactoryBot.create(:school, :eligible, :with_metadata, contract_period: another_contract_period, lead_provider: active_lead_provider.lead_provider) }

          before do
            ignored_contract_period = FactoryBot.create(:contract_period, year: another_contract_period.year + 1)
            FactoryBot.create(:school_contract_period_metadata, school: school1, contract_period: ignored_contract_period)
            FactoryBot.create(:school_lead_provider_contract_period_metadata, school: school1, contract_period: ignored_contract_period)
          end

          it "returns schools with only the applicable metadata" do
            school = query.school_by_id(school1.id)

            expected_contract_period_metadata = school.contract_period_metadata.find { |m| m.contract_period_year == contract_period_year }
            expect(school.contract_period_metadata).to contain_exactly(expected_contract_period_metadata)

            expected_lead_provider_contract_period_metadata = school.lead_provider_contract_period_metadata.find { |m| m.lead_provider_id == active_lead_provider.lead_provider_id }
            expect(school.lead_provider_contract_period_metadata).to contain_exactly(expected_lead_provider_contract_period_metadata)
          end
        end
      end

      describe "by `lead_provider_id`" do
        let!(:school1) { FactoryBot.create(:school, :eligible) }
        let!(:school2) { FactoryBot.create(:school) }
        let!(:school3) { FactoryBot.create(:school) }

        let(:another_contract_period) { FactoryBot.create(:contract_period) }
        let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period: another_contract_period) }
        let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
        let!(:school_partnership) { FactoryBot.create(:school_partnership, school: school3, lead_provider_delivery_partnership:) }
        let(:contract_period_year) { another_contract_period.id }
        let(:lead_provider) { active_lead_provider.lead_provider }

        let(:query_params) do
          {
            contract_period_year:,
            lead_provider_id: active_lead_provider.lead_provider_id,
          }
        end

        context "when the schools has metadata" do
          let!(:school3) { FactoryBot.create(:school, :eligible, :with_metadata, contract_period: another_contract_period, lead_provider:) }

          before do
            ignored_lead_provider = FactoryBot.create(:lead_provider)
            FactoryBot.create(:school_lead_provider_contract_period_metadata, school: school2, contract_period_year:, lead_provider: ignored_lead_provider)
          end

          it "returns schools with only the applicable metadata" do
            school = query.school_by_id(school3.id)
            expected_lead_provider_contract_period_metadata = school.lead_provider_contract_period_metadata.find { |m| m.lead_provider_id == lead_provider.id }
            expect(school.lead_provider_contract_period_metadata).to contain_exactly(expected_lead_provider_contract_period_metadata)
          end
        end
      end

      describe "by `updated_since`" do
        let!(:school1) { FactoryBot.create(:school, :eligible, updated_at: 2.days.ago) }
        let!(:school2) { FactoryBot.create(:school, :eligible, updated_at: 10.minutes.ago) }

        let!(:training_period) { FactoryBot.create(:training_period, :ongoing, :for_ect) }
        let!(:school3) { training_period.school_partnership.school }

        let(:contract_period_year) { training_period.contract_period.id }

        let(:updated_since) { 1.day.ago }

        let(:query_params) do
          {
            contract_period_year:,
            updated_since:
          }
        end

        it "filters by `updated_since`" do
          expect(query.schools).to contain_exactly(school2, school3)
        end

        context "when `updated_since` param is omitted" do
          let(:query_params) do
            {
              contract_period_year:,
            }
          end

          it "returns all eligible schools" do
            expect(query.schools).to contain_exactly(school1, school2, school3)
          end
        end

        context "when `contract_period_year` param is blank" do
          let!(:updated_since) { " " }

          it "returns all eligible schools" do
            expect(query.schools).to contain_exactly(school1, school2, school3)
          end
        end
      end

      describe "by `urn`" do
        let!(:school1) { FactoryBot.create(:school, :eligible, urn: "1234567") }
        let!(:school2) { FactoryBot.create(:school, :eligible, urn: "4567890") }
        let(:contract_period_year) { FactoryBot.create(:contract_period).id }
        let!(:urn) { school1.urn }

        let(:query_params) do
          {
            contract_period_year:,
            urn:,
          }
        end

        it "filters by `urn`" do
          expect(query.schools).to contain_exactly(school1)
        end

        context "when `urn` param is omitted" do
          let(:query_params) do
            {
              contract_period_year:,
            }
          end

          it "returns all eligible schools" do
            expect(query.schools).to contain_exactly(school1, school2)
          end
        end

        context "when `urn` param is blank" do
          let!(:urn) { " " }

          it "returns all eligible schools" do
            expect(query.schools).to contain_exactly(school1, school2)
          end
        end
      end
    end

    describe "sorting" do
      subject(:schools) { described_class.new(**query_params).schools }

      let(:school1) { FactoryBot.create(:school, :eligible, created_at: 1.day.ago) }
      let(:school2) { FactoryBot.create(:school, :eligible, created_at: 2.days.ago) }
      let(:school3) { FactoryBot.create(:school, :eligible, created_at: Time.zone.now) }

      let(:contract_period_year) { FactoryBot.create(:contract_period).id }

      let(:sort) { nil }

      let(:query_params) do
        {
          contract_period_year:,
          sort:,
        }
      end

      it { is_expected.to eq([school2, school1, school3]) }

      context "when sorting by created at, descending" do
        let(:sort) { "-created_at" }

        it { is_expected.to eq([school3, school1, school2]) }
      end

      context "when sorting by updated at, ascending" do
        let(:sort) { "+updated_at" }

        before do
          school1.update!(updated_at: 1.day.from_now)
          school2.update!(updated_at: 2.days.from_now)
        end

        it { is_expected.to eq([school3, school1, school2]) }
      end

      context "when sorting by multiple attributes" do
        let(:sort) { "+updated_at,-created_at" }

        before do
          school1.update!(updated_at: 1.day.from_now)
          school2.update!(updated_at: school1.updated_at)
          school3.update!(updated_at: 2.days.from_now)

          school2.update!(created_at: 1.day.from_now)
          school1.update!(created_at: 1.day.ago)
        end

        it { expect(schools).to eq([school2, school1, school3]) }
      end
    end
  end

  describe "#school_by_api_id" do
    subject(:query) { described_class.new(**query_params) }

    let(:contract_period) { FactoryBot.create(:contract_period) }
    let(:query_params) do
      {
        contract_period_year: contract_period.id,
      }
    end

    let(:school) { FactoryBot.create(:school, :eligible) }

    it "returns a school for the given school api_id" do
      expect(query.school_by_api_id(school.api_id)).to eq(school)
    end

    it "raises an error if the school does not exist" do
      expect { query.school_by_api_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an api_id is not supplied" do
      expect { query.school_by_api_id(nil) }.to raise_error(ArgumentError, "api_id needed")
    end
  end

  describe "#school_by_id" do
    subject(:query) { described_class.new(**query_params) }

    let(:contract_period) { FactoryBot.create(:contract_period) }
    let(:query_params) do
      {
        contract_period_year: contract_period.id,
      }
    end

    let(:school) { FactoryBot.create(:school, :eligible) }

    it "returns a school for the given school id" do
      expect(query.school_by_id(school.id)).to eq(school)
    end

    it "raises an error if the school does not exist" do
      expect { query.school_by_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an id is not supplied" do
      expect { query.school_by_id(nil) }.to raise_error(ArgumentError, "id needed")
    end
  end
end
