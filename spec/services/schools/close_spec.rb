RSpec.describe Schools::Close do
  subject(:service) { described_class.new(school) }

  let(:gias_school) { FactoryBot.create(:gias_school, :closed, :with_school) }
  let(:school) { gias_school.school }
  let!(:mentors) { FactoryBot.create_list(:mentor_at_school_period, 3, :ongoing, :with_training_period, school:) }
  let!(:ects) { FactoryBot.create_list(:ect_at_school_period, 3, :ongoing, :with_training_period, school:) }
  let!(:mentorship_period) { FactoryBot.create(:mentorship_period, mentee: ects.first, mentor: mentors.first) }
  let!(:unstarted_mentors) { FactoryBot.create_list(:mentor_at_school_period, 2, :with_training_period, school:, started_on: Date.tomorrow) }
  let!(:unstarted_ects) { FactoryBot.create_list(:ect_at_school_period, 2, :with_training_period, school:, started_on: Date.tomorrow) }
  let!(:unstarted_mentorship_period) { FactoryBot.create(:mentorship_period, mentee: unstarted_ects.first, mentor: unstarted_mentors.first) }
  let(:mentor_finish_service) { instance_double(MentorAtSchoolPeriods::Finish) }
  let(:ect_finish_service) { instance_double(ECTAtSchoolPeriods::Finish) }

  before do
    allow(MentorAtSchoolPeriods::Finish).to receive(:new).and_return(mentor_finish_service)
    allow(mentor_finish_service).to receive(:finish_periods_at_reported_school!)

    allow(ECTAtSchoolPeriods::Finish).to receive(:new).and_return(ect_finish_service)
    allow(ect_finish_service).to receive(:finish!)

    allow(MentorAtSchoolPeriods::Destroy).to receive(:call)
    allow(ECTAtSchoolPeriods::Destroy).to receive(:call)
  end

  describe "#call" do
    it "destroys unstarted periods" do
      service.call

      expect(MentorAtSchoolPeriods::Destroy).to have_received(:call).twice
      expect(ECTAtSchoolPeriods::Destroy).to have_received(:call).twice
    end

    it "finishes ongoing periods" do
      service.call

      expect(mentor_finish_service).to have_received(:finish_periods_at_reported_school!).exactly(3).times
      expect(ect_finish_service).to have_received(:finish!).exactly(3).times
    end

    context "when the school is open" do
      let(:gias_school) { FactoryBot.create(:gias_school, :open, :with_school) }

      it "does not destroy unstarted periods" do
        service.call

        expect(MentorAtSchoolPeriods::Destroy).not_to have_received(:call)
        expect(ECTAtSchoolPeriods::Destroy).not_to have_received(:call)
      end

      it "does not finish ongoing periods" do
        service.call

        expect(mentor_finish_service).not_to have_received(:finish_periods_at_reported_school!)
        expect(ect_finish_service).not_to have_received(:finish!)
      end
    end

    context "when the school is linked to another school" do
      before do
        FactoryBot.create(:gias_school_link, from_gias_school: gias_school)
      end

      it "does not destroy unstarted periods" do
        service.call

        expect(MentorAtSchoolPeriods::Destroy).not_to have_received(:call)
        expect(ECTAtSchoolPeriods::Destroy).not_to have_received(:call)
      end

      it "does not finish ongoing periods" do
        service.call

        expect(mentor_finish_service).not_to have_received(:finish_periods_at_reported_school!)
        expect(ect_finish_service).not_to have_received(:finish!)
      end
    end

    context "when there are no ongoing periods" do
      let(:mentors) { [] }
      let(:ects) { [] }
      let(:mentorship_period) { nil }

      it "destroys unstarted periods" do
        service.call

        expect(MentorAtSchoolPeriods::Destroy).to have_received(:call).twice
        expect(ECTAtSchoolPeriods::Destroy).to have_received(:call).twice
      end

      it "does not finish ongoing periods" do
        service.call

        expect(mentor_finish_service).not_to have_received(:finish_periods_at_reported_school!)
        expect(ect_finish_service).not_to have_received(:finish!)
      end
    end

    context "when all the periods are finished periods" do
      let!(:mentors) { FactoryBot.create_list(:mentor_at_school_period, 3, :with_training_period, school:, finished_on: Date.yesterday) }
      let!(:ects) { FactoryBot.create_list(:ect_at_school_period, 3, :with_training_period, school:, finished_on: Date.yesterday) }
      let!(:mentorship_period) { FactoryBot.create(:mentorship_period, mentee: ects.first, mentor: mentors.first, finished_on: 2.days.ago) }
      let(:unstarted_mentors) { [] }
      let(:unstarted_ects) { [] }
      let(:unstarted_mentorship_period) { nil }

      it "does not destroy unstarted periods" do
        service.call

        expect(MentorAtSchoolPeriods::Destroy).not_to have_received(:call)
        expect(ECTAtSchoolPeriods::Destroy).not_to have_received(:call)
      end

      it "does not finish ongoing periods" do
        service.call

        expect(mentor_finish_service).not_to have_received(:finish_periods_at_reported_school!)
        expect(ect_finish_service).not_to have_received(:finish!)
      end
    end

    context "when there are no unstarted periods" do
      let(:unstarted_mentors) { [] }
      let(:unstarted_ects) { [] }
      let(:unstarted_mentorship_period) { nil }

      it "destroys unstarted periods" do
        service.call

        expect(MentorAtSchoolPeriods::Destroy).not_to have_received(:call)
        expect(ECTAtSchoolPeriods::Destroy).not_to have_received(:call)
      end

      it "finishes ongoing periods" do
        service.call

        expect(mentor_finish_service).to have_received(:finish_periods_at_reported_school!).exactly(3).times
        expect(ect_finish_service).to have_received(:finish!).exactly(3).times
      end
    end
  end
end
