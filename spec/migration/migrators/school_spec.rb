describe Migrators::School do
  def create_ecf_school
    FactoryBot.create(:ecf_migration_school,
                      school_status_code: 1,
                      administrative_district_name: "AD1",
                      administrative_district_code: "9999",
                      school_type_code: 1,
                      name: "School one",
                      school_phase_name: "Phase one",
                      section_41_approved: false,
                      school_status_name: "Open",
                      school_type_name: "Academy converter").tap do |ecf_school|
      FactoryBot.create(:ecf_migration_school_local_authority, school: ecf_school)
      FactoryBot.create(:migration_induction_coordinator_profile, schools: [ecf_school])
    end
  end

  def create_gias_school(ecf_school)
    FactoryBot.create(:gias_school, :with_school,
                      urn: ecf_school.urn,
                      administrative_district_name: "AD1",
                      eligible: true,
                      in_england: true,
                      name: "School one",
                      phase_name: "Phase one",
                      section_41_approved: false,
                      status: "open",
                      type_name: "Academy converter",
                      ukprn: ecf_school.ukprn)
  end

  it_behaves_like "a migrator", :school, %i[gias_import gias_childrens_centres] do
    def create_migration_resource = create_ecf_school

    def create_resource(migration_resource) = create_gias_school(migration_resource)

    def setup_failure_state
      ecf_school = create_migration_resource
      gias_school = create_resource(ecf_school)

      gias_school.update!(section_41_approved: !ecf_school.section_41_approved)
    end
  end

  describe "#migrate!" do
    let!(:data_migration) { FactoryBot.create(:data_migration, model: :school, worker: 0) }

    context "when the ECF school can't be found in RECT" do
      context "when the GIAS school can't be created from the ECF school" do
        let!(:induction_record) { FactoryBot.create(:migration_induction_record) }
        let!(:ecf_school) { induction_record.school.tap { it.update!(school_status_name: "open") } }

        before do
          allow(::GIAS::School).to receive(:create!).and_raise(ActiveRecord::ActiveRecordError, "can't create school!")
        end

        it "logs a failure" do
          expect { described_class.new(worker: 0).migrate! }.not_to change(GIAS::School, :count)
          failure_messages = data_migration.migration_failures.pluck(:failure_message)
          expect(failure_messages).to contain_exactly("Failed to find or build a GIAS school for school with urn #{ecf_school.urn} (#{ecf_school.name}): can't create school!")
        end
      end

      context "when the school is closed and with induction records" do
        let!(:induction_record) { FactoryBot.create(:migration_induction_record) }
        let!(:ecf_school) { induction_record.school }
        let(:rect_school) { School.find_by_urn(ecf_school.urn) }

        before do
          ecf_school.update!(school_status_code: 2, school_type_code: 10, school_status_name: "closed", school_type_name: "Community school")
        end

        it "migrates it to RECT" do
          expect { described_class.new(worker: 0).migrate! }.to change(GIAS::School, :count).by(1)
          expect(rect_school.api_id).to eq(ecf_school.id)
        end
      end

      context "when the school is closed and with an unchallenged partnerships" do
        let!(:partnership) { FactoryBot.create(:migration_partnership) }
        let!(:ecf_school) { partnership.school }
        let(:rect_school) { School.find_by_urn(ecf_school.urn) }

        before do
          ecf_school.update!(school_status_code: 1, school_type_code: 10, school_status_name: "closed", school_type_name: "Community school")
        end

        it "migrates it to RECT" do
          expect { described_class.new(worker: 0).migrate! }.to change(GIAS::School, :count).by(1)
          expect(rect_school.api_id).to eq(ecf_school.id)
        end
      end

      context "when the school is closed and with an challenged partnerships" do
        let!(:partnership) { FactoryBot.create(:migration_partnership, challenged_at: 1.month.ago) }
        let!(:ecf_school) { partnership.school }
        let(:rect_school) { School.find_by_urn(ecf_school.urn) }

        before do
          ecf_school.update!(school_status_code: 1, school_type_code: 10, school_status_name: "closed", school_type_name: "Community school")
        end

        it { expect { described_class.new(worker: 0).migrate! }.not_to change(School, :count) }
      end

      context "when the school has no partnerships or induction records and is not returned by the API" do
        let!(:ecf_school) { FactoryBot.create(:ecf_migration_school, school_status_code: 1, school_status_name: "open", school_type_code: 10) }

        it { expect { described_class.new(worker: 0).migrate! }.not_to change(School, :count) }
      end
    end

    context "when fields mismatch" do
      let(:school_status_name) { "Open" }
      let(:status) { "closed" }
      let(:failure_messages) { data_migration.migration_failures.order(:created_at).pluck(:failure_message) }

      let!(:ecf_school) do
        FactoryBot.create(:ecf_migration_school,
                          school_status_code: 1,
                          administrative_district_name: "AD1",
                          administrative_district_code: "9999",
                          school_type_code: 1,
                          school_phase_name: "Phase one",
                          section_41_approved: false,
                          school_status_name:,
                          school_type_name: "Type one",
                          ukprn: "12345")
      end

      let!(:gias_school) do
        FactoryBot.create(:gias_school, :with_school,
                          urn: ecf_school.urn,
                          administrative_district_name: "AAD1",
                          eligible: true,
                          in_england: true,
                          phase_name: "Another Phase one",
                          section_41_approved: true,
                          status:,
                          type_name: "Academy converter",
                          ukprn: 54_321)
      end

      before do
        described_class.new(worker: 0).migrate!
      end

      it "adds mismatch errors" do
        expect(data_migration.reload.failure_count).to eq(1)
        expect(failure_messages)
          .to contain_exactly(":administrative_district_name - School #{ecf_school.urn} (#{ecf_school.name}) mismatch value on field named 'administrative_district_name': 'AD1' on ECF whilst 'AAD1' expected on RECT!",
                              ":eligible - School #{ecf_school.urn} (#{ecf_school.name}) mismatch value on field named 'eligible': 'false' on ECF whilst 'true' expected on RECT!",
                              ":in_england - School #{ecf_school.urn} (#{ecf_school.name}) mismatch value on field named 'in_england': 'false' on ECF whilst 'true' expected on RECT!",
                              ":phase_name - School #{ecf_school.urn} (#{ecf_school.name}) mismatch value on field named 'phase_name': 'Phase one' on ECF whilst 'Another Phase one' expected on RECT!",
                              ":section_41_approved - School #{ecf_school.urn} (#{ecf_school.name}) mismatch value on field named 'section_41_approved': 'false' on ECF whilst 'true' expected on RECT!",
                              ":status - School #{ecf_school.urn} (#{ecf_school.name}) mismatch value on field named 'status': 'open' on ECF whilst 'closed' expected on RECT!",
                              ":type_name - School #{ecf_school.urn} (#{ecf_school.name}) mismatch value on field named 'type_name': 'Type one' on ECF whilst 'Academy converter' expected on RECT!",
                              ":ukprn - School #{ecf_school.urn} (#{ecf_school.name}) mismatch value on field named 'ukprn': '12345' on ECF whilst '54321' expected on RECT!")
      end

      {
        "Open" => "proposed_to_close",
        "Proposed to Close" => "open",
        "Closed" => "proposed_to_open",
        "Proposed to Open" => "closed"
      }.each do |ecf1_value, ecf2_value|
        context "when the ECF1 school has status value '#{ecf1_value}' and the ECF2's is '#{ecf2_value}'" do
          let(:school_status_name) { ecf1_value }
          let(:status) { ecf2_value }

          it "do not add mismatch errors on :status" do
            expect(failure_messages.join(" ")).not_to include(":status")
          end
        end
      end
    end

    context "when school is a Children's Centre type" do
      let!(:ecf_school) do
        FactoryBot.create(:ecf_migration_school,
                          school_status_code: 1,
                          administrative_district_name: "AD1",
                          administrative_district_code: "9999",
                          school_type_code: 1,
                          name: "School one",
                          school_phase_name: "Phase one",
                          section_41_approved: false,
                          school_status_name: "Open",
                          school_type_name: "Children's centre",
                          ukprn: "12345")
      end

      let!(:gias_school) do
        FactoryBot.create(:gias_school, :with_school,
                          urn: ecf_school.urn,
                          administrative_district_name: nil,
                          eligible: true,
                          in_england: true,
                          name: "School one",
                          phase_name: "Phase one",
                          section_41_approved: false,
                          status: "open",
                          type_name: "Children's centre",
                          ukprn: 12_345)
      end

      before do
        described_class.new(worker: 0).migrate!
      end

      it "skips comparing the administrative_district_name field" do
        expect(data_migration.reload.failure_count).to be_zero
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
