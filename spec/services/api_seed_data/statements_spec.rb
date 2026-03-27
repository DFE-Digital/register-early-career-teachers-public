RSpec.describe APISeedData::Statements do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  describe "#plant" do
    let(:contract_period) { FactoryBot.create(:contract_period, year: Time.zone.now.year - 1) }
    let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
    let!(:contracts) { FactoryBot.create_list(:contract, 3, :for_ittecf_ectp, active_lead_provider:) }

    it "creates statements for active lead providers with the correct attributes" do
      instance.plant

      cohort_year = contract_period.year
      year_month_pairs = instance.send(:statement_year_month_pairs, cohort_year)

      year_month_pairs.each_with_index do |(year, month), index|
        statement = Statement.find_by(year:, month:)
        expected_deadline_date = Date.new(year, month, 1).prev_day
        expected_payment_date = Date.new(year, month, 25)
        expected_fee_type = month.in?(described_class::OUTPUT_FEE_MONTHS) ? "output" : "service"
        expected_contract = contracts[(index * contracts.size) / year_month_pairs.size]

        expect(statement).to have_attributes(
          active_lead_provider:,
          deadline_date: expected_deadline_date,
          payment_date: expected_payment_date,
          status: be_in(%w[open payable paid]),
          fee_type: expected_fee_type,
          contract: expected_contract
        )
      end
    end

    it "creates statements with all states" do
      instance.plant

      expect(Statement.distinct.pluck(:status)).to match_array(%w[open payable paid])
    end

    it "logs the creation of statements" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting statements/).once

      expect(logger).to have_received(:info).with(/#{active_lead_provider.lead_provider.name}/).once

      expect(logger).to have_received(:info).with(/#{contract_period.year}/).once
      expect(logger).to have_received(:info).with(/#{contract_period.year + 3}/).once

      (1..12).each do |month|
        expect(logger).to have_received(:info).with(/#{Date::MONTHNAMES[month]}/).at_least(:once)
      end

      %i[OP PB PD].each do |status|
        expect(logger).to have_received(:info).with(/#{status}/).at_least(:once)
      end
    end

    it "does not create data when already present" do
      expect { instance.plant }.to change(Statement, :count)
      expect { instance.plant }.not_to change(Statement, :count)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any statements" do
        expect { instance.plant }.not_to change(Statement, :count)
      end
    end
  end
end
