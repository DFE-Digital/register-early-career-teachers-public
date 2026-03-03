RSpec.describe APISeedData::SITBecomeMentorScenarios do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }

  let(:sit_year) { 2022 }
  let(:mentor_year) { 2024 }

  let(:sit_school) do
    FactoryBot.create(:school, induction_tutor_name: "Jane Smith", induction_tutor_email: "jane.smith@example.com")
  end

  let!(:school_partnership) do
    FactoryBot.create(:school_partnership, :for_year, year: sit_year, lead_provider:, delivery_partner:, school: sit_school)
  end

  let(:mentor_teacher) { FactoryBot.create(:teacher, :with_realistic_name) }

  let(:mentor_school) { FactoryBot.create(:school) }

  let!(:mentor_period) do
    mentor_at_school = FactoryBot.create(
      :mentor_at_school_period,
      teacher: mentor_teacher,
      school: mentor_school
    )

    lpdp = FactoryBot.create(
      :lead_provider_delivery_partnership,
      :for_year,
      year: mentor_year,
      lead_provider:
    )

    partnership = FactoryBot.create(
      :school_partnership,
      school: mentor_school,
      lead_provider_delivery_partnership: lpdp
    )

    FactoryBot.create(
      :training_period,
      :for_mentor,
      :provider_led,
      :with_schedule,
      mentor_at_school_period: mentor_at_school,
      school_partnership: partnership,
      started_on: mentor_at_school.started_on,
      finished_on: mentor_at_school.finished_on
    )

    mentor_at_school
  end

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  describe "#plant" do
    it "updates mentor teacher name to match the SIT" do
      instance.plant

      mentor_teacher.reload
      expect(mentor_teacher.trs_first_name).to eq("Jane")
      expect(mentor_teacher.trs_last_name).to eq("Smith")
    end

    it "updates mentor period email to match the SIT" do
      instance.plant

      mentor_period.reload
      expect(mentor_period.email).to eq("jane.smith@example.com")
    end

    it "logs the planting info" do
      instance.plant

      expect(logger).to have_received(:info).with(/Planting api mentor seed scenarios/).once
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not update any teachers" do
        instance.plant

        mentor_teacher.reload
        expect(mentor_teacher.trs_first_name).not_to eq("Jane")
      end
    end

    context "when the school has no SIT name" do
      let(:sit_school) do
        FactoryBot.create(:school, :without_induction_tutor)
      end

      it "does not update any teachers" do
        original_first_name = mentor_teacher.trs_first_name

        instance.plant

        mentor_teacher.reload
        expect(mentor_teacher.trs_first_name).to eq(original_first_name)
      end
    end

    context "when no mentor periods exist for the lead provider" do
      let!(:mentor_period) { nil }

      it "does not raise an error" do
        expect { instance.plant }.not_to raise_error
      end
    end

    context "when the SIT name includes a title" do
      let(:sit_school) do
        FactoryBot.create(:school, induction_tutor_name: "Dr. Jane Smith", induction_tutor_email: "jane.smith@example.com")
      end

      it "parses the name using FullNameParser stripping the title" do
        instance.plant

        mentor_teacher.reload
        expect(mentor_teacher.trs_first_name).to eq("Jane")
        expect(mentor_teacher.trs_last_name).to eq("Smith")
      end
    end

    context "mentors who became SITs" do
      let(:sit_year) { 2024 }
      let(:mentor_year) { 2022 }

      it "updates mentor teacher name to match the SIT" do
        instance.plant

        mentor_teacher.reload
        expect(mentor_teacher.trs_first_name).to eq("Jane")
        expect(mentor_teacher.trs_last_name).to eq("Smith")
      end

      it "updates mentor period email to match the SIT" do
        instance.plant

        mentor_period.reload
        expect(mentor_period.email).to eq("jane.smith@example.com")
      end
    end
  end
end
