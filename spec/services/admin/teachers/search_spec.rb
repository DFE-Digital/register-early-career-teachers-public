RSpec.describe Admin::Teachers::Search do
  subject(:search) { described_class.new(query_string:, role:, contract_period:) }

  let(:query_string) { nil }
  let(:role) { nil }
  let(:contract_period) { nil }

  describe "#teacher_scope" do
    subject(:teacher_scope) { search.teacher_scope }

    context "when teachers have different creation times" do
      let!(:older_teacher) { FactoryBot.create(:teacher, created_at: 2.days.ago) }
      let!(:newer_teacher) { FactoryBot.create(:teacher, created_at: 1.day.ago) }

      it "orders teachers by most recently created" do
        expect(teacher_scope).to eq([newer_teacher, older_teacher])
      end
    end

    context "when searching by name" do
      let(:query_string) { "Naruto" }
      let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
      let!(:other_teacher) { FactoryBot.create(:teacher, trs_first_name: "Sasuke", trs_last_name: "Uchiha") }

      it { is_expected.to contain_exactly(teacher) }
    end

    context "when filtering ECT rows by contract period across the whole dataset" do
      let(:contract_period) { "2024" }
      let!(:matching_teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
      let!(:non_matching_teacher) { FactoryBot.create(:teacher, trs_first_name: "Sasuke", trs_last_name: "Uchiha") }
      let!(:matching_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher: matching_teacher, started_on: Date.new(2025, 1, 1), finished_on: Date.new(2025, 7, 31)) }
      let!(:non_matching_old_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher: non_matching_teacher, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 7, 31)) }
      let!(:non_matching_latest_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, teacher: non_matching_teacher, started_on: Date.new(2025, 1, 1)) }

      before do
        contract_period_2024 = FactoryBot.create(:contract_period, year: 2024)
        contract_period_2025 = FactoryBot.create(:contract_period, year: 2025)

        matching_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_framework_agreement,
          framework_agreement: FactoryBot.create(:framework_agreement, contract_period: contract_period_2024),
          school: matching_ect_at_school_period.school
        )

        old_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_framework_agreement,
          framework_agreement: FactoryBot.create(:framework_agreement, contract_period: contract_period_2024),
          school: non_matching_old_ect_at_school_period.school
        )

        current_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_framework_agreement,
          framework_agreement: FactoryBot.create(:framework_agreement, contract_period: contract_period_2025),
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
          :unfinished,
          ect_at_school_period: non_matching_latest_ect_at_school_period,
          school_partnership: current_school_partnership
        )
      end

      it "matches teachers by the latest role periods, latest training period and contract period" do
        expect(teacher_scope).to contain_exactly(matching_teacher)
      end
    end

    context "when filtering mentor rows by contract period across the whole dataset" do
      let(:role) { "mentor" }
      let(:contract_period) { "2024" }
      let!(:matching_teacher) { FactoryBot.create(:teacher, trs_first_name: "Kakashi", trs_last_name: "Hatake") }
      let!(:non_matching_teacher) { FactoryBot.create(:teacher, trs_first_name: "Might", trs_last_name: "Guy") }
      let!(:matching_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher: matching_teacher, started_on: Date.new(2025, 1, 1), finished_on: Date.new(2025, 7, 31)) }
      let!(:non_matching_old_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher: non_matching_teacher, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 7, 31)) }
      let!(:non_matching_latest_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :unfinished, teacher: non_matching_teacher, started_on: Date.new(2025, 1, 1)) }

      before do
        contract_period_2024 = FactoryBot.create(:contract_period, year: 2024)
        contract_period_2025 = FactoryBot.create(:contract_period, year: 2025)

        matching_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_framework_agreement,
          framework_agreement: FactoryBot.create(:framework_agreement, contract_period: contract_period_2024),
          school: matching_mentor_at_school_period.school
        )

        old_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_framework_agreement,
          framework_agreement: FactoryBot.create(:framework_agreement, contract_period: contract_period_2024),
          school: non_matching_old_mentor_at_school_period.school
        )

        latest_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_framework_agreement,
          framework_agreement: FactoryBot.create(:framework_agreement, contract_period: contract_period_2025),
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
          :unfinished,
          mentor_at_school_period: non_matching_latest_mentor_at_school_period,
          school_partnership: latest_school_partnership
        )
      end

      it "matches mentors by the latest role periods, latest training period and contract period" do
        expect(teacher_scope).to contain_exactly(matching_teacher)
      end
    end

    context "when filtering by the not available contract period option" do
      let(:contract_period) { Admin::Teachers::Rows::CONTRACT_PERIOD_NOT_AVAILABLE }
      let!(:school_led_teacher) { FactoryBot.create(:teacher) }
      let!(:ect_without_training) { FactoryBot.create(:teacher) }
      let!(:mentor_without_training) { FactoryBot.create(:teacher) }
      let!(:induction_only_teacher) { FactoryBot.create(:teacher) }
      let!(:no_role_teacher) { FactoryBot.create(:teacher) }
      let!(:provider_led_teacher) { FactoryBot.create(:teacher) }

      before do
        school_led_period = FactoryBot.create(:ect_at_school_period, :unfinished, teacher: school_led_teacher)
        FactoryBot.create(
          :training_period,
          :for_ect,
          :school_led,
          :unfinished,
          ect_at_school_period: school_led_period
        )

        FactoryBot.create(:ect_at_school_period, :unfinished, teacher: ect_without_training)
        FactoryBot.create(:mentor_at_school_period, :unfinished, teacher: mentor_without_training)
        FactoryBot.create(:induction_period, teacher: induction_only_teacher)

        provider_led_period = FactoryBot.create(:ect_at_school_period, :unfinished, teacher: provider_led_teacher)
        FactoryBot.create(
          :training_period,
          :for_ect,
          :unfinished,
          ect_at_school_period: provider_led_period
        )
      end

      it "matches every teacher row without a contract period" do
        expect(teacher_scope).to contain_exactly(
          school_led_teacher,
          ect_without_training,
          mentor_without_training,
          induction_only_teacher,
          no_role_teacher
        )
      end

      context "when filtering by the ECT role" do
        let(:role) { "ect" }

        it "matches only unavailable ECT rows" do
          expect(teacher_scope).to contain_exactly(
            school_led_teacher,
            ect_without_training,
            induction_only_teacher
          )
        end
      end

      context "when filtering by the mentor role" do
        let(:role) { "mentor" }

        it "matches only unavailable mentor rows" do
          expect(teacher_scope).to contain_exactly(mentor_without_training)
        end
      end
    end
  end
end
