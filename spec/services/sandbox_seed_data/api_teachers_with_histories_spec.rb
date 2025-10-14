RSpec.describe SandboxSeedData::APITeachersWithHistories do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }
  let!(:school_partnerships) { FactoryBot.create_list(:school_partnership, 5) }
  let!(:appropriate_bodies) { FactoryBot.create_list(:appropriate_body, 5) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    stub_const("#{described_class}::NUMBER_OF_RECORDS", 2)

    # Ensure the default and other schedules exist for some contract periods
    school_partnerships.each do |school_partnership|
      FactoryBot.create(:schedule, contract_period: school_partnership.contract_period)
      FactoryBot.create(:schedule, contract_period: school_partnership.contract_period, identifier: Schedule.identifiers.keys.sample)
    end
  end

  describe "#plant" do
    subject(:plant) { instance.plant }

    context "when creating teachers in every contract period" do
      it "creates correct data" do
        plant

        expect(SchoolPartnership.all.map(&:contract_period).uniq).to match_array(TrainingPeriod.all.map(&:contract_period).uniq)
      end
    end

    context "when creating teachers with uplifts" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
      end

      it "creates correct data" do
        plant

        expect(Teacher.all.map(&:ect_pupil_premium_uplift).uniq).to contain_exactly(true, false)
      end
    end

    context "when creating teachers with different schedules" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.8).and_return(false)
      end

      it "creates correct data" do
        plant

        expect(TrainingPeriod.provider_led_training_programme.map(&:schedule).map(&:identifier).uniq.size).to be > 1
      end
    end

    context "when creating teachers with `training_record_id`" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.15).and_return(false)
      end

      it "creates correct data" do
        plant

        expect(Teacher.where(api_ect_training_record_id: nil, api_mentor_training_record_id: nil)).to be_empty
      end
    end

    context "when creating teachers with `cohort_changed_after_payments_frozen`" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(false)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.1).and_return(true)
      end

      it "creates correct data" do
        plant

        expect(Teacher.all.map(&:ect_payments_frozen_year).uniq).not_to be_nil
      end
    end

    context "when creating teachers with `teacher_id_changes`" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(false)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.15).and_return(true)
      end

      it "creates correct data" do
        expect {
          plant
        }.to change(TeacherIdChange, :count)
      end
    end

    context "when creating teachers with two enrolments" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(false)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.1).and_return(true)
      end

      it "creates correct data" do
        plant

        expect(Teacher.joins(:ect_at_school_periods, :mentor_at_school_periods).count).to be > 0
      end
    end

    context "when creating ECTAtSchoolPeriod records" do
      before { allow(Faker::Boolean).to receive(:boolean).and_return(true) }

      it { expect { plant }.to change(ECTAtSchoolPeriod, :count).by(10) }
    end

    context "when creating MentorAtSchoolPeriod records" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(false)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.20).and_return(true)
      end

      it { expect { plant }.to change(MentorAtSchoolPeriod, :count).by(10) }
    end

    context "when assigning ECTs to Mentors" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(false)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.30).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.20).and_return(true)

        # Create some ongoing ECT periods in the future to increase chances of assignment
        school_partnerships.each do |school_partnership|
          school = school_partnership.school
          FactoryBot.create(:ect_at_school_period, :ongoing, school:, started_on: 6.months.from_now)
        end
      end

      it { expect { plant }.to change(MentorshipPeriod, :count).by(5) }
    end

    context "when creating TrainingPeriod records without a finished_on" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.3).and_return(true)
      end

      it { expect { plant }.to change(TrainingPeriod.where(finished_on: nil), :count).by(20) }
    end

    context "when creating TrainingPeriod records with a finished_on" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.3).and_return(false)
      end

      it { expect { plant }.to change(TrainingPeriod.where.not(finished_on: nil), :count).by(20) }
    end

    context "when creating withdrawn TrainingPeriod records" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.2).and_return(true)
      end

      it { expect { plant }.to change(TrainingPeriod.where.not(withdrawn_at: nil), :count).by(20) }
    end

    context "when creating deferred TrainingPeriod records" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.2).and_return(false)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.15).and_return(true)
      end

      it { expect { plant }.to change(TrainingPeriod.where.not(deferred_at: nil), :count).by(20) }
    end

    context "when creating active TrainingPeriod records" do
      let!(:teachers) { FactoryBot.create_list(:teacher, 1) }

      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.2).and_return(false)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.15).and_return(false)
      end

      it { expect { plant }.to change(TrainingPeriod.where(deferred_at: nil, withdrawn_at: nil), :count).by(20) }
    end

    it "logs the creation of api teachers records" do
      plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting api teachers with histories/).once

      training_period = TrainingPeriod.all.sample
      training_status = ::API::TrainingPeriods::TrainingStatus.new(training_period:).status
      expect(logger).to have_received(:info).with(/(training period - provider-led - #{training_status})/).at_least(:once)
      expect(logger).to have_received(:info).with(/trained by #{training_period.school_partnership.active_lead_provider.lead_provider.name} \(LP\)/).at_least(:once)
      expect(logger).to have_received(:info).with(/and #{training_period.school_partnership.delivery_partner.name} \(DP\)/).at_least(:once)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any teachers, training periods or school periods" do
        expect { instance.plant }.not_to change(Teacher, :count)
        expect { instance.plant }.not_to change(TrainingPeriod, :count)
        expect { instance.plant }.not_to change(ECTAtSchoolPeriod, :count)
        expect { instance.plant }.not_to change(MentorAtSchoolPeriod, :count)
      end
    end
  end
end
