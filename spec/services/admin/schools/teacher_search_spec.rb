RSpec.describe Admin::Schools::TeacherSearch do
  subject(:rows) { described_class.new(school:, query_string:, role:, contract_period:).rows }

  around { |example| travel_to(Date.new(2025, 1, 15)) { example.run } }

  let(:school) { FactoryBot.create(:school) }
  let(:query_string) { nil }
  let(:role) { nil }
  let(:contract_period) { nil }
  let(:school_partnership_2024) { FactoryBot.create(:school_partnership, :for_year, school:, year: 2024) }
  let(:school_partnership_2025) { FactoryBot.create(:school_partnership, :for_year, school:, year: 2025) }

  describe "#rows" do
    context "when teachers have current and previous roles at the school" do
      let!(:both_roles_teacher) do
        FactoryBot.create(:teacher, trs_first_name: "Goku", created_at: 2.days.ago)
      end
      let!(:ect_teacher) do
        FactoryBot.create(:teacher, trs_first_name: "Vegeta", created_at: 1.day.ago)
      end
      let!(:leaving_teacher) do
        FactoryBot.create(:teacher, trs_first_name: "Piccolo", created_at: 3.days.ago)
      end
      let!(:previous_teacher) { FactoryBot.create(:teacher, trs_first_name: "Frieza") }
      let!(:teacher_at_another_school) { FactoryBot.create(:teacher, trs_first_name: "Cell") }

      before do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :unfinished,
          ect_at_school_period: FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher: both_roles_teacher),
          school_partnership: school_partnership_2024
        )
        FactoryBot.create(
          :training_period,
          :for_mentor,
          :unfinished,
          mentor_at_school_period: FactoryBot.create(:mentor_at_school_period, :unfinished, school:, teacher: both_roles_teacher),
          school_partnership: school_partnership_2025
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          :school_led,
          :unfinished,
          ect_at_school_period: FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher: ect_teacher)
        )
        FactoryBot.create(
          :ect_at_school_period,
          school:,
          teacher: leaving_teacher,
          started_on: 1.year.ago.to_date,
          finished_on: 2.weeks.from_now.to_date
        )
        FactoryBot.create(:ect_at_school_period, :finished, school:, teacher: previous_teacher)

        other_school = FactoryBot.create(:school)
        FactoryBot.create(
          :ect_at_school_period,
          :unfinished,
          school: other_school,
          teacher: teacher_at_another_school
        )
      end

      it "returns one row per current role, sorted by teacher creation time" do
        expect(rows.map { |row| [row.teacher, row.role_name, row.contract_period_name] }).to eq([
          [ect_teacher, "Early career teacher", "Not available"],
          [both_roles_teacher, "Early career teacher", "2024"],
          [both_roles_teacher, "Mentor", "2025"],
          [leaving_teacher, "Early career teacher", "Not available"]
        ])
      end

      it "does not return teachers with only closed school periods or periods at another school" do
        expect(rows.map(&:teacher)).not_to include(previous_teacher, teacher_at_another_school)
      end
    end

    context "when a teacher has consecutive current and future periods for the same role" do
      let!(:teacher) { FactoryBot.create(:teacher) }
      let!(:future_teacher) { FactoryBot.create(:teacher) }

      before do
        FactoryBot.create(:ect_at_school_period, school:, teacher:, started_on: 1.year.ago.to_date, finished_on: Date.current)
        FactoryBot.create(:ect_at_school_period, school:, teacher:, started_on: Date.tomorrow, finished_on: nil)
        FactoryBot.create(:mentor_at_school_period, school:, teacher: future_teacher, started_on: Date.tomorrow, finished_on: nil)
      end

      it "returns only the role period containing today" do
        expect(rows.map(&:teacher)).to eq([teacher])
        expect(rows.map(&:role_name)).to eq(["Early career teacher"])
        expect(rows.map(&:teacher)).not_to include(future_teacher)
      end
    end

    context "when filtering by role" do
      let(:role) { "mentor" }
      let!(:teacher) { FactoryBot.create(:teacher) }

      before do
        FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher:)
        mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :unfinished, school:, teacher:)
        FactoryBot.create(:training_period, :for_mentor, :unfinished, mentor_at_school_period:, school_partnership: school_partnership_2025)
      end

      it "returns only rows for that role" do
        expect(rows.map(&:teacher)).to eq([teacher])
        expect(rows.map(&:role_name)).to eq(%w[Mentor])
        expect(rows.map(&:contract_period_name)).to eq(%w[2025])
      end
    end

    context "when filtering by contract period" do
      let(:contract_period) { "2024" }
      let!(:matching_teacher) { FactoryBot.create(:teacher, trs_first_name: "Gohan") }
      let!(:other_teacher) { FactoryBot.create(:teacher, trs_first_name: "Krillin") }

      before do
        matching_ect_at_school_period = FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher: matching_teacher)
        other_mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :unfinished, school:, teacher: other_teacher)
        FactoryBot.create(:training_period, :for_ect, :unfinished, ect_at_school_period: matching_ect_at_school_period, school_partnership: school_partnership_2024)
        FactoryBot.create(:training_period, :for_mentor, :unfinished, mentor_at_school_period: other_mentor_at_school_period, school_partnership: school_partnership_2025)
      end

      it "returns only rows for that contract period" do
        expect(rows.map(&:teacher)).to eq([matching_teacher])
        expect(rows.map(&:teacher)).not_to include(other_teacher)
      end
    end

    context "when filtering by a contract period and role" do
      let(:role) { "mentor" }
      let(:contract_period) { "2025" }
      let!(:teacher) { FactoryBot.create(:teacher) }
      let!(:role_only_teacher) { FactoryBot.create(:teacher) }
      let!(:contract_period_only_teacher) { FactoryBot.create(:teacher) }

      before do
        FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher:)
        teacher_mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :unfinished, school:, teacher:)
        role_only_mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :unfinished, school:, teacher: role_only_teacher)
        contract_period_only_ect_at_school_period = FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher: contract_period_only_teacher)
        FactoryBot.create(:training_period, :for_mentor, :unfinished, mentor_at_school_period: teacher_mentor_at_school_period, school_partnership: school_partnership_2025)
        FactoryBot.create(:training_period, :for_mentor, :unfinished, mentor_at_school_period: role_only_mentor_at_school_period, school_partnership: school_partnership_2024)
        FactoryBot.create(:training_period, :for_ect, :unfinished, ect_at_school_period: contract_period_only_ect_at_school_period, school_partnership: school_partnership_2025)
      end

      it "applies both filters to the role rows" do
        expect(rows.map(&:teacher)).to eq([teacher])
        expect(rows.map(&:role_name)).to eq(%w[Mentor])
        expect(rows.map(&:teacher)).not_to include(role_only_teacher, contract_period_only_teacher)
      end
    end

    context "when filtering by the not available contract period option" do
      let(:contract_period) { Admin::Teachers::Rows::CONTRACT_PERIOD_NOT_AVAILABLE }
      let!(:school_led_teacher) { FactoryBot.create(:teacher, trs_first_name: "Goku") }
      let!(:provider_led_teacher) { FactoryBot.create(:teacher, trs_first_name: "Vegeta") }
      let!(:untrained_mentor) { FactoryBot.create(:teacher, trs_first_name: "Piccolo") }
      let!(:untrained_ect) { FactoryBot.create(:teacher, trs_first_name: "Trunks") }

      before do
        school_led_ect_at_school_period = FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher: school_led_teacher)
        provider_led_ect_at_school_period = FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher: provider_led_teacher)
        FactoryBot.create(:training_period, :for_ect, :school_led, :unfinished, ect_at_school_period: school_led_ect_at_school_period)
        FactoryBot.create(:training_period, :for_ect, :unfinished, ect_at_school_period: provider_led_ect_at_school_period, school_partnership: school_partnership_2024)
        FactoryBot.create(:mentor_at_school_period, :unfinished, school:, teacher: untrained_mentor)
        FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher: untrained_ect)
      end

      it "returns every row with no available contract period" do
        expect(rows.map(&:teacher)).to contain_exactly(
          school_led_teacher,
          untrained_mentor,
          untrained_ect
        )
        expect(rows.map(&:teacher)).not_to include(provider_led_teacher)
        expect(rows.map(&:contract_period_name)).to all(eq("Not available"))
      end

      context "when also filtering by the mentor role" do
        let(:role) { "mentor" }

        it { expect(rows.map(&:teacher)).to eq([untrained_mentor]) }
      end
    end

    context "when searching by API training record ID" do
      let(:query_string) { "323e4567-e89b-12d3-a456-426614174000" }
      let!(:matching_teacher) do
        FactoryBot.create(
          :teacher,
          trs_first_name: "Gohan",
          api_mentor_training_record_id: query_string
        )
      end
      let!(:other_teacher) do
        FactoryBot.create(:teacher, trs_first_name: "Trunks", trn: "7654321")
      end

      before do
        FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher: matching_teacher)
        FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher: other_teacher)
      end

      it "returns the matching teacher at the school" do
        expect(rows.map(&:teacher)).to eq([matching_teacher])
        expect(rows.map(&:teacher)).not_to include(other_teacher)
      end
    end
  end

  describe "#has_current_teachers?" do
    context "when the school has a current role period" do
      before { FactoryBot.create(:ect_at_school_period, :unfinished, school:) }

      it { expect(described_class.new(school:).has_current_teachers?).to be(true) }
    end

    context "when the school only has future role periods" do
      before do
        FactoryBot.create(
          :mentor_at_school_period,
          school:,
          started_on: Date.tomorrow,
          finished_on: nil
        )
      end

      it { expect(described_class.new(school:).has_current_teachers?).to be(false) }
    end
  end
end
