describe "ERO mentor (no induction records, has billable declaration)" do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  let(:cohort_year) { 2021 }
  let(:declaration_date) { Date.new(2021, 10, 15) }
  let(:mentor_created_at) { Time.zone.local(2021, 9, 15, 10, 30) }
  let(:school_urn) { "123456" }
  let(:email) { "mentor@example.com" }

  let(:lead_provider_info) { Types::LeadProviderInfo.new(ecf1_id: SecureRandom.uuid, name: "Test Lead Provider") }
  let(:delivery_partner_info) { Types::DeliveryPartnerInfo.new(ecf1_id: SecureRandom.uuid, name: "Test Delivery Partner") }
  let(:training_provider_info) do
    ECF1TeacherHistory::TrainingProviderInfo.new(
      lead_provider_info:,
      delivery_partner_info:,
      cohort_year:
    )
  end

  let(:ero_declaration) do
    ECF1TeacherHistory::EroMentorDeclarationRow.new(
      declaration_id: SecureRandom.uuid,
      declaration_date:,
      cohort_year:,
      school_urn:,
      training_provider_info:,
      preferred_identity_email: email
    )
  end

  let(:mentor) do
    ECF1TeacherHistory::Mentor.new(
      participant_profile_id: SecureRandom.uuid,
      created_at: mentor_created_at,
      updated_at: Time.zone.now,
      mentor_completion_date: nil,
      mentor_completion_reason: nil,
      states: [],
      induction_records: [],
      ero_declaration:
    )
  end

  let(:ecf1_teacher_history) do
    FactoryBot.build(:ecf1_teacher_history) do |history|
      history.ect = nil
      history.mentor = mentor
    end
  end

  describe "mentor_at_school_period_rows" do
    it "creates one mentor at school period row" do
      expect(subject.mentor_at_school_period_rows.count).to eq(1)
    end

    describe "mentor at school period attributes" do
      let(:mentor_period_row) { subject.mentor_at_school_period_rows.first }

      it "sets the school URN from the declaration" do
        expect(mentor_period_row.school.urn).to eq(school_urn)
      end

      it "sets the email from the declaration" do
        expect(mentor_period_row.email).to eq(email)
      end

      it "calculates start_date as the earliest of declaration date, profile created_at, or service start" do
        # Service start is 2021-09-01, mentor created at 2021-09-15, declaration 2021-10-15
        # Earliest should be service start
        expect(mentor_period_row.started_on).to eq(Date.new(2021, 9, 1))
      end

      it "calculates end_date as 31 August following the declaration date" do
        # Declaration date is 2021-10-15, so 31 August 2022
        expect(mentor_period_row.finished_on).to eq(Date.new(2022, 8, 31))
      end

      context "when mentor has a completion date" do
        let(:mentor) do
          ECF1TeacherHistory::Mentor.new(
            participant_profile_id: SecureRandom.uuid,
            created_at: mentor_created_at,
            updated_at: Time.zone.now,
            mentor_completion_date: Date.new(2021, 12, 1),
            mentor_completion_reason: "completed",
            states: [],
            induction_records: [],
            ero_declaration:
          )
        end

        it "calculates end_date as 31 August following the completion date" do
          # Completion date is 2021-12-01, so 31 August 2022
          expect(mentor_period_row.finished_on).to eq(Date.new(2022, 8, 31))
        end
      end

      context "when declaration date is after August" do
        let(:declaration_date) { Date.new(2021, 9, 15) }

        it "calculates end_date as 31 August of the following year" do
          # Declaration date is 2021-09-15 (after August), so 31 August 2022
          expect(mentor_period_row.finished_on).to eq(Date.new(2022, 8, 31))
        end
      end
    end

    describe "training period attributes" do
      let(:mentor_period_row) { subject.mentor_at_school_period_rows.first }
      let(:training_period_row) { mentor_period_row.training_period_rows.first }

      it "creates one training period row" do
        expect(mentor_period_row.training_period_rows.count).to eq(1)
      end

      it "sets training_programme to provider_led" do
        expect(training_period_row.training_programme).to eq("provider_led")
      end

      it "sets lead_provider_info from the declaration" do
        expect(training_period_row.lead_provider_info.ecf1_id).to eq(lead_provider_info.ecf1_id)
        expect(training_period_row.lead_provider_info.name).to eq(lead_provider_info.name)
      end

      it "sets delivery_partner_info from the declaration" do
        expect(training_period_row.delivery_partner_info.ecf1_id).to eq(delivery_partner_info.ecf1_id)
        expect(training_period_row.delivery_partner_info.name).to eq(delivery_partner_info.name)
      end

      it "sets contract_period from the cohort year" do
        expect(training_period_row.contract_period).to eq(cohort_year)
      end

      it "sets schedule_info to nil (looked up later by cohort_year)" do
        expect(training_period_row.schedule_info).to be_nil
      end

      it "has the same start and end dates as the school period" do
        expect(training_period_row.started_on).to eq(mentor_period_row.started_on)
        expect(training_period_row.finished_on).to eq(mentor_period_row.finished_on)
      end
    end
  end

  context "when mentor has no ero_declaration (no billable declarations)" do
    let(:mentor) do
      ECF1TeacherHistory::Mentor.new(
        participant_profile_id: SecureRandom.uuid,
        created_at: mentor_created_at,
        updated_at: Time.zone.now,
        mentor_completion_date: nil,
        mentor_completion_reason: nil,
        states: [],
        induction_records: [],
        ero_declaration: nil
      )
    end

    it "returns empty mentor_at_school_period_rows" do
      expect(subject.mentor_at_school_period_rows).to be_empty
    end
  end

  context "when there is no mentor at all" do
    let(:ecf1_teacher_history) do
      FactoryBot.build(:ecf1_teacher_history) do |history|
        history.ect = FactoryBot.build(:ecf1_teacher_history_ect, induction_records: [])
        history.mentor = nil
      end
    end

    it "returns empty mentor_at_school_period_rows" do
      expect(subject.mentor_at_school_period_rows).to be_empty
    end
  end
end
