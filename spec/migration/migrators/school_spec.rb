describe Migrators::School do
  def create_ecf_school
    FactoryBot.create(:ecf_migration_school,
                      school_status_code: 1,
                      administrative_district_name: 'AD1',
                      administrative_district_code: '9999',
                      school_type_code: 1,
                      name: 'School one',
                      school_phase_name: 'Phase one',
                      section_41_approved: false,
                      school_status_name: 'Open',
                      school_type_name: 'Academy converter').tap do |ecf_school|
      FactoryBot.create(:ecf_migration_school_local_authority, school: ecf_school)
      FactoryBot.create(:migration_induction_coordinator_profile, schools: [ecf_school])
    end
  end

  def create_gias_school(ecf_school)
    FactoryBot.create(:gias_school, :with_school,
                      urn: ecf_school.urn,
                      administrative_district_name: 'AD1',
                      funding_eligibility: 'eligible_for_fip',
                      induction_eligibility: true,
                      in_england: true,
                      name: 'School one',
                      phase_name: 'Phase one',
                      section_41_approved: false,
                      status: 'open',
                      type_name: 'Academy converter',
                      ukprn: ecf_school.ukprn)
  end

  it_behaves_like "a migrator", :school, [:gias_import] do
    def create_migration_resource = create_ecf_school

    def create_resource(migration_resource) = create_gias_school(migration_resource)

    def setup_failure_state = create_migration_resource
  end

  describe "#migrate!" do
    let!(:data_migration) { FactoryBot.create(:data_migration, model: :school, worker: 0) }

    context "when the ECF school can't be found in RECT" do
      context "when the school is closed and with induction records" do
        let!(:induction_record) { FactoryBot.create(:migration_induction_record) }
        let!(:ecf_school) { induction_record.school }
        let(:rect_school) { School.find_by_urn(ecf_school.urn) }

        before do
          ecf_school.update!(school_status_code: 2, school_type_code: 10, school_status_name: 'closed', school_type_name: 'Community school')
        end

        it "migrates it to RECT" do
          expect { described_class.new(worker: 0).migrate! }.to change(GIAS::School, :count).by(1)
          expect(rect_school.api_id).to eq(ecf_school.id)
        end
      end

      context "when the school is open and with partnerships" do
        let!(:partnership) { FactoryBot.create(:migration_partnership) }
        let!(:ecf_school) { partnership.school }
        let(:rect_school) { School.find_by_urn(ecf_school.urn) }

        before do
          ecf_school.update!(school_status_code: 1, school_type_code: 10, school_status_name: 'open', school_type_name: 'Community school')
        end

        it "migrates it to RECT" do
          expect { described_class.new(worker: 0).migrate! }.to change(GIAS::School, :count).by(1)
          expect(rect_school.api_id).to eq(ecf_school.id)
        end
      end

      context "when the school has no partnerships or induction records" do
        let!(:ecf_school) { FactoryBot.create(:ecf_migration_school, school_status_code: 1, school_status_name: 'open', school_type_code: 10) }

        before do
          described_class.new(worker: 0).migrate!
        end

        it "adds an error" do
          expect(data_migration.reload.failure_count).to eq(1)
          expect(data_migration.migration_failures.count).to eq(1)
          expect(data_migration.migration_failures.first.failure_message).to eq(":school_missing - School #{ecf_school.urn} (#{ecf_school.name}) missing on RECT!")
        end
      end
    end

    context "when fields mismatch" do
      let!(:ecf_school) do
        FactoryBot.create(:ecf_migration_school,
                          school_status_code: 1,
                          administrative_district_name: 'AD1',
                          administrative_district_code: '9999',
                          school_type_code: 1,
                          name: 'School one',
                          school_phase_name: 'Phase one',
                          section_41_approved: false,
                          school_status_name: 'Open',
                          school_type_name: 'Type one',
                          ukprn: "12345")
      end

      let!(:gias_school) do
        FactoryBot.create(:gias_school, :with_school,
                          urn: ecf_school.urn,
                          administrative_district_name: 'AAD1',
                          funding_eligibility: 'eligible_for_cip',
                          induction_eligibility: true,
                          in_england: true,
                          name: 'Another School one',
                          phase_name: 'Another Phase one',
                          section_41_approved: true,
                          status: 'proposed_to_close',
                          type_name: 'Academy converter',
                          ukprn: 54_321)
      end

      before do
        described_class.new(worker: 0).migrate!
      end

      it "adds mismatch errors" do
        expect(data_migration.reload.failure_count).to eq(1)
        expect(data_migration.migration_failures.order(:created_at).pluck(:failure_message))
          .to contain_exactly(":administrative_district_name - School #{gias_school.urn} (#{gias_school.name}) mismatch value on field named 'administrative_district_name': 'AD1' on ECF whilst 'AAD1' expected on RECT!",
                              ":funding_eligibility - School #{gias_school.urn} (#{gias_school.name}) mismatch value on field named 'funding_eligibility': 'ineligible' on ECF whilst 'eligible_for_cip' expected on RECT!",
                              ":induction_eligibility - School #{gias_school.urn} (#{gias_school.name}) mismatch value on field named 'induction_eligibility': 'false' on ECF whilst 'true' expected on RECT!",
                              ":in_england - School #{gias_school.urn} (#{gias_school.name}) mismatch value on field named 'in_england': 'false' on ECF whilst 'true' expected on RECT!",
                              ":name - School #{gias_school.urn} (#{gias_school.name}) mismatch value on field named 'name': 'School one' on ECF whilst 'Another School one' expected on RECT!",
                              ":phase_name - School #{gias_school.urn} (#{gias_school.name}) mismatch value on field named 'phase_name': 'Phase one' on ECF whilst 'Another Phase one' expected on RECT!",
                              ":section_41_approved - School #{gias_school.urn} (#{gias_school.name}) mismatch value on field named 'section_41_approved': 'false' on ECF whilst 'true' expected on RECT!",
                              ":status - School #{gias_school.urn} (#{gias_school.name}) mismatch value on field named 'status': 'open' on ECF whilst 'proposed_to_close' expected on RECT!",
                              ":type_name - School #{gias_school.urn} (#{gias_school.name}) mismatch value on field named 'type_name': 'Type one' on ECF whilst 'Academy converter' expected on RECT!",
                              ":ukprn - School #{gias_school.urn} (#{gias_school.name}) mismatch value on field named 'ukprn': '12345' on ECF whilst '54321' expected on RECT!")
      end
    end

    context "when schools match" do
      let!(:ecf_school) { create_ecf_school }
      let!(:gias_school) { create_gias_school(ecf_school) }

      before do
        described_class.new(worker: 0).migrate!
      end

      it "sets api_id to be the id of the school on ECF" do
        expect(data_migration.reload.failure_count).to eq(0)
        gias_school.reload
        expect(gias_school.school.api_id).to eq(ecf_school.id)
      end

      it "syncs the timestamps from the ECF school to the RECT school" do
        expect(data_migration.reload.failure_count).to eq(0)
        gias_school.reload
        expect(gias_school.school.created_at).to eq(ecf_school.created_at)
        expect(gias_school.school.api_updated_at).to eq(ecf_school.updated_at)
      end

      it "syncs the induction coordinator details" do
        gias_school.reload
        expect(gias_school.school.induction_tutor_name).to eq(ecf_school.induction_coordinators.first.full_name)
        expect(gias_school.school.induction_tutor_email).to eq(ecf_school.induction_coordinators.first.email)
      end
    end
  end
end
