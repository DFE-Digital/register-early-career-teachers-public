describe Migrators::Declaration do
  def create_declaration_from(participant_declaration)
    FactoryBot.create(:declaration, **create_training_period_and_statements_for(participant_declaration))
  end

  def create_participant_declaration
    FactoryBot.create(:migration_participant_declaration, :refundable)
  end

  def create_training_period_and_statements_for(participant_declaration)
    training_period = create_training_period_for(participant_declaration)
    active_lead_provider = training_period.school_partnership.lead_provider_delivery_partnership.active_lead_provider
    contract_period = active_lead_provider.contract_period

    {
      training_period:,
      payment_statement: FactoryBot.create(:statement, status: "paid", contract_period:, active_lead_provider:, api_id: participant_declaration.payment_statement.id),
      clawback_statement: FactoryBot.create(:statement, status: "paid", contract_period:, active_lead_provider:, api_id: participant_declaration.clawback_statement.id)
    }
  end

  def create_training_period_for(participant_declaration)
    ecf_lead_provider = participant_declaration.cpd_lead_provider.lead_provider
    lead_provider = FactoryBot.create(:lead_provider, ecf_id: ecf_lead_provider.id, name: ecf_lead_provider.name)
    delivery_partner = FactoryBot.create(:delivery_partner)
    contract_period = FactoryBot.create(:contract_period, year: participant_declaration.cohort.start_year)
    active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
    school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)

    if participant_declaration.participant_profile.ect?
      teacher = FactoryBot.create(:teacher, api_ect_training_record_id: participant_declaration.participant_profile_id)
      ect_at_school_period = FactoryBot.create(:ect_at_school_period, teacher:, school: school_partnership.school)
      FactoryBot.create(:training_period, :for_ect, school_partnership:, ect_at_school_period:)
    else
      teacher = FactoryBot.create(:teacher, api_mentor_training_record_id: participant_declaration.participant_profile_id)
      mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, teacher:, school: school_partnership.school)
      FactoryBot.create(:training_period, :for_mentor, school_partnership:, mentor_at_school_period:)
    end
  end

  before do
    stub_const("Migrators::Declaration::SPECIAL_DECLARATIONS_PATH", "spec/fixtures/special_declarations.csv")
  end

  it_behaves_like "a migrator", :declaration, %i[statement mentor ect] do
    def create_migration_resource = create_participant_declaration

    # creating dependencies resources
    def create_resource(migration_resource) = create_declaration_from(migration_resource)

    # Record to be migrated with unmet dependencies in the destination db
    def setup_failure_state
      FactoryBot.create(:migration_participant_declaration)
    end
  end

  describe "#migrate!" do
    let(:instance) { described_class.new(worker: 0) }
    let!(:data_migration) { FactoryBot.create(:data_migration, model: :declaration, worker: 0) }

    before { instance.send(:cache_manager).clear_all_caches! }

    context "when the declaration is not related to an ERO mentor" do
      let(:clawback_statement) { Statement.find_by_api_id(participant_declaration.clawback_statement.id) }
      let(:payment_statement) { Statement.find_by_api_id(participant_declaration.payment_statement.id) }
      let(:ecf_lead_provider_id) { participant_declaration.cpd_lead_provider.lead_provider.id }

      context "when the declaration is not a special one" do
        let!(:participant_declaration) { create_participant_declaration }
        let!(:training_period) { create_training_period_and_statements_for(participant_declaration)[:training_period] }

        it "sets the created declaration attributes correctly" do
          instance.migrate!

          declaration = Declaration.find_by(api_id: participant_declaration.id)

          aggregate_failures do
            expect(declaration).to have_attributes(participant_declaration.attributes.slice("created_at", "declaration_date", "declaration_type", "evidence_type", "updated_at"))
            expect(declaration.pupil_premium_uplift).to be_falsey
            expect(declaration.sparsity_uplift).to be_falsey
            expect(declaration.clawback_statement_id).to eq(clawback_statement.id)
            expect(declaration.clawback_status).to eq(participant_declaration.clawback_status)
            expect(declaration.delivery_partner_when_created.id).to eq(training_period.delivery_partner.id)
            expect(declaration.lead_provider.ecf_id).to eq(ecf_lead_provider_id)
            expect(declaration.payment_statement_id).to eq(payment_statement.id)
            expect(declaration.payment_status).to eq(participant_declaration.payment_status)
            expect(declaration.training_period_id).to eq(training_period.id)
            expect(declaration.voided_by_user_at).to eq(participant_declaration.voided_at)
          end
        end
      end

      context "when the declaration is a special one that can't be associated with any existing training_period" do
        let!(:school) { FactoryBot.create(:school, urn: 149_712, create_contract_period: false) }
        let!(:ecf_school) { FactoryBot.create(:ecf_migration_school, urn: 149_712) }
        let!(:cohort) { FactoryBot.create(:migration_cohort) }
        let!(:school_cohort) { FactoryBot.create(:migration_school_cohort, cohort:, school: ecf_school) }
        let!(:participant_profile) { FactoryBot.create(:migration_participant_profile, :ect, school_cohort:) }
        let!(:participant_declaration) { FactoryBot.create(:migration_participant_declaration, :billable, id: "05e09502-f3ef-4f89-aa1a-e17a120df7dc", participant_profile:, cohort:, declaration_type: :completed) }
        let!(:ecf_lead_provider) { participant_declaration.cpd_lead_provider.lead_provider }
        let!(:teacher) { FactoryBot.create(:teacher, api_ect_training_record_id: participant_declaration.participant_profile_id) }
        let!(:lead_provider) { FactoryBot.create(:lead_provider, ecf_id: ecf_lead_provider.id, name: ecf_lead_provider.name) }
        let!(:contract_period) { FactoryBot.create(:contract_period, year: participant_declaration.cohort.start_year) }
        let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
        let!(:delivery_partner) { FactoryBot.create(:delivery_partner, api_id: "cdb6cef0-5128-4f53-877c-37d70634e82a", name: "DP173") }
        let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
        let!(:schedule) { FactoryBot.create(:schedule, contract_period:) }
        let!(:payment_statement) { FactoryBot.create(:statement, :payable, api_id: participant_declaration.payment_statement.id, contract_period:) }

        let(:started_on) { Date.new(contract_period.year, 9, 1) }
        let(:finished_on) { Date.new(contract_period.year, 9, 2) }

        context "when no school periods overlap the new one and no school partnership to reuse" do
          it "sets the created declaration attributes correctly" do
            instance.migrate!

            declaration = Declaration.find_by(api_id: participant_declaration.id)
            training_period = declaration.training_period
            at_school_period = training_period.ect_at_school_period
            school_partnership = training_period.school_partnership

            aggregate_failures do
              expect(declaration).to have_attributes(participant_declaration.attributes.slice("created_at", "declaration_date", "declaration_type", "evidence_type", "updated_at"))
              expect(declaration.clawback_status).to eq(participant_declaration.clawback_status)
              expect(declaration.delivery_partner_when_created.id).to eq(delivery_partner.id)
              expect(declaration.lead_provider.ecf_id).to eq(ecf_lead_provider_id)
              expect(declaration.payment_statement_id).to eq(payment_statement.id)
              expect(declaration.payment_status).to eq(participant_declaration.payment_status)
              expect(declaration.training_period_id).to be_present
              expect(declaration.voided_by_user_at).to eq(participant_declaration.voided_at)

              expect(at_school_period.started_on).to eq(started_on)
              expect(at_school_period.finished_on).to eq(finished_on)
              expect(at_school_period.school).to eq(school)

              expect(training_period.started_on).to eq(started_on)
              expect(training_period.finished_on).to eq(finished_on)
              expect(training_period.schedule.contract_period_year).to eq(contract_period.year)
              expect(training_period.schedule.identifier).to eq("ecf-standard-september")

              expect(school_partnership.school).to eq(school)
              expect(school_partnership.lead_provider).to eq(lead_provider)
              expect(school_partnership.delivery_partner).to eq(delivery_partner)
              expect(school_partnership.contract_period).to eq(contract_period)
            end
          end
        end

        context "when an existing teacher at school period overlaps with the new one to be created" do
          before do
            FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on:, finished_on:)
          end

          it "creates the ect_at_school_period and training_period immediately before the clashing period" do
            instance.migrate!

            declaration = Declaration.find_by(api_id: participant_declaration.id)
            training_period = declaration.training_period
            at_school_period = training_period.ect_at_school_period

            aggregate_failures do
              expect(at_school_period.started_on).to eq(started_on - 2.days)
              expect(at_school_period.finished_on).to eq(finished_on - 2.days)
              expect(at_school_period.school).to eq(school)

              expect(training_period.started_on).to eq(started_on - 2.days)
              expect(training_period.finished_on).to eq(finished_on - 2.days)
            end
          end
        end

        context "when a school partnerships for the new training period already exists" do
          let!(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

          it "reuses that school partnership" do
            instance.migrate!

            declaration = Declaration.find_by(api_id: participant_declaration.id)
            training_period = declaration.training_period

            expect(training_period.school_partnership).to eq(school_partnership)
          end
        end
      end
    end

    context "when the declaration belongs to an ERO mentor" do
      let(:mentor_profile) { mentor_declaration.participant_profile }
      let!(:ineligible_entry) { FactoryBot.create(:migration_ecf_ineligible_participant, trn: mentor_profile.teacher_profile.trn) }

      context "when the declaration is not in an excluded state" do
        let!(:mentor_declaration) { FactoryBot.create(:migration_participant_declaration, :mentor, :billable) }
        let!(:training_period) { create_training_period_for(mentor_declaration) }

        let!(:statement) do
          FactoryBot.create(:statement, status: "payable", contract_period: training_period.contract_period,
                                        active_lead_provider: training_period.school_partnership.active_lead_provider,
                                        api_id: mentor_declaration.payment_statement.id)
        end

        it "migrates the declaration" do
          expect {
            instance.migrate!
          }.to change { training_period.declarations.count }.by(1)
        end
      end

      context "when the declaration has voided state" do
        let!(:mentor_declaration) { FactoryBot.create(:migration_participant_declaration, :mentor, state: "voided") }
        let!(:training_period) { create_training_period_for(mentor_declaration) }

        it "does not migrate the declaration" do
          expect {
            instance.migrate!
          }.not_to(change { training_period.declarations.count })
        end
      end

      context "when the declaration has submitted state" do
        let!(:mentor_declaration) { FactoryBot.create(:migration_participant_declaration, :mentor, state: "submitted") }
        let!(:training_period) { create_training_period_for(mentor_declaration) }
        let(:state) { "submitted" }

        it "does not migrate the declaration" do
          expect {
            instance.migrate!
          }.not_to(change { training_period.declarations.count })
        end
      end
    end
  end
end
