RSpec.describe Admin::Teachers::RowQuery do
  subject(:row_query) { described_class.new(matching_teacher_scope:, role:, contract_period:) }

  let(:matching_teacher_scope) { Teacher.unscoped }
  let(:role) { nil }
  let(:contract_period) { nil }

  describe "#relation" do
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
        expect(row_query.rows(row_query.relation).map(&:name)).to eq(["Naruto Uzumaki", "Sasuke Uchiha"])
      end
    end

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

      it "returns one row per role and counts rendered rows" do
        expect(row_query.relation.map { |row| [row.teacher_id, row.role, row.contract_period] }).to eq(
          [
            [teacher.id, "ect", "2024"],
            [teacher.id, "mentor", "2025"]
          ]
        )
        expect(row_query.count).to eq(2)
      end
    end

    context "when a teacher has no role history" do
      let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }

      it "returns a no role row" do
        expect(row_query.relation.map { |row| [row.teacher_id, row.role, row.contract_period] }).to eq(
          [
            [teacher.id, described_class::NO_ROLE_ASSIGNED, nil]
          ]
        )
        expect(row_query.count).to eq(1)
      end
    end

    context "when filters are applied" do
      let(:role) { "ect" }
      let(:contract_period) { described_class::CONTRACT_PERIOD_NOT_AVAILABLE }

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

        provider_led_contract_period = FactoryBot.create(:contract_period, year: 2024)
        provider_led_school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: provider_led_contract_period),
          school: provider_led_ect_at_school_period.school
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          :ongoing,
          ect_at_school_period: provider_led_ect_at_school_period,
          school_partnership: provider_led_school_partnership
        )
      end

      it "filters the rendered rows and keeps a row based count" do
        expect(row_query.relation.map { |row| [row.teacher_id, row.role, row.contract_period] }).to eq(
          [
            [school_led_teacher.id, "ect", described_class::CONTRACT_PERIOD_NOT_AVAILABLE]
          ]
        )
        expect(row_query.count).to eq(1)
      end
    end
  end
end
