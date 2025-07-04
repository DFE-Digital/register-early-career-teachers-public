RSpec.describe SandboxSeedData::Statements do
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

    it "creates statements for active lead providers with the correct attributes" do
      instance.plant

      registration_year = contract_period.year
      years = (registration_year...(registration_year + described_class::YEARS_TO_CREATE)).to_a
      months = described_class::MONTHS.to_a

      years.product(months).each do |year, month|
        statement = Statement.find_by(year:, month:)
        expected_deadline_date = Date.new(year, month).end_of_month

        expect(statement).to have_attributes(
          active_lead_provider:,
          deadline_date: expected_deadline_date,
          payment_date: be_between(expected_deadline_date, expected_deadline_date + 2.months),
          status: be_in(%w[open payable paid])
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
      expect(logger).to have_received(:info).with(/#{contract_period.year + described_class::YEARS_TO_CREATE - 1}/).once

      described_class::MONTHS.each do |month|
        expect(logger).to have_received(:info).with(/#{Date::MONTHNAMES[month]}/).at_least(:once)
      end

      %i[OP PB PD].each do |status|
        expect(logger).to have_received(:info).with(/#{status}/).at_least(:once)
      end
    end

    it "does not create data when already present" do
      number_of_statements_created = described_class::YEARS_TO_CREATE * described_class::MONTHS.count
      expect { instance.plant }.to change(Statement, :count).by(number_of_statements_created)

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
