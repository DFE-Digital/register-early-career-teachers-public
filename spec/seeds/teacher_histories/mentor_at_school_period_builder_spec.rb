describe TeacherHistories::MentorAtSchoolPeriodBuilder do
  let(:trn) { "1122334" }
  let(:trs_first_name) { "Clark" }
  let(:trs_last_name) { "Gable" }
  let(:full_name) { "#{trs_first_name} #{trs_last_name}" }

  let(:school) { FactoryBot.create(:school) }
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Lead provider one") }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Delivery partner one") }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let!(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

  let(:random_uuid) { SecureRandom.uuid }

  describe "adding training periods" do
    subject { teacher.mentor_at_school_periods[0].training_periods[0] }

    let(:teacher) do
      school_inner = school
      lead_provider_inner = lead_provider
      random_uuid_inner = random_uuid

      TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
        mentor_at_school_period(school_inner, "2024-01-01 -> 2025-03-03") do
          training_period(lead_provider_inner, 2025, "2024-01-03 -> 2025-03-01", ecf_end_induction_record_id: random_uuid_inner)
        end
      end
    end

    it "adds a training periods to the mentor at school period" do
      expect(teacher.mentor_at_school_periods[0].training_periods.count).to be(1)
    end

    it "is linked to the right lead provider" do
      expect(subject.lead_provider).to eql(lead_provider)
    end

    it "is linked to the right contract period" do
      expect(subject.contract_period).to eql(contract_period)
    end

    it "is linked to the right teacher" do
      expect(subject.teacher).to eql(teacher)
    end

    context "when there is a finish date" do
      it "has the right start date" do
        expect(subject.started_on).to eql(Date.new(2024, 1, 3))
      end

      it "has the right end date" do
        expect(subject.finished_on).to eql(Date.new(2025, 3, 1))
      end
    end

    context "when ongoing" do
      let(:teacher) do
        school_inner = school
        lead_provider_inner = lead_provider

        TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
          mentor_at_school_period(school_inner, "2024-01-01") do
            training_period(lead_provider_inner, 2025, "2024-01-03")
          end
        end
      end

      it "has the right start date" do
        expect(subject.started_on).to eql(Date.new(2024, 1, 3))
      end

      it "has the right end date" do
        expect(subject.finished_on).to be_nil
      end
    end
  end
end
