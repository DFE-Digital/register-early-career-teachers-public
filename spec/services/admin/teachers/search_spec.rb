RSpec.describe Admin::Teachers::Search do
  subject { described_class.new(query_string:, role:, contract_period:) }

  let(:query_string) { nil }
  let(:role) { nil }
  let(:contract_period) { nil }

  describe "#search" do
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
        matching_rows = subject.search.select { |row| row.teacher == teacher }

        expect(matching_rows.map(&:role_name)).to eq(["Early career teacher", "Mentor"])
        expect(matching_rows.map(&:contract_period_name)).to eq(%w[2024 2025])
      end
    end

    context "when a teacher has no role history" do
      let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }

      it "returns a no role assigned row" do
        matching_rows = subject.search.select { |row| row.teacher == teacher }

        expect(matching_rows.map(&:role_name)).to eq(["No role assigned"])
        expect(matching_rows.map(&:contract_period_name)).to eq([nil])
      end
    end

    context "when sorting rows" do
      let!(:sauske) { FactoryBot.create(:teacher, trs_first_name: "Sasuke", trs_last_name: "Uchiha") }
      let!(:naruto) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
      let!(:sauske_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: sauske) }
      let!(:naruto_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: naruto) }

      before do
        [sauske_ect_at_school_period, naruto_ect_at_school_period].each do |ect_at_school_period|
          contract_period = FactoryBot.create(:contract_period, year: 2024)
          school_partnership = FactoryBot.create(
            :school_partnership,
            :with_active_lead_provider,
            active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period:),
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
        expect(subject.search.map(&:name)).to eq(["Naruto Uzumaki", "Sasuke Uchiha"])
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
        expect(subject.search.map(&:role_name)).to eq(%w[Mentor])
        expect(subject.search.map(&:contract_period_name)).to eq(%w[2025])
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

        contract_period = FactoryBot.create(:contract_period, year: 2024)
        school_partnership = FactoryBot.create(
          :school_partnership,
          :with_active_lead_provider,
          active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period:),
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
        expect(subject.search.map(&:teacher)).to eq([school_led_teacher])
        expect(subject.search.map(&:contract_period_name)).to eq(["Not available"])
      end
    end

    context "when a mentor has no training period" do
      let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }

      before do
        FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:)
      end

      it "does not return not available" do
        matching_rows = subject.search.select { |row| row.teacher == teacher }

        expect(matching_rows.map(&:role_name)).to eq(%w[Mentor])
        expect(matching_rows.map(&:contract_period_name)).to eq([nil])
      end
    end

    context "with a search query" do
      context "when it is an exact 7 digit TRN" do
        let(:query_string) { "1234567" }
        let!(:teacher) { FactoryBot.create(:teacher, trn: "1234567") }
        let!(:other_teacher) { FactoryBot.create(:teacher, trn: "7654321", trs_first_name: "1234567", trs_last_name: "Teacher") }
        let!(:teacher_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:) }
        let!(:other_teacher_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: other_teacher) }

        before do
          [teacher_ect_at_school_period, other_teacher_ect_at_school_period].each do |ect_at_school_period|
            contract_period = FactoryBot.create(:contract_period, year: 2024)
            school_partnership = FactoryBot.create(
              :school_partnership,
              :with_active_lead_provider,
              active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period:),
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

        it "matches by TRN only" do
          expect(subject.search.map(&:teacher)).to eq([teacher])
        end
      end

      context "when it is a partial API participant ID" do
        let(:query_string) { "4266141740" }
        let!(:teacher) { FactoryBot.create(:teacher, api_id: "123e4567-e89b-12d3-a456-426614174000") }
        let!(:other_teacher) { FactoryBot.create(:teacher, api_id: "999e4567-e89b-12d3-a456-426614174999") }
        let!(:teacher_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:) }
        let!(:other_teacher_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: other_teacher) }

        before do
          [teacher_ect_at_school_period, other_teacher_ect_at_school_period].each do |ect_at_school_period|
            contract_period = FactoryBot.create(:contract_period, year: 2024)
            school_partnership = FactoryBot.create(
              :school_partnership,
              :with_active_lead_provider,
              active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period:),
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

        it "matches a partial API participant ID" do
          expect(subject.search.map(&:teacher)).to eq([teacher])
        end
      end
    end
  end
end
