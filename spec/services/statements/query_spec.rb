RSpec.describe Statements::Query do
  describe "#statements" do
    let(:lead_provider) { FactoryBot.create(:lead_provider) }

    it "returns all statements" do
      statement = FactoryBot.create(:statement)
      query = described_class.new

      expect(query.statements).to eq([statement])
    end

    it "orders statements by payment date in ascending order" do
      statement1 = FactoryBot.create(:statement, payment_date: 2.days.ago)
      statement2 = FactoryBot.create(:statement, payment_date: 1.day.ago)
      statement3 = FactoryBot.create(:statement, payment_date: Time.zone.now)

      query = described_class.new

      expect(query.statements).to eq([statement1, statement2, statement3])
    end

    describe "filtering" do
      describe "by `lead_provider`" do
        let!(:statement1) { FactoryBot.create(:statement, lead_provider:) }
        let!(:statement2) { FactoryBot.create(:statement) }
        let!(:statement3) { FactoryBot.create(:statement) }

        context "when `lead_provider` param is omitted" do
          it "returns all statements" do
            expect(described_class.new.statements).to contain_exactly(statement1, statement2, statement3)
          end
        end

        it "filters by `lead_provider`" do
          query = described_class.new(lead_provider_id: lead_provider.id)

          expect(query.statements).to eq([statement1])
        end

        it "returns no statements if no statements are found for the given `lead_provider`" do
          query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

          expect(query.statements).to be_empty
        end

        it "does not filter by `lead_provider` if an empty string is supplied" do
          query = described_class.new(lead_provider_id: " ")

          expect(query.statements).to contain_exactly(statement1, statement2, statement3)
        end
      end

      describe "by `contract_period_years`" do
        let!(:contract_period1) { FactoryBot.create(:contract_period) }
        let!(:contract_period2) { FactoryBot.create(:contract_period) }
        let!(:contract_period3) { FactoryBot.create(:contract_period) }

        context "when `contract_period_years` param is omitted" do
          it "returns all statements" do
            statement1 = FactoryBot.create(:statement, contract_period: contract_period1)
            statement2 = FactoryBot.create(:statement, contract_period: contract_period2)
            statement3 = FactoryBot.create(:statement, contract_period: contract_period3)

            expect(described_class.new.statements).to contain_exactly(statement1, statement2, statement3)
          end
        end

        it "filters by `contract_period_years`" do
          _statement = FactoryBot.create(:statement, contract_period: contract_period1)
          statement = FactoryBot.create(:statement, contract_period: contract_period2)
          query = described_class.new(contract_period_years: contract_period2.year)

          expect(query.statements).to eq([statement])
        end

        it "filters by multiple `contract_period_years`" do
          statement1 = FactoryBot.create(:statement, contract_period: contract_period1)
          statement2 = FactoryBot.create(:statement, contract_period: contract_period2)
          statement3 = FactoryBot.create(:statement, contract_period: contract_period3)

          query1 = described_class.new(contract_period_years: "#{contract_period1.year},#{contract_period2.year}")
          expect(query1.statements).to contain_exactly(statement1, statement2)

          query2 = described_class.new(contract_period_years: [contract_period2.year.to_s, contract_period3.year.to_s])
          expect(query2.statements).to contain_exactly(statement2, statement3)
        end

        it "returns no statements if no `contract_period_years` are found" do
          query = described_class.new(contract_period_years: "0000")

          expect(query.statements).to be_empty
        end

        it "does not filter by `contract_period_years` if blank" do
          statement1 = FactoryBot.create(:statement, contract_period: contract_period1)
          statement2 = FactoryBot.create(:statement, contract_period: contract_period2)

          query = described_class.new(contract_period_years: " ")

          expect(query.statements).to contain_exactly(statement1, statement2)
        end
      end

      describe "by `updated_since`" do
        let(:updated_since) { 1.day.ago }

        it "filters by `updated_since`" do
          FactoryBot.create(:statement, lead_provider:, updated_at: 2.days.ago)
          statement2 = FactoryBot.create(:statement, lead_provider:, updated_at: Time.zone.now)

          query = described_class.new(lead_provider_id: lead_provider.id, updated_since:)

          expect(query.statements).to eq([statement2])
        end

        context "when `updated_since` param is omitted" do
          it "returns all statements" do
            statement1 = FactoryBot.create(:statement, updated_at: 1.week.ago)
            statement2 = FactoryBot.create(:statement, updated_at: 2.weeks.ago)

            expect(described_class.new.statements).to contain_exactly(statement1, statement2)
          end
        end

        it "does not filter by `updated_since` if blank" do
          statement1 = FactoryBot.create(:statement, updated_at: 1.week.ago)
          statement2 = FactoryBot.create(:statement, updated_at: 2.weeks.ago)

          query = described_class.new(updated_since: " ")

          expect(query.statements).to contain_exactly(statement1, statement2)
        end
      end

      describe "by `fee_type`" do
        let!(:statement1) { FactoryBot.create(:statement, :output_fee) }
        let!(:statement2) { FactoryBot.create(:statement, :service_fee) }

        it "return only statements with `fee_type` 'output' by default" do
          expect(described_class.new.statements).to eq([statement1])
        end

        context "when `fee_type`: 'output'" do
          it "return only statements with fee type of service" do
            query = described_class.new(fee_type: "output")

            expect(query.statements).to eq([statement1])
          end
        end

        context "when `fee_type`: 'service'" do
          it "return only statements with fee type of service" do
            query = described_class.new(fee_type: "service")

            expect(query.statements).to eq([statement2])
          end
        end

        context "when `output_fee`: :ignore" do
          it "returns all statements" do
            query = described_class.new(fee_type: :ignore)

            expect(query.statements).to contain_exactly(statement1, statement2)
          end
        end

        it "does not filter by `output_fee` if blank" do
          query = described_class.new(fee_type: " ")

          expect(query.statements).to contain_exactly(statement1, statement2)
        end

        it 'raises an error when searching by an invalid fee type' do
          expect { described_class.new(fee_type: "something_else") }.to raise_error(Statements::Query::InvalidFeeTypeError)
        end
      end
    end

    describe "ordering" do
      let!(:statement1) { FactoryBot.create(:statement, year: 2025, month: 4, payment_date: "2024-01-01") }
      let!(:statement2) { FactoryBot.create(:statement, year: 2024, month: 8, payment_date: "2025-01-01") }

      describe "default order" do
        it "returns statements in correct order" do
          query = described_class.new
          expect(query.statements).to eq([statement1, statement2])
        end
      end

      describe "sort by payment_date" do
        it "returns statements in correct order" do
          query = described_class.new(sort: "+payment_date")
          expect(query.statements).to eq([statement1, statement2])
        end
      end

      describe "sort by year and month" do
        it "returns statements in correct order" do
          query = described_class.new(sort: "+year,+month")
          expect(query.statements).to eq([statement2, statement1])
        end
      end
    end
  end

  describe "#statement_by_api_id" do
    let(:lead_provider) { FactoryBot.create(:lead_provider) }

    it "returns the statement for a Lead Provider" do
      statement = FactoryBot.create(:statement, lead_provider:)
      query = described_class.new

      expect(query.statement_by_api_id(statement.api_id)).to eq(statement)
    end

    it "raises an error if the statement does not exist" do
      query = described_class.new

      expect { query.statement_by_api_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the statement is not in the filtered query" do
      other_lead_provider = FactoryBot.create(:lead_provider)
      other_statement = FactoryBot.create(:statement, lead_provider: other_lead_provider)

      query = described_class.new(lead_provider_id: lead_provider.id)

      expect { query.statement_by_api_id(other_statement.api_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an api_id is not supplied" do
      expect { described_class.new.statement_by_api_id(nil) }.to raise_error(ArgumentError, "api_id needed")
    end
  end

  describe "#statement_by_id" do
    let(:lead_provider) { FactoryBot.create(:lead_provider) }

    it "returns the statement for a Lead Provider" do
      statement = FactoryBot.create(:statement, lead_provider:)
      query = described_class.new

      expect(query.statement_by_id(statement.id)).to eq(statement)
    end

    it "raises an error if the statement does not exist" do
      query = described_class.new

      expect { query.statement_by_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the statement is not in the filtered query" do
      other_lead_provider = FactoryBot.create(:lead_provider)
      other_statement = FactoryBot.create(:statement, lead_provider: other_lead_provider)

      query = described_class.new(lead_provider_id: lead_provider.id)

      expect { query.statement_by_id(other_statement.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an api_id is not supplied" do
      expect { described_class.new.statement_by_id(nil) }.to raise_error(ArgumentError, "id needed")
    end
  end
end
