RSpec.describe API::Declarations::Query do
  def create_training_period(trainee:, contract_period: nil, teacher: nil, following_on_from_training_period: nil, delivery_partner: nil)
    school_partnership = FactoryBot.create(:school_partnership, :for_year, year: contract_period&.year || Date.current.year)
    school_partnership.lead_provider_delivery_partnership.update!(delivery_partner:) if delivery_partner
    trait = trainee == :ect ? :for_ect : :for_mentor

    if following_on_from_training_period
      previous_finished_on = following_on_from_training_period.started_on + rand(10..100).days
      following_on_from_training_period.update!(finished_on: previous_finished_on)
      school_period = following_on_from_training_period.trainee

      FactoryBot.create(:training_period, trait, :ongoing, school_partnership:, started_on: previous_finished_on, "#{trainee}_at_school_period": school_period)
    else
      teacher ||= FactoryBot.create(:teacher)
      school_period = FactoryBot.create(:"#{trainee}_at_school_period", :ongoing, teacher:)
      FactoryBot.create(:training_period, trait, :ongoing, school_partnership:, "#{trainee}_at_school_period": school_period)
    end
  end

  def create_declaration(declaration_type: "started", contract_period: nil, training_period: nil, status: nil, declaration_date: nil)
    contract_period ||= FactoryBot.create(:contract_period)
    training_period ||= create_training_period(contract_period:, trainee: :ect)
    declaration_date ||= training_period.started_on.next_day
    FactoryBot.create(
      :declaration,
      status,
      training_period:,
      declaration_type:,
      declaration_date:
    )
  end

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

          # Previous training period with `lead_provider1`
          let(:training_period1) { create_training_period(contract_period:, trainee: :ect) }
          let(:lead_provider1) { training_period1.lead_provider }

          # Current training period with `lead_provider2`
          let(:training_period2) { create_training_period(contract_period:, trainee: :ect, following_on_from_training_period: training_period1) }
          let(:lead_provider2) { training_period2.lead_provider }

          # New ongoing training period with `lead_provider3`
          let(:training_period3) { create_training_period(contract_period:, trainee: :ect, following_on_from_training_period: training_period2) }
          let(:lead_provider3) { training_period3.lead_provider }

          # Declaration for each training period
          let!(:declaration1) { create_declaration(training_period: training_period1, declaration_type: "started") }
          let!(:declaration2) { create_declaration(training_period: training_period2, declaration_type: "retained-1") }
          let!(:declaration3) { create_declaration(training_period: training_period3, declaration_type: "retained-3") }

          # Additional unrelated declaration
          before { FactoryBot.create(:declaration) }

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

          %i[voided ineligible awaiting_clawback clawed_back].each do |ignored_status|
            context "when previous declaration is `#{ignored_status}`" do
              let!(:declaration1) { create_declaration(training_period: training_period1, declaration_type: "started", status: ignored_status) }

              it "returns only the direct declaration" do
                query = described_class.new(lead_provider_id: lead_provider2.id)

                expect(query.declarations).to contain_exactly(declaration2)
              end
            end
          end

          context "when declaration submitted after all the training period started on date" do
            let!(:declaration5) do
              create_declaration(
                training_period: training_period1,
                declaration_type: "retained-3",
                declaration_date: training_period3.started_on.next_day
              )
            end

            it "lead_provider3 should return direct and previous declarations" do
              query = described_class.new(lead_provider_id: lead_provider3.id)

              expect(query.declarations).to contain_exactly(declaration1, declaration2, declaration3, declaration5)
            end
          end

          context "when teacher has previous ECT declarations, however the lead provider is only associated with their mentor training" do
            # ECT teacher for `training_period1` will be a mentor with a new lead provider `lead_provider4`
            let(:teacher) { training_period1.trainee.teacher }
            let(:mentor_training_period) { create_training_period(contract_period:, trainee: :mentor, teacher:) }
            let(:lead_provider4) { mentor_training_period.lead_provider }
            let!(:mentor_declaration) { create_declaration(training_period: mentor_training_period, declaration_type: "started") }

            it "does not return previous ECT declarations, only mentor declaration" do
              query = described_class.new(lead_provider_id: lead_provider4.id)

              expect(query.declarations).to contain_exactly(mentor_declaration)
            end
          end
        end
      end

      describe "by `contract_period_years`" do
        let(:contract_period1) { FactoryBot.create(:contract_period) }
        let(:contract_period2) { FactoryBot.create(:contract_period) }
        let(:contract_period3) { FactoryBot.create(:contract_period) }

        let!(:declaration1) { create_declaration(contract_period: contract_period1) }
        let!(:declaration2) { create_declaration(contract_period: contract_period2) }
        let!(:declaration3) { create_declaration(contract_period: contract_period3) }

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

        let(:training_period1) { create_training_period(trainee: :ect, teacher: teacher1) }
        let(:training_period2) { create_training_period(trainee: :ect, teacher: teacher2) }

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

        let(:training_period1) { create_training_period(trainee: :ect, delivery_partner: delivery_partner1) }
        let(:training_period2) { create_training_period(trainee: :mentor, delivery_partner: delivery_partner2) }

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
