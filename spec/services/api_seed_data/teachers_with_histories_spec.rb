RSpec.describe APISeedData::TeachersWithHistories do
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
      FactoryBot.create(:schedule, contract_period: school_partnership.contract_period, identifier: Schedule.excluding_replacement_schedules.identifiers.keys.sample)
    end
  end

  describe "#plant" do
    subject(:plant) { instance.plant }

    it "does not create data when already present" do
      expect { instance.plant }.to change(TrainingPeriod, :count)
      expect { instance.plant }.not_to change(TrainingPeriod, :count)
    end

    context "when creating teachers in every contract period" do
      it "creates correct data" do
        plant

        expect(SchoolPartnership.all.map(&:contract_period).uniq).to match_array(TrainingPeriod.all.map(&:contract_period).uniq)
      end
    end

    context "when creating teachers with pupil premium uplifts" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 1.0)
        stub_const("#{described_class}::ECT_ELIGIBLE_FOR_TRAINING_RATIO", 1.0)
        stub_const("#{described_class}::PUPIL_PREMIUM_UPLIFT_RATIO", 1.0)
      end

      it "creates correct data" do
        plant

        expect(Teacher.where(pupil_premium_uplift: true)).to exist
      end
    end

    context "when creating teachers with sparsity uplifts" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 1.0)
        stub_const("#{described_class}::ECT_ELIGIBLE_FOR_TRAINING_RATIO", 1.0)
        stub_const("#{described_class}::SPARSITY_UPLIFT_RATIO", 1.0)
      end

      it "creates correct data" do
        plant

        expect(Teacher.where(sparsity_uplift: true)).to exist
      end
    end

    context "when creating teachers with different schedules" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 1.0)
        stub_const("#{described_class}::SCHEDULE_RATIO", 0.0)
      end

      it "creates correct data" do
        plant

        expect(TrainingPeriod.provider_led_training_programme.map(&:schedule).map(&:identifier).uniq.size).to be > 1
      end
    end

    context "when creating teachers with `training_record_id`" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 1.0)
        stub_const("#{described_class}::TEACHER_ID_CHANGE_RATIO", 0.0)
      end

      it "creates correct data" do
        plant

        expect(Teacher.where(api_ect_training_record_id: nil, api_mentor_training_record_id: nil)).to be_empty
      end
    end

    context "when creating teachers with `cohort_changed_after_payments_frozen`" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 0.0)
        stub_const("#{described_class}::ECT_MENTOR_SCHOOL_PERIOD_TRAIT_RATIO", 1.0)
      end

      it "creates correct data" do
        plant

        expect(Teacher.all.map(&:ect_payments_frozen_year).uniq).not_to be_nil
      end
    end

    context "when creating teachers with `teacher_id_changes`" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 0.0)
        stub_const("#{described_class}::TEACHER_ID_CHANGE_RATIO", 1.0)
      end

      it "creates correct data" do
        expect {
          plant
        }.to change(TeacherIdChange, :count)
      end
    end

    context "when creating teachers with two enrolments" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 0.0)
        stub_const("#{described_class}::OPTIONAL_ECT_TRAINING_RATIO", 1.0)
      end

      it "creates correct data" do
        plant

        expect(Teacher.joins(:ect_at_school_periods, :mentor_at_school_periods).count).to be > 0
      end
    end

    context "when creating ECTAtSchoolPeriod records" do
      before { stub_const("#{described_class}::ECT_MENTOR_RATIO", 1.0) }

      it { expect { plant }.to change(ECTAtSchoolPeriod, :count).by(10) }
    end

    context "when creating MentorAtSchoolPeriod records" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 0.0)
        stub_const("#{described_class}::ASSIGN_ECT_TO_MENTOR_RATIO", 1.0)
      end

      it { expect { plant }.to change(MentorAtSchoolPeriod, :count).by(10) }
    end

    context "when assigning ECTs to Mentors" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 0.0)
        stub_const("#{described_class}::FINISHED_PERIOD_RATIO", 1.0)
        stub_const("#{described_class}::ASSIGN_ECT_TO_MENTOR_RATIO", 1.0)

        # Create ECT periods that will match the mentor periods created by the seed data
        # The seed creates mentor periods starting in September of the contract_period year
        school_partnerships.each do |school_partnership|
          school = school_partnership.school
          contract_period = school_partnership.contract_period
          started_on = Date.new(contract_period.year, 9, 15)
          # finished_on must be before the mentor's finished_on which is started_on + 200..300 days
          FactoryBot.create(:ect_at_school_period, school:, started_on:, finished_on: started_on + 150.days)
        end
      end

      it { expect { plant }.to change(MentorshipPeriod, :count).by_at_least(1) }

      it "only creates mentorship periods where mentor and mentee school periods are for the same school" do
        plant

        cross_school_count = MentorshipPeriod
          .joins(:mentee, :mentor)
          .where("mentor_at_school_periods.school_id <> ect_at_school_periods.school_id")
          .count

        expect(cross_school_count).to eq(0)
      end
    end

    context "when creating TrainingPeriod records without a finished_on" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 1.0)
        stub_const("#{described_class}::OPTIONAL_MENTOR_TRAINING_RATIO", 1.0)
        stub_const("#{described_class}::FINISHED_PERIOD_RATIO", 0.0)
      end

      it { expect { plant }.to change(TrainingPeriod.where(finished_on: nil), :count).by(20) }
    end

    context "when creating TrainingPeriod records with a finished_on" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 1.0)
        stub_const("#{described_class}::OPTIONAL_MENTOR_TRAINING_RATIO", 1.0)
        stub_const("#{described_class}::FINISHED_PERIOD_RATIO", 1.0)
      end

      it { expect { plant }.to change(TrainingPeriod.where.not(finished_on: nil), :count).by(20) }
    end

    context "when creating withdrawn TrainingPeriod records" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 1.0)
        stub_const("#{described_class}::OPTIONAL_MENTOR_TRAINING_RATIO", 1.0)
        stub_const("#{described_class}::WITHDRAWN_RATIO", 1.0)
        stub_const("#{described_class}::LATE_START_RATIO", 0)

        # Withdrawn TrainingPeriod records can only be created if the
        # started_on is not in the future
        latest_contract_period = ContractPeriod.order(year: :desc).first
        travel_to Date.new(latest_contract_period.year, 12, 31)
      end

      it { expect { plant }.to change(TrainingPeriod.where.not(withdrawn_at: nil), :count).by(20) }
    end

    context "when creating deferred TrainingPeriod records" do
      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 1.0)
        stub_const("#{described_class}::OPTIONAL_MENTOR_TRAINING_RATIO", 1.0)
        stub_const("#{described_class}::WITHDRAWN_RATIO", 0.0)
        stub_const("#{described_class}::DEFERRED_RATIO", 1.0)
        stub_const("#{described_class}::LATE_START_RATIO", 0)

        # Deferred TrainingPeriod records can only be created if the
        # started_on is not in the future
        latest_contract_period = ContractPeriod.order(year: :desc).first
        travel_to Date.new(latest_contract_period.year, 12, 31)
      end

      it { expect { plant }.to change(TrainingPeriod.where.not(deferred_at: nil), :count).by(20) }
    end

    context "when creating active TrainingPeriod records" do
      let!(:teachers) { FactoryBot.create_list(:teacher, 1) }

      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 1.0)
        stub_const("#{described_class}::OPTIONAL_MENTOR_TRAINING_RATIO", 1.0)
        stub_const("#{described_class}::WITHDRAWN_RATIO", 0.0)
        stub_const("#{described_class}::DEFERRED_RATIO", 0.0)
      end

      it { expect { plant }.to change(TrainingPeriod.where(deferred_at: nil, withdrawn_at: nil), :count).by(20) }
    end

    context "when creating teachers with induction period" do
      let!(:school_partnerships) do
        # Create partnerships with past contract periods to ensure induction periods can be created
        ContractPeriod.all.map do |contract_period|
          year = contract_period.year
          FactoryBot.create(:schedule, contract_period:)
          FactoryBot.create(:schedule, contract_period:, identifier: Schedule.excluding_replacement_schedules.identifiers.keys.sample)
          FactoryBot.create(:school_partnership, :for_year, year:)
        end
      end

      before do
        stub_const("#{described_class}::ECT_MENTOR_RATIO", 1.0)
        stub_const("#{described_class}::ECT_INDUCTION_RATIO", 1.0)
      end

      it { expect { plant }.to change(InductionPeriod, :count).by(school_partnerships.count * 2) }
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
