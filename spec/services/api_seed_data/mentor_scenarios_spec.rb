RSpec.describe APISeedData::MentorScenarios do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  let(:contract_period_2022) { FactoryBot.create(:contract_period, year: 2022) }
  let(:contract_period_2023) { FactoryBot.create(:contract_period, year: 2023) }
  let(:contract_period_2025) { FactoryBot.create(:contract_period, year: 2025) }

  let!(:lead_providers) do
    FactoryBot.create_list(:lead_provider, 2).each do |lead_provider|
      [contract_period_2022, contract_period_2023, contract_period_2025].each do |contract_period|
        FactoryBot.create_list(:lead_provider_delivery_partnership, 2, :for_year, lead_provider:, year: contract_period.year)
      end
    end
  end

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    # Create delivery partners and appropriate bodies for induction periods
    FactoryBot.create_list(:delivery_partner, 3)
    FactoryBot.create_list(:appropriate_body, 2)
  end

  describe "#plant" do
    it "does not create data when already present" do
      expect { instance.plant }.to change(Teacher, :count)
      expect { instance.plant }.not_to change(Teacher, :count)
    end

    it "logs the creation of scenarios" do
      instance.plant

      expect(logger).to have_received(:info).with(/Planting api mentor seed scenarios/).once
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any teachers" do
        expect { instance.plant }.not_to change(Teacher, :count)
      end
    end

    it "creates teachers with both ECT and mentor training record IDs for each lead provider and ECT year" do
      teacher_ids_before = Teacher.pluck(:id)

      instance.plant

      new_teachers = Teacher.where.not(id: teacher_ids_before)

      lead_providers.each do |lead_provider|
        [2022, 2023].each do |ect_year|
          teachers_for_lp_and_year = new_teachers
            .joins(ect_at_school_periods: { training_periods: { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } } })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .where(training_periods: { started_on: Date.new(ect_year, 9, 1) })
            .distinct

          expect(teachers_for_lp_and_year.count).to eq(2)
        end
      end
    end

    it "sets both api training record IDs on each created teacher" do
      teacher_ids_before = Teacher.pluck(:id)

      instance.plant

      new_teachers = Teacher.where.not(id: teacher_ids_before)

      expect(new_teachers).to all(
        have_attributes(
          api_ect_training_record_id: be_present,
          api_mentor_training_record_id: be_present
        )
      )
    end

    it "creates completed ECT induction periods with pass outcome" do
      teacher_ids_before = Teacher.pluck(:id)

      instance.plant

      new_teachers = Teacher.where.not(id: teacher_ids_before)

      new_teachers.each do |teacher|
        expect(teacher.induction_periods.count).to eq(1)
        expect(teacher.induction_periods.first.outcome).to eq("pass")
      end
    end

    it "creates finished ECT training periods and ongoing mentor training periods" do
      teacher_ids_before = Teacher.pluck(:id)

      instance.plant

      new_teachers = Teacher.where.not(id: teacher_ids_before)

      new_teachers.each do |teacher|
        ect_training = teacher.ect_training_periods
        expect(ect_training.count).to eq(1)
        expect(ect_training.first.finished_on).to be_present
        expect(ect_training.first.training_programme).to eq("provider_led")

        mentor_training = teacher.mentor_training_periods
        expect(mentor_training.count).to eq(1)
        expect(mentor_training.first.finished_on).to be_nil
        expect(mentor_training.first.training_programme).to eq("provider_led")
      end
    end
  end
end
