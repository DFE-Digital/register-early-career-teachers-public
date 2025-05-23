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
          query = described_class.new(lead_provider:)

          expect(query.statements).to eq([statement1])
        end

        it "returns no statements if no statements are found for the given `lead_provider`" do
          query = described_class.new(lead_provider: FactoryBot.create(:lead_provider))

          expect(query.statements).to be_empty
        end

        it "does not filter by `lead_provider` if an empty string is supplied" do
          query = described_class.new(lead_provider: " ")

          expect(query.statements).to contain_exactly(statement1, statement2, statement3)
        end
      end

      describe "by `registration_period_start_years`" do
        let!(:registration_period1) { FactoryBot.create(:registration_period) }
        let!(:registration_period2) { FactoryBot.create(:registration_period) }
        let!(:registration_period3) { FactoryBot.create(:registration_period) }

        context "when `registration_period_start_years` param is omitted" do
          it "returns all statements" do
            statement1 = FactoryBot.create(:statement, registration_period: registration_period1)
            statement2 = FactoryBot.create(:statement, registration_period: registration_period2)
            statement3 = FactoryBot.create(:statement, registration_period: registration_period3)

            expect(described_class.new.statements).to contain_exactly(statement1, statement2, statement3)
          end
        end

        it "filters by `registration_period_start_years`" do
          _statement = FactoryBot.create(:statement, registration_period: registration_period1)
          statement = FactoryBot.create(:statement, registration_period: registration_period2)
          query = described_class.new(registration_period_start_years: registration_period2.year)

          expect(query.statements).to eq([statement])
        end

        it "filters by multiple `registration_period_start_years`" do
          statement1 = FactoryBot.create(:statement, registration_period: registration_period1)
          statement2 = FactoryBot.create(:statement, registration_period: registration_period2)
          statement3 = FactoryBot.create(:statement, registration_period: registration_period3)

          query1 = described_class.new(registration_period_start_years: "#{registration_period1.year},#{registration_period2.year}")
          expect(query1.statements).to contain_exactly(statement1, statement2)

          query2 = described_class.new(registration_period_start_years: [registration_period2.year.to_s, registration_period3.year.to_s])
          expect(query2.statements).to contain_exactly(statement2, statement3)
        end

        it "returns no statements if no `registration_period_start_years` are found" do
          query = described_class.new(registration_period_start_years: "0000")

          expect(query.statements).to be_empty
        end

        it "does not filter by `registration_period_start_years` if blank" do
          statement1 = FactoryBot.create(:statement, registration_period: registration_period1)
          statement2 = FactoryBot.create(:statement, registration_period: registration_period2)

          query = described_class.new(registration_period_start_years: " ")

          expect(query.statements).to contain_exactly(statement1, statement2)
        end
      end

      describe "by `updated_since`" do
        let(:updated_since) { 1.day.ago }

        it "filters by `updated_since`" do
          FactoryBot.create(:statement, lead_provider:, updated_at: 2.days.ago)
          statement2 = FactoryBot.create(:statement, lead_provider:, updated_at: Time.zone.now)

          query = described_class.new(lead_provider:, updated_since:)

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

      describe "by `state`" do
        let!(:open_statement) { FactoryBot.create(:statement, :open) }
        let!(:payable_statement) { FactoryBot.create(:statement, :payable) }
        let!(:paid_statement) { FactoryBot.create(:statement, :paid) }

        it "filters by `state`" do
          expect(described_class.new(state: "open").statements).to eq([open_statement])
          expect(described_class.new(state: "payable").statements).to eq([payable_statement])
          expect(described_class.new(state: "paid").statements).to eq([paid_statement])
        end

        it "filters by multiple states with a comma separated list" do
          expect(described_class.new(state: "open,paid").statements).to contain_exactly(open_statement, paid_statement)
        end

        it "filters by multiple states with an array" do
          expect(described_class.new(state: %w[open paid]).statements).to contain_exactly(open_statement, paid_statement)
        end

        context "when `state` param is omitted" do
          it "returns all statements" do
            expect(described_class.new.statements).to contain_exactly(open_statement, payable_statement, paid_statement)
          end
        end

        it "does not filter by `state` if blank" do
          query = described_class.new(state: " ")

          expect(query.statements).to contain_exactly(open_statement, payable_statement, paid_statement)
        end
      end

      describe "by `output_fee`" do
        let!(:statement1) { FactoryBot.create(:statement, output_fee: true) }
        let!(:statement2) { FactoryBot.create(:statement, output_fee: false) }

        it "return only statements with `output_fee` true by default" do
          expect(described_class.new.statements).to eq([statement1])
        end

        context "when `output_fee``: 'false'" do
          it "return only statements with output fee false" do
            query = described_class.new(output_fee: "false")

            expect(query.statements).to eq([statement2])
          end
        end

        context "when `output_fee`: :ignore" do
          it "returns all statements" do
            query = described_class.new(output_fee: :ignore)

            expect(query.statements).to contain_exactly(statement1, statement2)
          end
        end

        it "does not filter by `output_fee` if blank" do
          query = described_class.new(output_fee: " ")

          expect(query.statements).to contain_exactly(statement1, statement2)
        end
      end
    end
  end

  describe "#statement" do
    let(:lead_provider) { FactoryBot.create(:lead_provider) }

    it "returns the statement for a Lead Provider" do
      statement = FactoryBot.create(:statement, lead_provider:)
      query = described_class.new

      expect(query.statement(api_id: statement.api_id)).to eq(statement)
      expect(query.statement(id: statement.id)).to eq(statement)
    end

    it "raises an error if the statement does not exist" do
      query = described_class.new

      expect { query.statement(api_id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
      expect { query.statement(id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the statement is not in the filtered query" do
      other_lead_provider = FactoryBot.create(:lead_provider)
      other_statement = FactoryBot.create(:statement, lead_provider: other_lead_provider)

      query = described_class.new(lead_provider:)

      expect { query.statement(api_id: other_statement.api_id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { query.statement(id: other_statement.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if neither an api_id or id is supplied" do
      expect { described_class.new.statement }.to raise_error(ArgumentError, "id or api_id needed")
    end
  end
end
