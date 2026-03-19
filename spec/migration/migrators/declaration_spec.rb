describe Migrators::Declaration do
  def create_declaration_from(participant_declaration)
    FactoryBot.create(:declaration, **create_training_period_and_statements_for(participant_declaration))
  end

  def create_participant_declaration
    FactoryBot.create(:migration_participant_declaration, :refundable)
  end

  def create_training_period_and_statements_for(participant_declaration, started_on: nil)
    started_on ||= participant_declaration.declaration_date
    training_period = create_training_period_for(participant_declaration, started_on:)
    active_lead_provider = training_period.school_partnership.lead_provider_delivery_partnership.active_lead_provider
    contract_period = active_lead_provider.contract_period

    {
      training_period:,
      payment_statement: FactoryBot.create(:statement, status: "paid", contract_period:, active_lead_provider:, api_id: participant_declaration.payment_statement.id),
      clawback_statement: FactoryBot.create(:statement, status: "paid", contract_period:, active_lead_provider:, api_id: participant_declaration.clawback_statement.id)
    }
  end

  def create_training_period_for(participant_declaration, started_on: nil)
    ecf_lead_provider = participant_declaration.cpd_lead_provider.lead_provider
    lead_provider = FactoryBot.create(:lead_provider, ecf_id: ecf_lead_provider.id, name: ecf_lead_provider.name)
    delivery_partner = FactoryBot.create(:delivery_partner, api_id: participant_declaration.delivery_partner_id)
    contract_period = FactoryBot.create(:contract_period, year: participant_declaration.cohort.start_year)
    active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
    school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
    started_on ||= participant_declaration.declaration_date

    if participant_declaration.participant_profile.ect?
      teacher = FactoryBot.create(:teacher, api_ect_training_record_id: participant_declaration.participant_profile_id)
      ect_at_school_period = FactoryBot.create(:ect_at_school_period, teacher:, school: school_partnership.school, started_on:)
      FactoryBot.create(:training_period, :for_ect, school_partnership:, ect_at_school_period:)
    else
      teacher = FactoryBot.create(:teacher, api_mentor_training_record_id: participant_declaration.participant_profile_id)
      mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, teacher:, school: school_partnership.school, started_on:)
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

      context "no special declaration" do
        let!(:ecf_delivery_partner) { FactoryBot.create(:migration_delivery_partner) }
        let!(:participant_declaration) { FactoryBot.create(:migration_participant_declaration, :refundable, delivery_partner: ecf_delivery_partner) }

        context "there is a training period matching pp, lp, dp, cohort and contains the declaration date" do
          let!(:training_period) { create_training_period_and_statements_for(participant_declaration)[:training_period] }

          it "associate that training period and create a declaration with the expected attributes" do
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

        context "there is a training period matching pp, lp, dp, cohort but doesn't contain the declaration date" do
          let!(:training_period) do
            create_training_period_and_statements_for(
              participant_declaration,
              started_on: participant_declaration.declaration_date - 2.years
            )[:training_period]
          end

          it "associate that training period and create a declaration with the expected attributes" do
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

        context "there is a training period matching pp, lp, and cohort" do
          let!(:participant_declaration) { FactoryBot.create(:migration_participant_declaration, :refundable) }

          let!(:training_period) do
            create_training_period_and_statements_for(
              participant_declaration,
              started_on: participant_declaration.declaration_date + 2.years
            )[:training_period]
          end

          it "associate that training period and create a declaration with the expected attributes" do
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
      end

      context "special declaration" do
        let!(:school) { FactoryBot.create(:school, urn: 149_712, create_contract_period: false) }
        let!(:ecf_school) { FactoryBot.create(:ecf_migration_school, urn: 149_712) }
        let!(:cohort) { FactoryBot.create(:migration_cohort) }
        let!(:school_cohort) { FactoryBot.create(:migration_school_cohort, cohort:, school: ecf_school) }
        let!(:participant_profile) { FactoryBot.create(:migration_participant_profile, :ect, school_cohort:) }
        let!(:participant_declaration) { FactoryBot.create(:migration_participant_declaration, :refundable, id: "05e09502-f3ef-4f89-aa1a-e17a120df7dc", participant_profile:, cohort:, declaration_type: :completed) }
        let!(:ecf_lead_provider) { participant_declaration.cpd_lead_provider.lead_provider }
        let!(:teacher) { FactoryBot.create(:teacher, api_ect_training_record_id: participant_declaration.participant_profile_id) }
        let!(:lead_provider) { FactoryBot.create(:lead_provider, ecf_id: ecf_lead_provider.id, name: ecf_lead_provider.name) }
        let!(:contract_period) { FactoryBot.create(:contract_period, year: participant_declaration.cohort.start_year) }
        let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
        let!(:delivery_partner) { FactoryBot.create(:delivery_partner, api_id: "cdb6cef0-5128-4f53-877c-37d70634e82a", name: "DP173") }
        let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
        let!(:schedule) { FactoryBot.create(:schedule, contract_period:) }
        let!(:payment_statement) { FactoryBot.create(:statement, :payable, api_id: participant_declaration.payment_statement.id, contract_period:) }
        let!(:clawback_statement) { FactoryBot.create(:statement, :payable, api_id: participant_declaration.clawback_statement.id, contract_period:) }

        context "there is a training period matching pp, lp, dp, cohort and contains the declaration date" do
          let!(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:) }
          let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: participant_declaration.declaration_date) }
          let!(:training_period) { FactoryBot.create(:training_period, :for_ect, school_partnership:, ect_at_school_period:) }

          it "associate that training period and creates a declaration with the expected attributes" do
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

        context "there is a training period matching pp, lp, dp, cohort but doesn't contain the declaration date" do
          let!(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:) }
          let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: participant_declaration.declaration_date - 2.years) }
          let!(:training_period) { FactoryBot.create(:training_period, :for_ect, school_partnership:, ect_at_school_period:) }

          it "associate that training period and creates a declaration with the expected attributes" do
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

        context "otherwise" do
          let!(:school_partnership) { FactoryBot.create(:school_partnership) }
          let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: started_on + 2.days) }
          let!(:training_period) { FactoryBot.create(:training_period, :for_ect, school_partnership:, ect_at_school_period:) }
          let(:started_on) { Date.new(contract_period.year, 8, 30) }

          it "build ASP and TP and create a declaration with the expected attributes associated to them" do
            instance.migrate!

            declaration = Declaration.find_by(api_id: participant_declaration.id)

            aggregate_failures do
              expect(declaration).to have_attributes(participant_declaration.attributes.slice("created_at", "declaration_date", "declaration_type", "evidence_type", "updated_at"))
              expect(declaration.pupil_premium_uplift).to be_falsey
              expect(declaration.sparsity_uplift).to be_falsey
              expect(declaration.clawback_statement_id).to eq(clawback_statement.id)
              expect(declaration.clawback_status).to eq(participant_declaration.clawback_status)
              expect(declaration.lead_provider.ecf_id).to eq(ecf_lead_provider_id)
              expect(declaration.payment_statement_id).to eq(payment_statement.id)
              expect(declaration.payment_status).to eq(participant_declaration.payment_status)
              expect(declaration.training_period_id).not_to eq(training_period.id)
              expect(declaration.training_period.started_on).to eq(started_on)
              expect(declaration.training_period.finished_on).to eq(started_on + 1.day)
              expect(declaration.training_period.school_partnership).not_to eq(school_partnership)
              expect(declaration.voided_by_user_at).to eq(participant_declaration.voided_at)
            end
          end

          context "when the at school period created is the teacher's only one" do
            let!(:ect_at_school_period) {}
            let!(:training_period) {}

            it "set its creation date to the participant profile's creation date" do
              instance.migrate!

              declaration = Declaration.find_by(api_id: participant_declaration.id)
              training_period = declaration.training_period

              expect(training_period.created_at).to eq(participant_profile.created_at)
              expect(training_period.at_school_period.created_at).to eq(training_period.created_at)
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
