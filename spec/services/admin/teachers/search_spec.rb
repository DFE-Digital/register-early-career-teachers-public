RSpec.describe Admin::Teachers::Search do
  subject { described_class.new(query_string:, role:, contract_period:) }

  let(:query_string) { nil }
  let(:role) { nil }
  let(:contract_period) { nil }

  describe "#teacher_scope" do
    context "when the query is blank" do
      let!(:teacher) { FactoryBot.create(:teacher) }

      it "returns all teachers" do
        expect(subject.teacher_scope).to include(teacher)
      end
    end

    context "when it is an exact 7 digit TRN" do
      let(:query_string) { "1234567" }
      let!(:teacher) { FactoryBot.create(:teacher, trn: "1234567") }
      let!(:other_teacher) { FactoryBot.create(:teacher, trn: "7654321", trs_first_name: "1234567", trs_last_name: "Teacher") }

      it "matches by TRN only" do
        expect(subject.teacher_scope).to contain_exactly(teacher)
      end
    end

    context "when it contains a full TRN with extra text" do
      let(:query_string) { "TRN 1234567" }
      let!(:teacher) { FactoryBot.create(:teacher, trn: "1234567") }
      let!(:other_teacher) { FactoryBot.create(:teacher, trs_first_name: "TRN", trs_last_name: "Teacher") }

      it "matches by TRN" do
        expect(subject.teacher_scope).to contain_exactly(teacher)
      end
    end

    context "when it is a partial API participant ID" do
      let(:query_string) { "4266141740" }
      let!(:teacher) { FactoryBot.create(:teacher, api_id: "123e4567-e89b-12d3-a456-426614174000") }
      let!(:other_teacher) { FactoryBot.create(:teacher, api_id: "999e4567-e89b-12d3-a456-426614174999") }

      it "matches the API participant ID" do
        expect(subject.teacher_scope).to contain_exactly(teacher)
      end
    end

    context "when the query is a plain name" do
      let(:query_string) { "Naruto" }
      let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki", api_id: "123e4567-e89b-12d3-a456-426614174000") }
      let!(:other_teacher) { FactoryBot.create(:teacher, trs_first_name: "Sasuke", trs_last_name: "Uchiha", api_id: "999e4567-e89b-12d3-a456-426614174999") }

      it "does not fall back to API participant ID matching" do
        expect(subject.teacher_scope).to contain_exactly(teacher)
      end
    end

    context "when the query only contains tsquery punctuation" do
      let(:query_string) { "<?'" }

      it "returns no teachers" do
        expect(subject.teacher_scope).to be_empty
      end
    end

    context "when filtering ECT rows by contract period across the whole dataset" do
      let(:contract_period) { "2024" }
      let!(:matching_teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
      let!(:non_matching_teacher) { FactoryBot.create(:teacher, trs_first_name: "Sasuke", trs_last_name: "Uchiha") }
      let!(:matching_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher: matching_teacher, started_on: Date.new(2025, 1, 1), finished_on: Date.new(2025, 7, 31)) }
      let!(:non_matching_old_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher: non_matching_teacher, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 7, 31)) }
      let!(:non_matching_latest_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher: non_matching_teacher, started_on: Date.new(2025, 1, 1)) }

      before do
        contract_period_2024 = FactoryBot.create(:contract_period, year: 2024)
        contract_period_2025 = FactoryBot.create(:contract_period, year: 2025)

        matching_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period_2024),
          school: matching_ect_at_school_period.school
        )

        old_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period_2024),
          school: non_matching_old_ect_at_school_period.school
        )

        current_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period_2025),
          school: non_matching_latest_ect_at_school_period.school
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          ect_at_school_period: matching_ect_at_school_period,
          school_partnership: matching_school_partnership,
          started_on: matching_ect_at_school_period.started_on,
          finished_on: matching_ect_at_school_period.finished_on
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          ect_at_school_period: non_matching_old_ect_at_school_period,
          school_partnership: old_school_partnership,
          started_on: non_matching_old_ect_at_school_period.started_on,
          finished_on: non_matching_old_ect_at_school_period.finished_on
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          :ongoing,
          ect_at_school_period: non_matching_latest_ect_at_school_period,
          school_partnership: current_school_partnership
        )
      end

      it "matches teachers by the latest role periods, latest training period and contract period" do
        expect(subject.teacher_scope).to contain_exactly(matching_teacher)
      end
    end

    context "when filtering mentor rows by contract period across the whole dataset" do
      let(:role) { "mentor" }
      let(:contract_period) { "2024" }
      let!(:matching_teacher) { FactoryBot.create(:teacher, trs_first_name: "Kakashi", trs_last_name: "Hatake") }
      let!(:non_matching_teacher) { FactoryBot.create(:teacher, trs_first_name: "Might", trs_last_name: "Guy") }
      let!(:matching_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher: matching_teacher, started_on: Date.new(2025, 1, 1), finished_on: Date.new(2025, 7, 31)) }
      let!(:non_matching_old_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher: non_matching_teacher, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 7, 31)) }
      let!(:non_matching_latest_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher: non_matching_teacher, started_on: Date.new(2025, 1, 1)) }

      before do
        contract_period_2024 = FactoryBot.create(:contract_period, year: 2024)
        contract_period_2025 = FactoryBot.create(:contract_period, year: 2025)

        matching_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period_2024),
          school: matching_mentor_at_school_period.school
        )

        old_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period_2024),
          school: non_matching_old_mentor_at_school_period.school
        )

        latest_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period_2025),
          school: non_matching_latest_mentor_at_school_period.school
        )

        FactoryBot.create(
          :training_period,
          :for_mentor,
          mentor_at_school_period: matching_mentor_at_school_period,
          school_partnership: matching_school_partnership,
          started_on: matching_mentor_at_school_period.started_on,
          finished_on: matching_mentor_at_school_period.finished_on
        )

        FactoryBot.create(
          :training_period,
          :for_mentor,
          mentor_at_school_period: non_matching_old_mentor_at_school_period,
          school_partnership: old_school_partnership,
          started_on: non_matching_old_mentor_at_school_period.started_on,
          finished_on: non_matching_old_mentor_at_school_period.finished_on
        )

        FactoryBot.create(
          :training_period,
          :for_mentor,
          :ongoing,
          mentor_at_school_period: non_matching_latest_mentor_at_school_period,
          school_partnership: latest_school_partnership
        )
      end

      it "matches mentors by the latest role periods, latest training period and contract period" do
        expect(subject.teacher_scope).to contain_exactly(matching_teacher)
      end
    end
  end
end
