RSpec.describe Statements::Search do
  describe "#statements" do
    let(:lead_provider) { FactoryBot.create(:lead_provider) }

    it "returns all statements" do
      statement = FactoryBot.create(:statement)
      search = described_class.new

      expect(search.statements).to eq([statement])
    end

    it "orders statements by payment date in ascending order" do
      statement1 = FactoryBot.create(:statement, payment_date: 2.days.ago)
      statement2 = FactoryBot.create(:statement, payment_date: 1.day.ago)
      statement3 = FactoryBot.create(:statement, payment_date: Time.zone.now)

      search = described_class.new

      expect(search.statements).to eq([statement1, statement2, statement3])
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
          search = described_class.new(lead_provider_id: lead_provider.id)

          expect(search.statements).to eq([statement1])
        end

        it "returns no statements if no statements are found for the given `lead_provider`" do
          search = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

          expect(search.statements).to be_empty
        end

        it "does not filter by `lead_provider` if an empty string is supplied" do
          search = described_class.new(lead_provider_id: " ")

          expect(search.statements).to contain_exactly(statement1, statement2, statement3)
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
          search = described_class.new(contract_period_years: contract_period2.year)

          expect(search.statements).to eq([statement])
        end

        it "filters by multiple `contract_period_years`" do
          statement1 = FactoryBot.create(:statement, contract_period: contract_period1)
          statement2 = FactoryBot.create(:statement, contract_period: contract_period2)
          statement3 = FactoryBot.create(:statement, contract_period: contract_period3)

          search1 = described_class.new(contract_period_years: [contract_period1.year, contract_period2.year])
          expect(search1.statements).to contain_exactly(statement1, statement2)

          search2 = described_class.new(contract_period_years: [contract_period2.year.to_s, contract_period3.year.to_s])
          expect(search2.statements).to contain_exactly(statement2, statement3)
        end

        it "returns no statements if no `contract_period_years` are found" do
          search = described_class.new(contract_period_years: "0000")

          expect(search.statements).to be_empty
        end

        it "does not filter by `contract_period_years` if blank" do
          statement1 = FactoryBot.create(:statement, contract_period: contract_period1)
          statement2 = FactoryBot.create(:statement, contract_period: contract_period2)

          search = described_class.new(contract_period_years: " ")

          expect(search.statements).to contain_exactly(statement1, statement2)
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
            search = described_class.new(fee_type: "output")

            expect(search.statements).to eq([statement1])
          end
        end

        context "when `fee_type`: 'service'" do
          it "return only statements with fee type of service" do
            search = described_class.new(fee_type: "service")

            expect(search.statements).to eq([statement2])
          end
        end

        context "when `output_fee`: :ignore" do
          it "returns all statements" do
            search = described_class.new(fee_type: :ignore)

            expect(search.statements).to contain_exactly(statement1, statement2)
          end
        end

        it "does not filter by `output_fee` if blank" do
          search = described_class.new(fee_type: " ")

          expect(search.statements).to contain_exactly(statement1, statement2)
        end

        it "raises an error when searching by an invalid fee type" do
          expect { described_class.new(fee_type: "something_else") }.to raise_error(Statements::Search::InvalidFeeTypeError)
        end
      end

      describe "by `statement_date`" do
        let!(:statement1) { FactoryBot.create(:statement, year: 2025, month: 4) }
        let!(:statement2) { FactoryBot.create(:statement, year: 2024, month: 8) }

        it "returns statement1 for 2025-04" do
          search = described_class.new(statement_date: "2025-04")
          expect(search.statements).to eq([statement1])
        end

        it "returns statement2 for 2024-04" do
          search = described_class.new(statement_date: "2024-08")
          expect(search.statements).to eq([statement2])
        end

        it "returns empty for 2021-01" do
          search = described_class.new(statement_date: "2021-01")
          expect(search.statements).to be_empty
        end

        context "when filter should be ignored" do
          it "returns all statements when value is :ignore" do
            search = described_class.new(statement_date: :ignore)
            expect(search.statements).to contain_exactly(statement1, statement2)
          end

          it "returns all statements when value is blank" do
            search = described_class.new(statement_date: " ")
            expect(search.statements).to contain_exactly(statement1, statement2)
          end

          it "returns all statements when value is nil" do
            search = described_class.new(statement_date: nil)
            expect(search.statements).to contain_exactly(statement1, statement2)
          end
        end
      end

      describe "by `deadline_date`" do
        let!(:statement1) { FactoryBot.create(:statement, deadline_date: Date.new(2025, 7, 1)) }
        let!(:statement2) { FactoryBot.create(:statement, deadline_date: Date.new(2025, 9, 1)) }

        it "returns all statements for 2025-07-01" do
          search = described_class.new(deadline_date: "2025-07-01")
          expect(search.statements).to contain_exactly(statement1, statement2)
        end

        it "returns statement2 for 2025-08-01" do
          search = described_class.new(deadline_date: "2025-08-01")
          expect(search.statements).to eq([statement2])
        end

        it "returns empty for 2025-10-01" do
          search = described_class.new(deadline_date: "2025-10-01")
          expect(search.statements).to be_empty
        end

        context "when filter should be ignored" do
          it "returns all statements when value is :ignore" do
            search = described_class.new(deadline_date: :ignore)
            expect(search.statements).to contain_exactly(statement1, statement2)
          end

          it "returns all statements when value is blank" do
            search = described_class.new(deadline_date: " ")
            expect(search.statements).to contain_exactly(statement1, statement2)
          end

          it "returns all statements when value is nil" do
            search = described_class.new(deadline_date: nil)
            expect(search.statements).to contain_exactly(statement1, statement2)
          end
        end
      end
    end

    describe "ordering" do
      let!(:statement1) { FactoryBot.create(:statement, year: 2025, month: 4, payment_date: "2024-01-01", deadline_date: "2025-01-01") }
      let!(:statement2) { FactoryBot.create(:statement, year: 2024, month: 8, payment_date: "2025-01-01", deadline_date: "2024-01-01") }

      describe "default order" do
        it "returns statements in correct order" do
          search = described_class.new
          expect(search.statements).to eq([statement1, statement2])
        end
      end

      describe "sort by payment_date" do
        it "returns statements in correct order" do
          search = described_class.new(order: :payment_date)
          expect(search.statements).to eq([statement1, statement2])
        end
      end

      describe "sort by year and month" do
        it "returns statements in correct order" do
          search = described_class.new(order: :statement_date)
          expect(search.statements).to eq([statement2, statement1])
        end
      end

      describe "sort by `deadline_date`" do
        it "returns statements in correct order" do
          search = described_class.new(order: :deadline_date)
          expect(search.statements).to eq([statement2, statement1])
        end
      end
    end
  end
end
