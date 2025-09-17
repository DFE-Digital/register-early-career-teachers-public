RSpec.describe SchoolPartnerships::Create do
  let(:contract_period) { FactoryBot.create(:contract_period) }

  let(:school) { FactoryBot.create(:school, :eligible) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }

  let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }

  let(:service) do
    described_class.new(
      school:,
      lead_provider_delivery_partnership:
    )
  end

  describe "#create" do
    subject(:create_school_partnership) { service.create }

    it "creates a school partnership" do
      created_school_partnership = nil

      expect { created_school_partnership = create_school_partnership }.to change(SchoolPartnership, :count).by(1)

      expect(created_school_partnership).to have_attributes(school:, lead_provider_delivery_partnership:)
    end

    it "records a school partnership created event" do
      allow(Events::Record).to receive(:record_school_partnership_created_event!).once.and_call_original

      school_partnership = create_school_partnership

      expect(Events::Record).to have_received(:record_school_partnership_created_event!).once.with(
        hash_including(
          {
            school_partnership:,
            author: an_object_having_attributes(
              class: Events::LeadProviderAPIAuthor,
              lead_provider:
            ),
          }
        )
      )
    end

    it 'links eligible training periods to the new school partnership' do
      ect_at_school_period = FactoryBot.create(
        :ect_at_school_period,
        school:,
        started_on: Date.new(2025, 1, 1),
        finished_on: Date.new(2025, 12, 31)
      )

      training_period = FactoryBot.create(
        :training_period,
        :with_only_expression_of_interest,
        ect_at_school_period:,
        expression_of_interest: active_lead_provider,
        started_on: Date.new(2025, 3, 1),
        finished_on: Date.new(2025, 3, 31)
      )

      created_school_partnership = create_school_partnership

      expect {
        training_period.reload
      }.to change { training_period.school_partnership }
        .from(nil).to(created_school_partnership)
    end

    it 'delegates training period assignment to AssignTrainingPeriods' do
      assign_service = instance_double(SchoolPartnerships::AssignTrainingPeriods, call: true)

      allow(SchoolPartnerships::AssignTrainingPeriods).to receive(:new)
        .with(
          school_partnership: an_instance_of(SchoolPartnership),
          school:,
          lead_provider:,
          contract_period:
        )
        .and_return(assign_service)

      service.create

      expect(assign_service).to have_received(:call).once
    end

    it 'raises an error if the school and delivery partnership are already linked' do
      FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)

      expect {
        service.create
      }.to raise_error(ActiveRecord::RecordInvalid, /must be unique/)
    end
  end
end
