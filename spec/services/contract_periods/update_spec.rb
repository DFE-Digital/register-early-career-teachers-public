RSpec.describe ContractPeriods::Update do
  include ActiveJob::TestHelper

  subject(:service) { described_class.new(author:, contract_period:, params:) }

  let(:author) { Events::SystemAuthor.new }

  let(:started_on) { 1.year.from_now.beginning_of_year }
  let(:finished_on) { 1.year.from_now.end_of_year }

  let(:contract_period) do
    FactoryBot.create(
      :contract_period,
      year: 1.year.from_now.year,
      started_on:,
      finished_on:,
      detailed_evidence_types_enabled: true
    )
  end
  let(:params) { {} }

  describe "#update!" do
    context "with valid params" do
      let(:params) do
        {
          started_on: started_on + 3.months,
          finished_on: finished_on - 3.months,
        }
      end

      it "updates the record" do
        expect { service.update! }.to change { contract_period.reload.started_on }.to((started_on + 3.months).to_date)
          .and change { contract_period.reload.finished_on }.to((finished_on - 3.months).to_date)
      end

      it "records a `contract_period_updated` event" do
        service.update!

        perform_enqueued_jobs

        expect(Event.all.map(&:event_type)).to match_array(%w[contract_period_updated])
      end

      it "creates an event with the expected values" do
        freeze_time

        service.update!

        perform_enqueued_jobs

        last_event = Event.find_by(event_type: "contract_period_updated")
        contract_period = last_event.contract_period
        expect(contract_period.year).to eq(1.year.from_now.year)
        expect(contract_period.started_on.to_date).to eql((started_on + 3.months).to_date)
        expect(contract_period.finished_on.to_date).to eql((finished_on - 3.months).to_date)
        expect(last_event.modifications).to contain_exactly(
          "Started on changed from '#{started_on.to_date.to_formatted_s(:govuk_short)}' to '#{(started_on + 3.months).to_date.to_formatted_s(:govuk_short)}'",
          "Finished on changed from '#{finished_on.to_date.to_formatted_s(:govuk_short)}' to '#{(finished_on - 3.months).to_date.to_formatted_s(:govuk_short)}'"
        )
      end

      it "returns the updated period and exposes it as a attr" do
        returned_value = subject.update!

        expect(returned_value).to be_an(ContractPeriod)
        expect(subject.contract_period).to be(returned_value)
      end
    end
  end

  context "with invalid params" do
    let(:params) do
      {
        year: contract_period.year,
        started_on: Date.current.end_of_year,
        finished_on: Date.current.beginning_of_year,
      }
    end

    # it "returns false" do
    #   expect(subject.update!).to be_falsey
    # end

    before do
      allow(Events::Record).to receive(:record_contract_period_updated_event!)
    end

    it "raises an error" do
      expect { service.update! }.to raise_error(/Finished on The end date must be later than the start date/)
      expect(Events::Record).not_to have_received(:record_contract_period_updated_event!)
    end
  end
end
