RSpec.describe SchoolPartnerships::AssignTrainingPeriods do
  include ActiveJob::TestHelper

  describe "#call" do
    subject(:service) do
      described_class.new(
        school_partnership:,
        school:,
        lead_provider:,
        contract_period:,
        author:
      )
    end

    let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
    let(:school) { FactoryBot.create(:school) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }

    let(:school_partnership) do
      FactoryBot.create(:school_partnership,
                        school:,
                        lead_provider_delivery_partnership: FactoryBot.create(
                          :lead_provider_delivery_partnership,
                          active_lead_provider: FactoryBot.create(
                            :active_lead_provider,
                            lead_provider:,
                            contract_period:
                          )
                        ))
    end

    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period,
                        school:,
                        started_on: Date.new(2025, 1, 1),
                        finished_on: Date.new(2025, 12, 31))
    end

    let(:matching_expression_of_interest) do
      FactoryBot.create(:active_lead_provider,
                        lead_provider:,
                        contract_period_year: contract_period.year)
    end

    let!(:linkable_tp) do
      FactoryBot.create(:training_period,
                        :with_only_expression_of_interest,
                        ect_at_school_period:,
                        expression_of_interest: matching_expression_of_interest,
                        started_on: Date.new(2025, 3, 1),
                        finished_on: Date.new(2025, 3, 31))
    end

    let!(:already_linked_tp) do
      FactoryBot.create(:training_period,
                        :with_expression_of_interest,
                        ect_at_school_period:,
                        school_partnership:,
                        expression_of_interest: matching_expression_of_interest,
                        started_on: Date.new(2025, 4, 1),
                        finished_on: Date.new(2025, 4, 30))
    end

    let!(:wrong_provider_tp) do
      FactoryBot.create(:training_period,
                        :with_only_expression_of_interest,
                        ect_at_school_period:,
                        expression_of_interest: FactoryBot.create(:active_lead_provider,
                                                                  lead_provider: FactoryBot.create(:lead_provider), # different provider
                                                                  contract_period_year: contract_period.year),
                        started_on: Date.new(2025, 5, 1),
                        finished_on: Date.new(2025, 5, 31))
    end

    let!(:wrong_year_tp) do
      wrong_contract_period = FactoryBot.create(:contract_period, year: 2030)

      FactoryBot.create(:training_period,
                        :with_only_expression_of_interest,
                        ect_at_school_period:,
                        expression_of_interest: FactoryBot.create(:active_lead_provider,
                                                                  lead_provider:,
                                                                  contract_period_year: wrong_contract_period.year),
                        started_on: Date.new(2025, 6, 1),
                        finished_on: Date.new(2025, 6, 30))
    end

    it "links only eligible training periods to the given school partnership" do
      expect {
        service.call
      }.to change { linkable_tp.reload.school_partnership }
        .from(nil)
        .to(school_partnership)
    end

    it "does not link already linked training periods" do
      expect { service.call }.not_to(change { already_linked_tp.reload.school_partnership })
    end

    it "does not link tp with different lead providers" do
      expect { service.call }.not_to(change { wrong_provider_tp.reload.school_partnership })
    end

    it "does not link tp with different contract periods" do
      expect { service.call }.not_to(change { wrong_year_tp.reload.school_partnership })
    end

    it "records a training_period_assigned_to_school_partnership event for each newly linked training period" do
      perform_enqueued_jobs do
        expect {
          service.call
        }.to change { Event.where(event_type: "training_period_assigned_to_school_partnership").count }.by(1)
      end

      expect(Event.last).to have_attributes(
        event_type: "training_period_assigned_to_school_partnership",
        school_partnership:,
        training_period: linkable_tp,
        lead_provider:,
        delivery_partner: school_partnership.delivery_partner,
        school:
      )
    end
  end
end
