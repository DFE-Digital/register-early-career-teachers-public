RSpec.describe Schools::Query do
  describe "#schools" do
    subject(:query) { described_class.new(**query_params) }

    let(:query_params) do
      {
        contract_period_id:,
      }
    end

    context "when no params is sent" do
      it "returns no schools" do
        expect(described_class.new.schools).to be_empty
      end
    end

    it "returns all eligible schools" do
      school = FactoryBot.create(:school, :eligible)
      contract_period_id = FactoryBot.create(:contract_period).id

      expect(described_class.new(contract_period_id:).schools).to eq([school])
    end

    context "when there is existing partnerships" do
      let(:school1) { FactoryBot.create(:school, :eligible) }
      let(:school2) { FactoryBot.create(:school, :ineligible) }
      let!(:school1_partnership) { FactoryBot.create(:school_partnership, school: school1) }
      let!(:school2_partnership) { FactoryBot.create(:school_partnership, school: school2, lead_provider_delivery_partnership: school1_partnership.lead_provider_delivery_partnership) }
      let(:contract_period_id) { school1_partnership.contract_period.id }

      it "returns all schools" do
        expect(described_class.new(contract_period_id:).schools).to contain_exactly(school1, school2)
      end
    end

    it "orders schools by `created_at` date in ascending order" do
      school1 = FactoryBot.create(:school, :eligible, created_at: 2.days.ago)
      school2 = FactoryBot.create(:school, :eligible, created_at: 1.day.ago)
      school3 = FactoryBot.create(:school, :eligible, created_at: Time.zone.now)
      contract_period_id = FactoryBot.create(:contract_period).id

      expect(described_class.new(contract_period_id:).schools).to contain_exactly(school1, school2, school3)
    end

    describe "filtering" do
      describe "by `contract_period_id`" do
        let!(:school1) { FactoryBot.create(:school, :eligible) }
        let!(:school2) { FactoryBot.create(:school) }
        let!(:school3) { FactoryBot.create(:school) }

        let(:another_contract_period) { FactoryBot.create(:contract_period) }
        let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period: another_contract_period) }
        let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
        let!(:school_partnership) { FactoryBot.create(:school_partnership, school: school3, lead_provider_delivery_partnership:) }
        let(:contract_period_id) { another_contract_period.id }

        let(:query_params) do
          {
            contract_period_id:,
          }
        end

        it "filters by `contract_period_id`" do
          expect(query.schools).to contain_exactly(school1, school3)
        end

        context "when `contract_period_id` param is omitted" do
          it "returns no schools" do
            expect(described_class.new.schools).to be_empty
          end
        end

        context "when no `contract_period_id` is found" do
          let!(:contract_period_id) { "0000" }

          it "returns no schools" do
            expect(query.schools).to be_empty
          end
        end

        context "when `contract_period_id` param is blank" do
          let!(:contract_period_id) { " " }

          it "returns no schools" do
            expect(query.schools).to be_empty
          end
        end
      end

      describe "by `updated_since`" do
        let!(:school1) { FactoryBot.create(:school, :eligible, updated_at: 2.days.ago) }
        let!(:school2) { FactoryBot.create(:school, :eligible, updated_at: 10.minutes.ago) }

        let!(:training_period) { FactoryBot.create(:training_period, :active, :for_ect) }
        let!(:school3) { training_period.school_partnership.school }

        let(:contract_period_id) { training_period.contract_period.id }
        let!(:lead_provider_id) { training_period.lead_provider.id }

        let(:updated_since) { 1.day.ago }

        let(:query_params) do
          {
            contract_period_id:,
            lead_provider_id:,
            updated_since:
          }
        end

        it "filters by `updated_since`" do
          expect(query.schools).to contain_exactly(school2, school3)
        end

        context "when `updated_since` param is omitted" do
          let(:query_params) do
            {
              contract_period_id:,
              lead_provider_id:,
            }
          end

          it "returns all eligible schools" do
            expect(query.schools).to contain_exactly(school1, school2, school3)
          end
        end

        context "when `contract_period_id` param is blank" do
          let!(:updated_since) { " " }

          it "returns all eligible schools" do
            expect(query.schools).to contain_exactly(school1, school2, school3)
          end
        end
      end

      describe "by `urn`" do
        let!(:school1) { FactoryBot.create(:school, :eligible, urn: "1234567") }
        let!(:school2) { FactoryBot.create(:school, :eligible, urn: "4567890") }
        let(:contract_period_id) { FactoryBot.create(:contract_period).id }
        let!(:urn) { school1.urn }

        let(:query_params) do
          {
            contract_period_id:,
            urn:,
          }
        end

        it "filters by `urn`" do
          expect(query.schools).to contain_exactly(school1)
        end

        context "when `urn` param is omitted" do
          let(:query_params) do
            {
              contract_period_id:,
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

      let(:contract_period_id) { FactoryBot.create(:contract_period).id }

      let(:sort) { nil }

      let(:query_params) do
        {
          contract_period_id:,
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

    describe "transient_in_partnership" do
      let!(:school) { FactoryBot.create(:school, :eligible) }
      let(:contract_period_id) { FactoryBot.create(:contract_period).id }
      let(:query_schools) { query.schools }
      let(:returned_school) { query_schools.find(school.id) }

      it { expect(returned_school).not_to be_transient_in_partnership }

      context "when there is any partnership for the given school and contract period" do
        let(:school_partnership) { FactoryBot.create(:school_partnership, school:) }
        let!(:contract_period_id) { school_partnership.contract_period.id }

        it { expect(returned_school).to be_transient_in_partnership }
      end
    end

    describe "transient_mentors_at_school" do
      let!(:school) { FactoryBot.create(:school, :eligible) }
      let(:query_schools) { query.schools }
      let(:returned_school) { query_schools.find(school.id) }
      let(:contract_period_id) { FactoryBot.create(:contract_period).id }

      it { expect(returned_school).not_to be_transient_mentors_at_school }

      context "when there is any mentors with expression of interest for the given school and contract period" do
        let!(:training_period) { FactoryBot.create(:training_period, :active, :with_only_expression_of_interest, :for_mentor) }
        let(:contract_period_id) { training_period.expression_of_interest.contract_period.id }

        before do
          training_period.mentor_at_school_period.update!(school_id: school.id)
        end

        it { expect(returned_school).to be_transient_mentors_at_school }
      end

      context "when there is any mentors in training for the given school and contract period" do
        let!(:training_period) { FactoryBot.create(:training_period, :active, :with_school_partnership, :for_mentor) }
        let(:contract_period_id) { training_period.contract_period.id }

        before do
          training_period.mentor_at_school_period.update!(school_id: school.id)
          training_period.school_partnership.update!(school_id: school.id)
        end

        it { expect(returned_school).to be_transient_mentors_at_school }
      end
    end

    describe "transient_ects_at_school_training_programme" do
      let!(:school) { FactoryBot.create(:school, :eligible) }
      let(:query_schools) { query.schools }
      let(:returned_school) { query_schools.find(school.id) }
      let(:contract_period_id) { FactoryBot.create(:contract_period).id }

      it { expect(returned_school).not_to be_transient_ects_at_school_training_programme }

      context "when there is any ects with expression of interest for the given school and contract period" do
        let!(:training_period) { FactoryBot.create(:training_period, :active, :with_only_expression_of_interest, :for_ect) }
        let(:contract_period_id) { training_period.expression_of_interest.contract_period.id }

        before do
          training_period.ect_at_school_period.update!(school_id: school.id)
        end

        it { expect(returned_school).to be_transient_ects_at_school_training_programme }
      end

      context "when there is any ects in training for the given school and contract period" do
        let!(:training_period) { FactoryBot.create(:training_period, :active, :with_school_partnership, :for_ect) }
        let(:contract_period_id) { training_period.contract_period.id }

        before do
          training_period.ect_at_school_period.update!(school_id: school.id)
          training_period.school_partnership.update!(school_id: school.id)
        end

        context "when ect has chosen `provider_led` as training programme" do
          it "returns `provider_led`" do
            expect(returned_school.transient_ects_at_school_training_programme).to eq("provider_led")
          end
        end

        context "when ect has chosen `school_led` as training programme" do
          before do
            training_period.ect_at_school_period.update!(training_programme: "school_led")
          end

          it "returns `provider_led`" do
            expect(returned_school.transient_ects_at_school_training_programme).to eq("school_led")
          end
        end
      end
    end

    describe "transient_expression_of_interest_ects" do
      let!(:school) { FactoryBot.create(:school, :eligible) }
      let(:query_schools) { query.schools }
      let(:returned_school) { query_schools.find(school.id) }
      let(:contract_period_id) { FactoryBot.create(:contract_period).id }
      let(:lead_provider_id) { FactoryBot.create(:lead_provider).id }

      let(:query_params) do
        {
          contract_period_id:,
          lead_provider_id:,
        }
      end

      it { expect(returned_school).not_to be_transient_expression_of_interest_ects }

      context "when there is any expression of interest from an ect for the given school/contract period/lead provider" do
        let!(:training_period) { FactoryBot.create(:training_period, :active, :with_only_expression_of_interest, :for_ect) }
        let(:lead_provider_id) { training_period.expression_of_interest.lead_provider.id }
        let(:contract_period_id) { training_period.expression_of_interest.contract_period.id }

        before do
          training_period.ect_at_school_period.update!(school_id: school.id)
        end

        it { expect(returned_school).to be_transient_expression_of_interest_ects }
      end

      context "when there is any expression of interest from a mentor for the given school/contract period/lead provider" do
        let!(:training_period) { FactoryBot.create(:training_period, :active, :with_only_expression_of_interest, :for_mentor) }
        let(:lead_provider_id) { training_period.expression_of_interest.lead_provider.id }
        let(:contract_period_id) { training_period.expression_of_interest.contract_period.id }

        before do
          training_period.mentor_at_school_period.update!(school_id: school.id)
        end

        it { expect(returned_school).not_to be_transient_expression_of_interest_ects }
      end
    end

    describe "transient_expression_of_interest_mentors" do
      let!(:school) { FactoryBot.create(:school, :eligible) }
      let(:query_schools) { query.schools }
      let(:returned_school) { query_schools.find(school.id) }
      let(:contract_period_id) { FactoryBot.create(:contract_period).id }
      let(:lead_provider_id) { FactoryBot.create(:lead_provider).id }

      let(:query_params) do
        {
          contract_period_id:,
          lead_provider_id:,
        }
      end

      it { expect(returned_school).not_to be_transient_expression_of_interest_mentors }

      context "when there is any expression of interest from a mentor for the given school/contract period/lead provider" do
        let!(:training_period) { FactoryBot.create(:training_period, :active, :with_only_expression_of_interest, :for_mentor) }
        let(:lead_provider_id) { training_period.expression_of_interest.lead_provider.id }
        let(:contract_period_id) { training_period.expression_of_interest.contract_period.id }

        before do
          training_period.mentor_at_school_period.update!(school_id: school.id)
        end

        it { expect(returned_school).to be_transient_expression_of_interest_mentors }
      end

      context "when there is any expression of interest from an ect for the given school/contract period/lead provider" do
        let!(:training_period) { FactoryBot.create(:training_period, :active, :with_only_expression_of_interest, :for_ect) }
        let(:lead_provider_id) { training_period.expression_of_interest.lead_provider.id }
        let(:contract_period_id) { training_period.expression_of_interest.contract_period.id }

        before do
          training_period.ect_at_school_period.update!(school_id: school.id)
        end

        it { expect(returned_school).not_to be_transient_expression_of_interest_mentors }
      end
    end
  end

  describe "#school_by_api_id" do
    subject(:query) { described_class.new(**query_params) }

    let(:contract_period) { FactoryBot.create(:contract_period) }
    let(:query_params) do
      {
        contract_period_id: contract_period.id,
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

  describe "#school" do
    subject(:query) { described_class.new(**query_params) }

    let(:contract_period) { FactoryBot.create(:contract_period) }
    let(:query_params) do
      {
        contract_period_id: contract_period.id,
      }
    end

    let(:school) { FactoryBot.create(:school, :eligible) }

    it "returns a school for the given school id" do
      expect(query.school(school.id)).to eq(school)
    end

    it "raises an error if the school does not exist" do
      expect { query.school("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an id is not supplied" do
      expect { query.school(nil) }.to raise_error(ArgumentError, "id needed")
    end
  end
end
