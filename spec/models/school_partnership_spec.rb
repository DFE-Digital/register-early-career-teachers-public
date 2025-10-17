describe SchoolPartnership do
  describe "declarative updates" do
    describe "declarative touch" do
      let(:instance) { FactoryBot.create(:school_partnership) }
      let(:target) { instance }

      def will_change_attribute(attribute_to_change:, new_value:)
        FactoryBot.create(:lead_provider_delivery_partnership, id: new_value) if attribute_to_change == :lead_provider_delivery_partnership
      end

      it_behaves_like "a declarative touch model",
                      when_changing: %i[lead_provider_delivery_partnership_id],
                      timestamp_attribute: :api_updated_at
    end

    describe "declarative metadata" do
      let(:instance) { FactoryBot.create(:school_partnership, school: target) }
      let!(:target) { FactoryBot.create(:school) }

      it_behaves_like "a declarative metadata model", on_event: %i[create destroy update]
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:lead_provider_delivery_partnership).inverse_of(:school_partnerships) }
    it { is_expected.to belong_to(:school) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:ongoing_training_periods).class_name("TrainingPeriod") }
    it { is_expected.to have_one(:active_lead_provider).through(:lead_provider_delivery_partnership) }
    it { is_expected.to have_one(:delivery_partner).through(:lead_provider_delivery_partnership) }
    it { is_expected.to have_one(:contract_period).through(:active_lead_provider) }
    it { is_expected.to have_one(:lead_provider).through(:active_lead_provider) }
    it { is_expected.to have_many(:training_periods) }

    describe "#ongoing_training_periods" do
      subject { instance.ongoing_training_periods }

      let(:instance) { FactoryBot.create(:school_partnership) }
      let(:ongoing_training_period) { FactoryBot.create(:training_period, :ongoing, school_partnership: instance) }

      before do
        # Different lead provider
        FactoryBot.create(:training_period, :ongoing, :with_school_partnership)
        # Not on-going today
        ect_at_school_period = FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, finished_on: 1.month.ago)
        FactoryBot.create(:training_period, school_partnership: instance, ect_at_school_period:, started_on: 5.months.ago, finished_on: 2.months.ago)
        FactoryBot.create(:training_period, school_partnership: instance, started_on: 1.week.from_now, finished_on: nil)
      end

      it { is_expected.to contain_exactly(ongoing_training_period) }
    end
  end

  describe "validations" do
    subject { FactoryBot.create(:school_partnership) }

    it { is_expected.to validate_presence_of(:lead_provider_delivery_partnership_id) }
    it { is_expected.to validate_presence_of(:school_id) }

    it do
      expect(subject).to validate_uniqueness_of(:school_id)
        .scoped_to(:lead_provider_delivery_partnership_id)
        .with_message("School and lead provider delivery partnership combination must be unique")
    end
  end

  describe "scopes" do
    describe ".earliest_first" do
      let!(:school_partnership_first)  { FactoryBot.create(:school_partnership, created_at: 3.weeks.ago) }
      let!(:school_partnership_second) { FactoryBot.create(:school_partnership, created_at: 2.weeks.ago) }
      let!(:school_partnership_third)  { FactoryBot.create(:school_partnership, created_at: 1.week.ago) }

      it "orders with earliest created records first" do
        expect(SchoolPartnership.earliest_first.to_a).to eq([
          school_partnership_first,
          school_partnership_second,
          school_partnership_third,
        ])
      end
    end

    context "with contract period data" do
      let(:contract_period_1) { FactoryBot.create(:contract_period) }
      let(:contract_period_2) { FactoryBot.create(:contract_period) }

      let(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, contract_period: contract_period_1) }
      let(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, contract_period: contract_period_2) }

      let(:lead_provider_delivery_partnership_1) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider_1) }
      let(:lead_provider_delivery_partnership_2) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider_2) }

      let!(:school_partnership_1) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership_1) }
      let!(:school_partnership_2) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership_2) }

      describe ".for_contract_period" do
        it "returns school partnerships only for the specified contract period" do
          expect(described_class.for_contract_period(contract_period_2.id)).to contain_exactly(school_partnership_2)
        end
      end

      describe ".for_contract_period_year" do
        it "returns partnerships only for the specified contract period year" do
          result = described_class.for_contract_period_year(contract_period_1.year)
          expect(result).to contain_exactly(school_partnership_1)
          expect(result).not_to include(school_partnership_2)
        end
      end

      describe ".excluding_contract_period_year" do
        it "excludes partnerships from the specified contract period year" do
          result = described_class.excluding_contract_period_year(contract_period_1.year)
          expect(result).to contain_exactly(school_partnership_2)
          expect(result).not_to include(school_partnership_1)
        end
      end

      describe ".latest_by_contract_year" do
        let!(:school_partnership_for_contract_period_1_newer) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership_1, created_at: 1.day.ago) }
        let!(:school_partnership_for_contract_period_1_older) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership_1, created_at: 3.days.ago) }
        let!(:school_partnership_for_contract_period_2_newer) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership_2, created_at: Time.current) }
        let!(:school_partnership_for_contract_period_2_older) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership_2, created_at: 2.days.ago) }

        before do
          school_partnership_1.update!(created_at: 4.days.ago)
          school_partnership_2.update!(created_at: 5.days.ago)
        end

        it "orders by contract period year desc, then created_at desc" do
          result = described_class.latest_by_contract_year.to_a

          expect(result).to eq([
            school_partnership_for_contract_period_2_newer,
            school_partnership_for_contract_period_2_older,
            school_partnership_2,
            school_partnership_for_contract_period_1_newer,
            school_partnership_for_contract_period_1_older,
            school_partnership_1
          ])
        end
      end
    end
  end
end
