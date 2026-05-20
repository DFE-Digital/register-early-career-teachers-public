describe ContractPeriods::Create do
  include ActiveJob::TestHelper

  subject { described_class.new(author:, params:) }

  let(:params) do
    {
      year: 1.year.from_now.year,
      started_on: 1.year.from_now.beginning_of_year,
      finished_on: 1.year.from_now.end_of_year,
      detailed_evidence_types_enabled: false,
      mentor_funding_enabled: true,
      uplift_fees_enabled: false,
    }
  end
  let(:author) { Events::SystemAuthor.new }

  before do
    allow(ContractPeriods::SeedFromPrevious).to receive(:new).and_return(instance_double(ContractPeriods::SeedFromPrevious, schedule!: true))
  end

  describe "#initialize" do
    it "accepts and assigns the author and params" do
      expect(subject.author).to eql(author)
      expect(subject.contract_period).to be_a(ContractPeriod)
    end
  end

  describe "#create!" do
    context "with valid params" do
      it "saves the record" do
        contract_period = subject.create!

        expect(contract_period).to be_a(ContractPeriod)
        expect(contract_period).to be_persisted
      end

      it "records a `contract_period_added` event" do
        subject.create!

        perform_enqueued_jobs

        expect(Event.all.map(&:event_type)).to match_array(%w[contract_period_added])
      end

      it "creates an event with the expected values" do
        freeze_time

        subject.create!

        perform_enqueued_jobs

        last_event = Event.find_by(event_type: "contract_period_added")
        contract_period = last_event.contract_period
        expect(contract_period.year).to eql(1.year.from_now.year)
        expect(contract_period.started_on.to_date).to eql(1.year.from_now.beginning_of_year.to_date)
        expect(contract_period.finished_on.to_date).to eql(1.year.from_now.end_of_year.to_date)
        expect(contract_period.detailed_evidence_types_enabled).to be false
        expect(contract_period.mentor_funding_enabled).to be true
        expect(contract_period.uplift_fees_enabled).to be false
      end

      it "returns the create period and exposes it as a attr" do
        returned_value = subject.create!

        expect(returned_value).to be_an(ContractPeriod)
        expect(subject.contract_period).to be(returned_value)
      end
    end

    context "with invalid params" do
      let(:params) do
        {
          year: 1.year.from_now.year,
          started_on: Date.current.end_of_year,
          finished_on: Date.current.beginning_of_year,
        }
      end

      it "returns false" do
        expect(subject.create!).to be_falsey
      end

      it "does not record an event" do
        subject.create!

        perform_enqueued_jobs

        expect(Event.count).to be_zero
      end
    end
  end
end
