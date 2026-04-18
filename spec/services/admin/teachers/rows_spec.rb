RSpec.describe Admin::Teachers::Rows do
  subject(:rows_builder) { described_class.new(role:, contract_period:) }

  let(:role) { nil }
  let(:contract_period) { nil }
  let(:teachers) { Teacher.where(id: teacher_ids).preload(:induction_periods, { latest_ect_at_school_period: training_period_preload }, { latest_mentor_at_school_period: training_period_preload }) }
  let(:teacher_ids) { Teacher.select(:id) }
  let(:training_period_preload) do
    {
      latest_training_period: :schedule
    }
  end

  describe "#rows" do
    context "when a teacher has both ECT and mentor roles" do
      let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
      let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:) }
      let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:) }

      before do
        ect_contract_period = FactoryBot.create(:contract_period, year: 2024)
        ect_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: ect_contract_period),
          school: ect_at_school_period.school
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          :ongoing,
          ect_at_school_period:,
          school_partnership: ect_school_partnership
        )

        mentor_contract_period = FactoryBot.create(:contract_period, year: 2025)
        mentor_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: mentor_contract_period),
          school: mentor_at_school_period.school
        )

        FactoryBot.create(
          :training_period,
          :for_mentor,
          :ongoing,
          mentor_at_school_period:,
          school_partnership: mentor_school_partnership
        )
      end

      it "returns one row for each role" do
        matching_rows = rows_builder.rows(teachers).select { |row| row.teacher == teacher }

        expect(matching_rows.map(&:role_name)).to eq(["Early career teacher", "Mentor"])
        expect(matching_rows.map(&:contract_period_name)).to eq(%w[2024 2025])
      end
    end

    context "when a teacher has no role history" do
      let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }

      it "returns a no role assigned row" do
        matching_rows = rows_builder.rows(teachers).select { |row| row.teacher == teacher }

        expect(matching_rows.map(&:role_name)).to eq(["No role assigned"])
        expect(matching_rows.map(&:contract_period_name)).to eq([nil])
      end
    end

    context "when sorting rows" do
      let!(:sasuke) { FactoryBot.create(:teacher, trs_first_name: "Sasuke", trs_last_name: "Uchiha") }
      let!(:naruto) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
      let!(:sasuke_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: sasuke) }
      let!(:naruto_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: naruto) }

      before do
        [sasuke_ect_at_school_period, naruto_ect_at_school_period].each do |ect_at_school_period|
          role_contract_period = FactoryBot.create(:contract_period, year: 2024)
          school_partnership = FactoryBot.create(
            :school_partnership,
            :with_active_lead_provider,
            active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: role_contract_period),
            school: ect_at_school_period.school
          )

          FactoryBot.create(
            :training_period,
            :for_ect,
            :ongoing,
            ect_at_school_period:,
            school_partnership:
          )
        end
      end

      it "orders rows alphabetically by full name" do
        expect(rows_builder.rows(teachers).map(&:name)).to eq(["Naruto Uzumaki", "Sasuke Uchiha"])
      end
    end

    context "when a teacher has a later ect role period" do
      let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
      let!(:older_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 7, 31)) }
      let!(:latest_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: Date.new(2025, 1, 1)) }

      before do
        contract_period_2024 = FactoryBot.create(:contract_period, year: 2024)
        contract_period_2025 = FactoryBot.create(:contract_period, year: 2025)

        older_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period_2024),
          school: older_ect_at_school_period.school
        )

        latest_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period_2025),
          school: latest_ect_at_school_period.school
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          ect_at_school_period: older_ect_at_school_period,
          school_partnership: older_school_partnership,
          started_on: older_ect_at_school_period.started_on,
          finished_on: older_ect_at_school_period.finished_on
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          :ongoing,
          ect_at_school_period: latest_ect_at_school_period,
          school_partnership: latest_school_partnership
        )
      end

      it "shows the contract period from the latest ect role periods latest training period" do
        matching_rows = rows_builder.rows(teachers).select { |row| row.teacher == teacher }

        expect(matching_rows.map(&:contract_period_name)).to eq(%w[2025])
      end
    end

    context "when a teacher has a later mentor role period" do
      let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Kakashi", trs_last_name: "Hatake") }
      let!(:older_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 7, 31)) }
      let!(:latest_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, started_on: Date.new(2025, 1, 1)) }

      before do
        contract_period_2024 = FactoryBot.create(:contract_period, year: 2024)
        contract_period_2025 = FactoryBot.create(:contract_period, year: 2025)

        older_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period_2024),
          school: older_mentor_at_school_period.school
        )

        latest_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period_2025),
          school: latest_mentor_at_school_period.school
        )

        FactoryBot.create(
          :training_period,
          :for_mentor,
          mentor_at_school_period: older_mentor_at_school_period,
          school_partnership: older_school_partnership,
          started_on: older_mentor_at_school_period.started_on,
          finished_on: older_mentor_at_school_period.finished_on
        )

        FactoryBot.create(
          :training_period,
          :for_mentor,
          :ongoing,
          mentor_at_school_period: latest_mentor_at_school_period,
          school_partnership: latest_school_partnership
        )
      end

      it "shows the contract period from the latest mentor role periods latest training period" do
        matching_rows = rows_builder.rows(teachers).select { |row| row.teacher == teacher }

        expect(matching_rows.map(&:contract_period_name)).to eq(%w[2025])
      end
    end

    context "when filtering by role" do
      let(:role) { "mentor" }
      let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
      let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:) }
      let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:) }

      before do
        ect_contract_period = FactoryBot.create(:contract_period, year: 2024)
        ect_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: ect_contract_period),
          school: ect_at_school_period.school
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          :ongoing,
          ect_at_school_period:,
          school_partnership: ect_school_partnership
        )

        mentor_contract_period = FactoryBot.create(:contract_period, year: 2025)
        mentor_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: mentor_contract_period),
          school: mentor_at_school_period.school
        )

        FactoryBot.create(
          :training_period,
          :for_mentor,
          :ongoing,
          mentor_at_school_period:,
          school_partnership: mentor_school_partnership
        )
      end

      it "returns only mentor rows" do
        expect(rows_builder.rows(teachers).map(&:role_name)).to eq(%w[Mentor])
        expect(rows_builder.rows(teachers).map(&:contract_period_name)).to eq(%w[2025])
      end
    end

    context "when filtering by the not available contract period option" do
      let(:contract_period) { "not_available" }
      let!(:school_led_teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
      let!(:provider_led_teacher) { FactoryBot.create(:teacher, trs_first_name: "Sasuke", trs_last_name: "Uchiha") }
      let!(:school_led_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: school_led_teacher) }
      let!(:provider_led_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: provider_led_teacher) }

      before do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :ongoing,
          :school_led,
          ect_at_school_period: school_led_ect_at_school_period,
          started_on: school_led_ect_at_school_period.started_on
        )

        role_contract_period = FactoryBot.create(:contract_period, year: 2024)
        school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: role_contract_period),
          school: provider_led_ect_at_school_period.school
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          :ongoing,
          ect_at_school_period: provider_led_ect_at_school_period,
          school_partnership:
        )
      end

      it "returns only not available rows" do
        expect(rows_builder.rows(teachers).map(&:teacher)).to eq([school_led_teacher])
        expect(rows_builder.rows(teachers).map(&:contract_period_name)).to eq(["Not available"])
      end
    end
  end
end
