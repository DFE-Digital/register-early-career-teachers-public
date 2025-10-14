RSpec.describe SandboxSeedData::TeacherHistories do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }
  let!(:teachers) { FactoryBot.create_list(:teacher, 1) }
  let!(:school_partnerships) { FactoryBot.create_list(:school_partnership, 2) }
  let!(:appropriate_bodies) { FactoryBot.create_list(:appropriate_body, 2) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  describe "#plant" do
    subject(:plant) { instance.plant }

    it { expect { plant }.to change(TrainingPeriod, :count).by(Teacher.count) }
    it { expect { plant }.to change { ECTAtSchoolPeriod.count + MentorAtSchoolPeriod.count }.by(Teacher.count) }

    context "when creating ECTAtSchoolPeriod records" do
      before { allow(Faker::Boolean).to receive(:boolean).and_return(true) }

      it { expect { plant }.to change(ECTAtSchoolPeriod, :count).by(Teacher.count) }
    end

    context "when creating MentorAtSchoolPeriod records" do
      before { allow(Faker::Boolean).to receive(:boolean).and_return(false) }

      it { expect { plant }.to change(MentorAtSchoolPeriod, :count).by(Teacher.count) }
    end

    context "when creating TrainingPeriod records without a finished_on" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.3).and_return(true)
      end

      it { expect { plant }.to change(TrainingPeriod.where(finished_on: nil), :count).by(Teacher.count) }
    end

    context "when creating TrainingPeriod records with a finished_on" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.3).and_return(false)
      end

      it { expect { plant }.to change(TrainingPeriod.where.not(finished_on: nil), :count).by(Teacher.count) }
    end

    context "when creating withdrawn TrainingPeriod records" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.2).and_return(true)
      end

      it { expect { plant }.to change(TrainingPeriod.where.not(withdrawn_at: nil), :count).by(Teacher.count) }
    end

    context "when creating deferred TrainingPeriod records" do
      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.2).and_return(false)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.15).and_return(true)
      end

      it { expect { plant }.to change(TrainingPeriod.where.not(deferred_at: nil), :count).by(Teacher.count) }
    end

    context "when creating active TrainingPeriod records" do
      let!(:teachers) { FactoryBot.create_list(:teacher, 1) }

      before do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.2).and_return(false)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.15).and_return(false)
      end

      it { expect { plant }.to change(TrainingPeriod.where(deferred_at: nil, withdrawn_at: nil), :count).by(Teacher.count) }
    end

    context "when setting eligible for funding" do
      before do
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.2).and_return(false)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.15).and_return(false)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.3).and_return(false)
        allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.65).and_return(true)
      end

      context "for ECT" do
        before do
          allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.5).and_return(true)
        end

        it "sets eligible for funding for ECT" do
          freeze_time
          plant
          teacher = teachers.first.reload
          expect(teacher.ect_first_became_eligible_for_training_at).to eq(3.months.ago)
        end
      end

      context "for Mentor" do
        before do
          allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.5).and_return(false)
        end

        it "sets eligible for funding for Mentor" do
          freeze_time
          plant
          teacher = teachers.first.reload
          expect(teacher.mentor_first_became_eligible_for_training_at).to eq(3.months.ago)
        end
      end
    end

    it "logs the creation of teacher histories" do
      plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting teacher histories/).once

      training_period = TrainingPeriod.all.sample
      training_status = ::API::TrainingPeriods::TrainingStatus.new(training_period:).status
      expect(logger).to have_received(:info).with(/(training period - provider-led - #{training_status})/).at_least(:once)
      expect(logger).to have_received(:info).with(/trained by #{training_period.school_partnership.active_lead_provider.lead_provider.name} \(LP\)/).at_least(:once)
      expect(logger).to have_received(:info).with(/and #{training_period.school_partnership.delivery_partner.name} \(DP\)/).at_least(:once)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any training periods or school periods" do
        expect { instance.plant }.not_to change(TrainingPeriod, :count)
        expect { instance.plant }.not_to change(ECTAtSchoolPeriod, :count)
        expect { instance.plant }.not_to change(MentorAtSchoolPeriod, :count)
      end
    end
  end
end
