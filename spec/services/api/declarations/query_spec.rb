RSpec.describe API::Declarations::Query do
  it_behaves_like "a query that avoids includes" do
    before { FactoryBot.create(:declaration) }
  end

  describe "preloading relationships" do
    shared_examples "preloaded associations" do
      it { expect(result.association(:training_period)).to be_loaded }
    end

    let(:instance) { described_class.new }
    let!(:declaration) { FactoryBot.create(:declaration) }

    describe "#declarations" do
      subject(:result) { instance.declarations.first }

      include_context "preloaded associations"
    end

    describe "#declaration_by_api_id" do
      subject(:result) { instance.declaration_by_api_id(declaration.api_id) }

      include_context "preloaded associations"
    end

    describe "#declaration_by_id" do
      subject(:result) { instance.declaration_by_id(declaration.id) }

      include_context "preloaded associations"
    end
  end

  describe "#declarations" do
    let(:instance) { described_class.new }

    it "returns all declarations" do
      declarations = FactoryBot.create_list(:declaration, 3)

      expect(instance.declarations).to match_array(declarations)
    end

    it "accepts a block for additional scoping" do
      declarations = FactoryBot.create_list(:declaration, 3)

      result = instance.declarations { |scope| scope.limit(1) }

      expect(result.size).to eq(1)
      expect(declarations).to include(result.first)
    end

    describe "filtering" do
      describe "by `lead_provider_id`" do
        let(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing) }
        let(:lead_provider_id) { training_period.lead_provider.id }

        let!(:declaration1) { FactoryBot.create(:declaration, training_period:) }
        let!(:declaration2) { FactoryBot.create(:declaration) }
        let!(:declaration3) { FactoryBot.create(:declaration) }

        context "when `lead_provider_id` param is omitted" do
          it "returns all declarations" do
            expect(instance.declarations).to contain_exactly(declaration1, declaration2, declaration3)
          end
        end

        it "filters by `lead_provider_id`" do
          query = described_class.new(lead_provider_id:)

          expect(query.declarations).to contain_exactly(declaration1)
        end

        it "returns empty if no declarations are found for the given `lead_provider_id`" do
          query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

          expect(query.declarations).to be_empty
        end

        it "does not filter by `lead_provider_id` if an empty string is supplied" do
          query = described_class.new(lead_provider_id: " ")

          expect(query.declarations).to contain_exactly(declaration1, declaration2, declaration3)
        end

        context "when there are declarations from previous lead provider" do
          let(:contract_period) { FactoryBot.create(:contract_period) }

          # Previous lead provider
          let(:lead_provider1) { FactoryBot.create(:lead_provider) }
          let(:active_lead_provider1) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider1, contract_period:) }
          let(:lead_provider_delivery_partnership1) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider1) }
          let(:school_partnership1) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership1) }

          # Current lead provider
          let(:lead_provider2) { FactoryBot.create(:lead_provider) }
          let(:active_lead_provider2) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider2, contract_period:) }
          let(:lead_provider_delivery_partnership2) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider2) }
          let(:school_partnership2) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership2) }

          # New lead provider
          let(:lead_provider3) { FactoryBot.create(:lead_provider) }
          let(:active_lead_provider3) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider3, contract_period:) }
          let(:lead_provider_delivery_partnership3) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider3) }
          let(:school_partnership3) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership3) }

          # Previous training period
          let(:training_period1) { FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership: school_partnership1) }
          let(:ect_at_school_period) { training_period1.ect_at_school_period }

          # Current training period
          let(:prev_finished_on) { training_period1.started_on + rand(100).days }
          let(:training_period2) do
            # set previous training period to end
            training_period1.update!(finished_on: prev_finished_on)

            FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: prev_finished_on, school_partnership: school_partnership2)
          end

          # New training period
          let(:curr_finished_on) { training_period2.started_on + rand(100).days }
          let(:training_period3) do
            # set current training period to end
            training_period2.update!(finished_on: curr_finished_on)

            FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: curr_finished_on, school_partnership: school_partnership3)
          end

          # Declaration for each training period
          let!(:declaration1) do
            FactoryBot.create(
              :declaration,
              training_period: training_period1,
              declaration_type: "started",
              declaration_date: training_period1.started_on.next_day
            )
          end
          let!(:declaration2) do
            FactoryBot.create(
              :declaration,
              training_period: training_period2,
              declaration_type: "retained-1",
              declaration_date: training_period2.started_on.next_day
            )
          end
          let!(:declaration3) do
            FactoryBot.create(
              :declaration,
              training_period: training_period3,
              declaration_type: "retained-2",
              declaration_date: training_period3.started_on.next_day
            )
          end
          # Additional unrelated declaration
          let!(:declaration4) { FactoryBot.create(:declaration) }

          context "when lead_provider2 has previous and direct declaration" do
            it "returns previous declarations and direct declarations for lead_provider2" do
              query = described_class.new(lead_provider_id: lead_provider2.id)

              expect(query.declarations).to contain_exactly(declaration1, declaration2)
            end
          end

          context "when previous declaration is submitted after training_period2.finished_on date" do
            before { declaration1.update!(declaration_date: training_period2.finished_on.next_day) }

            it "returns only the direct declaration" do
              query = described_class.new(lead_provider_id: lead_provider2.id)

              expect(query.declarations).to contain_exactly(declaration2)
            end
          end

          context "when previous declaration is voided" do
            let!(:declaration1) do
              FactoryBot.create(
                :declaration,
                :voided,
                training_period: training_period1,
                declaration_type: "started",
                declaration_date: training_period1.started_on.next_day
              )
            end

            it "returns only the direct declaration" do
              query = described_class.new(lead_provider_id: lead_provider2.id)

              expect(query.declarations).to contain_exactly(declaration2)
            end
          end

          context "when declaration submitted after all the training period started on date" do
            let!(:declaration5) do
              FactoryBot.create(
                :declaration,
                training_period: training_period1,
                declaration_type: "retained-3",
                declaration_date: training_period1.started_on.next_day
              )
            end

            it "lead_provider3 should return direct and previous declarations" do
              query = described_class.new(lead_provider_id: lead_provider3.id)

              expect(query.declarations).to contain_exactly(declaration1, declaration2, declaration3, declaration5)
            end
          end
        end
      end

      describe "by `contract_period_years`" do
        def create_declaration_for_contract_period(contract_period:)
          active_lead_provider = FactoryBot.create(:active_lead_provider, contract_period:)
          lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
          school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
          training_period = FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership:)
          FactoryBot.create(:declaration, training_period:)
        end

        let(:contract_period1) { FactoryBot.create(:contract_period) }
        let(:contract_period2) { FactoryBot.create(:contract_period) }
        let(:contract_period3) { FactoryBot.create(:contract_period) }

        let!(:declaration1) { create_declaration_for_contract_period(contract_period: contract_period1) }
        let!(:declaration2) { create_declaration_for_contract_period(contract_period: contract_period2) }
        let!(:declaration3) { create_declaration_for_contract_period(contract_period: contract_period3) }

        context "when `contract_period_years` param is omitted" do
          it "returns all declarations" do
            expect(instance.declarations).to contain_exactly(declaration1, declaration2, declaration3)
          end
        end

        it "filters by `contract_period_years`" do
          query = described_class.new(contract_period_years: contract_period2.year)

          expect(query.declarations).to contain_exactly(declaration2)
        end

        it "filters by multiple `contract_period_years`" do
          query = described_class.new(contract_period_years: [contract_period1.year, contract_period2.year])

          expect(query.declarations).to contain_exactly(declaration1, declaration2)
        end

        it "returns no declarations if no `contract_period_years` are found" do
          query = described_class.new(contract_period_years: "0000")

          expect(query.declarations).to be_empty
        end

        it "returns no declarations if `contract_period_years` is an empty array" do
          query = described_class.new(contract_period_years: [])

          expect(query.declarations).to be_empty
        end

        it "does not filter by `contract_period_years` if blank" do
          query = described_class.new(contract_period_years: " ")

          expect(query.declarations).to contain_exactly(declaration1, declaration2, declaration3)
        end
      end

      describe "by `teacher_api_ids`" do
        let(:teacher1) { FactoryBot.create(:teacher) }
        let(:teacher2) { FactoryBot.create(:teacher) }
        let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher: teacher1) }
        let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher: teacher2) }
        let(:training_period1) { FactoryBot.create(:training_period, :for_ect, :ongoing, ect_at_school_period:) }
        let(:training_period2) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:) }

        let!(:declaration1) { FactoryBot.create(:declaration, training_period: training_period1) }
        let!(:declaration2) { FactoryBot.create(:declaration, training_period: training_period2) }
        let!(:declaration3) { FactoryBot.create(:declaration) }

        context "when `teacher_api_ids` param is omitted" do
          it "returns all declarations" do
            expect(instance.declarations).to contain_exactly(declaration1, declaration2, declaration3)
          end
        end

        it "filters by `teacher_api_ids` for ECT" do
          query = described_class.new(teacher_api_ids: teacher1.api_id)

          expect(query.declarations).to contain_exactly(declaration1)
        end

        it "filters by `teacher_api_ids` for mentor" do
          query = described_class.new(teacher_api_ids: teacher2.api_id)

          expect(query.declarations).to contain_exactly(declaration2)
        end

        it "filters by multiple `teacher_api_ids`" do
          query = described_class.new(teacher_api_ids: [teacher1.api_id, teacher2.api_id])

          expect(query.declarations).to contain_exactly(declaration1, declaration2)
        end

        it "returns empty if no declarations are found for the given `teacher_api_ids`" do
          query = described_class.new(teacher_api_ids: FactoryBot.create(:teacher).api_id)

          expect(query.declarations).to be_empty
        end

        it "does not filter by `teacher_api_ids` if an empty string is supplied" do
          query = described_class.new(teacher_api_ids: " ")

          expect(query.declarations).to contain_exactly(declaration1, declaration2, declaration3)
        end
      end

      describe "by `delivery_partner_api_ids`" do
        let(:delivery_partner1) { FactoryBot.create(:delivery_partner) }
        let(:delivery_partner2) { FactoryBot.create(:delivery_partner) }
        let(:lead_provider_delivery_partnership1) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: delivery_partner1) }
        let(:lead_provider_delivery_partnership2) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: delivery_partner2) }
        let(:school_partnership1) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership1) }
        let(:school_partnership2) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership2) }
        let(:training_period1) { FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership: school_partnership1) }
        let(:training_period2) { FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership: school_partnership2) }

        let!(:declaration1) { FactoryBot.create(:declaration, training_period: training_period1) }
        let!(:declaration2) { FactoryBot.create(:declaration, training_period: training_period2) }
        let!(:declaration3) { FactoryBot.create(:declaration) }

        context "when `delivery_partner_api_ids` param is omitted" do
          it "returns all declarations" do
            expect(instance.declarations).to contain_exactly(declaration1, declaration2, declaration3)
          end
        end

        it "filters by `delivery_partner_api_ids`" do
          query = described_class.new(delivery_partner_api_ids: delivery_partner1.api_id)

          expect(query.declarations).to contain_exactly(declaration1)
        end

        it "filters by multiple `delivery_partner_api_ids`" do
          query = described_class.new(delivery_partner_api_ids: [delivery_partner1.api_id, delivery_partner2.api_id])

          expect(query.declarations).to contain_exactly(declaration1, declaration2)
        end

        it "returns empty if no declarations are found for the given `delivery_partner_api_ids`" do
          query = described_class.new(delivery_partner_api_ids: FactoryBot.create(:delivery_partner).api_id)

          expect(query.declarations).to be_empty
        end

        it "does not filter by `delivery_partner_api_ids` if an empty string is supplied" do
          query = described_class.new(delivery_partner_api_ids: " ")

          expect(query.declarations).to contain_exactly(declaration1, declaration2, declaration3)
        end
      end

      describe "by `updated_since`" do
        it "filters by `updated_since`" do
          FactoryBot.create(:declaration).tap { it.update(updated_at: 2.days.ago) }
          declaration2 = FactoryBot.create(:declaration)

          query = described_class.new(updated_since: 1.day.ago)

          expect(query.declarations).to contain_exactly(declaration2)
        end

        it "does not filter by `updated_since` if omitted" do
          declaration1 = FactoryBot.create(:declaration).tap { it.update(updated_at: 1.week.ago) }
          declaration2 = FactoryBot.create(:declaration).tap { it.update(updated_at: 2.weeks.ago) }

          expect(instance.declarations).to contain_exactly(declaration1, declaration2)
        end

        it "does not filter by `updated_since` if blank" do
          declaration1 = FactoryBot.create(:declaration).tap { it.update(updated_at: 1.week.ago) }
          declaration2 = FactoryBot.create(:declaration).tap { it.update(updated_at: 2.weeks.ago) }

          query = described_class.new(updated_since: " ")

          expect(query.declarations).to contain_exactly(declaration1, declaration2)
        end
      end
    end
  end

  describe "#declaration_by_api_id" do
    let(:instance) { described_class.new }

    it "returns the declaration for a given api_id" do
      declaration = FactoryBot.create(:declaration)

      expect(instance.declaration_by_api_id(declaration.api_id)).to eq(declaration)
    end

    it "raises an error if the declaration does not exist" do
      expect { instance.declaration_by_api_id(SecureRandom.uuid) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the declaration is not in the filtered query" do
      declaration1 = FactoryBot.create(:declaration)
      declaration2 = FactoryBot.create(:declaration)

      query = described_class.new(delivery_partner_api_ids: declaration1.delivery_partner.api_id)

      expect { query.declaration_by_api_id(declaration2.api_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an api_id is not supplied" do
      expect { instance.declaration_by_api_id(nil) }.to raise_error(ArgumentError, "api_id needed")
    end
  end

  describe "#declaration_by_id" do
    let(:instance) { described_class.new }

    it "returns the declaration for a given id" do
      declaration = FactoryBot.create(:declaration)

      expect(instance.declaration_by_id(declaration.id)).to eq(declaration)
    end

    it "raises an error if the declaration does not exist" do
      expect { instance.declaration_by_id(SecureRandom.uuid) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the declaration is not in the filtered query" do
      declaration1 = FactoryBot.create(:declaration)
      declaration2 = FactoryBot.create(:declaration)

      query = described_class.new(delivery_partner_api_ids: declaration1.delivery_partner.api_id)

      expect { query.declaration_by_id(declaration2.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an id is not supplied" do
      expect { instance.declaration_by_id(nil) }.to raise_error(ArgumentError, "id needed")
    end
  end
end
