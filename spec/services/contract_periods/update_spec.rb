RSpec.describe ContractPeriods::Update do
  include ActiveJob::TestHelper

  subject { described_class.new(author:, contract_period:, params:) }

  let(:author) { Events::SystemAuthor.new }
  let(:contract_period) do
    FactoryBot.create(
      :contract_period,
      year: 2025,
      started_on: "2025-06-01",
      finished_on: "2025-10-31"
    )
  end
  let(:params) { {} }

  describe "#update!" do
    context "with valid params" do
      let(:params) do
        {
          started_on: "2025-01-01",
          finished_on: "2025-12-31",
        }
      end

      it "updates the record" do
        expect { subject.update! }.to change { contract_period.reload.started_on }.to(Date.parse("2025-01-01"))
          .and change { contract_period.reload.finished_on }.to(Date.parse("2025-12-31"))
      end

      it "records a `contract_period_updated` event" do
        subject.update!

        perform_enqueued_jobs

        expect(Event.all.map(&:event_type)).to match_array(%w[contract_period_updated])
      end

      it "creates an event with the expected values" do
        freeze_time

        subject.update!

        perform_enqueued_jobs

        last_event = Event.find_by(event_type: "contract_period_updated")
        contract_period = last_event.contract_period
        expect(contract_period.year).to eq(2025)
        expect(contract_period.started_on.to_date).to eql(Date.parse("2025-01-01"))
        expect(contract_period.finished_on.to_date).to eql(Date.parse("2025-12-31"))
        expect(last_event.modifications).to contain_exactly(
          "Started on changed from '1 Jun 2025' to '1 Jan 2025'",
          "Finished on changed from '31 Oct 2025' to '31 Dec 2025'"
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

    it "raises an error" do
      expect { subject.update! }.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Finished on The end date must be later than the start date (31 December #{Date.current.end_of_year.year})"
      )
    end
  end
end
