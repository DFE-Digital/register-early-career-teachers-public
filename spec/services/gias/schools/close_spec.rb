RSpec.describe GIAS::Schools::Close do
  describe "#close" do
    subject(:service) { described_class.new(gias_school).close! }

    let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :closed) }
    let(:school) { gias_school.school }
    let!(:mentors) { FactoryBot.create_list(:mentor_at_school_period, 3, :ongoing, :with_training_period, school:) }
    let!(:ects) { FactoryBot.create_list(:ect_at_school_period, 3, :ongoing, :with_training_period, school:) }
    let!(:unstarted_mentors) { FactoryBot.create_list(:mentor_at_school_period, 2, :with_training_period, school:, started_on: Date.tomorrow) }
    let!(:unstarted_ects) { FactoryBot.create_list(:ect_at_school_period, 2, :with_training_period, school:, started_on: Date.tomorrow) }
    let(:mentor_finish_service) { instance_double(MentorAtSchoolPeriods::Finish) }
    let(:ect_finish_service) { instance_double(ECTAtSchoolPeriods::Finish) }
    let(:mentorship_finished_on) { nil }

    before do
      create_mentorship_period(ects, mentors)
      create_mentorship_period(unstarted_ects, unstarted_mentors, finished_on: nil)

      allow(MentorAtSchoolPeriods::Finish).to receive(:new).and_return(mentor_finish_service)
      allow(mentor_finish_service).to receive(:finish_periods_at_reported_school!)

      allow(ECTAtSchoolPeriods::Finish).to receive(:new).and_return(ect_finish_service)
      allow(ect_finish_service).to receive(:finish!)
    end

    it "destroys unstarted periods" do
      expect(MentorAtSchoolPeriods::Destroy).to receive(:call).twice
      expect(ECTAtSchoolPeriods::Destroy).to receive(:call).twice

      service
    end

    it "finishes ongoing periods" do
      expect(mentor_finish_service).to receive(:finish_periods_at_reported_school!).exactly(3).times
      expect(ect_finish_service).to receive(:finish!).exactly(3).times

      service
    end

    it_behaves_like "records a school closed event"

    context "when the school is open" do
      let(:gias_school) { FactoryBot.create(:gias_school, :open, :with_school) }

      it_behaves_like "does not destroy or finish any periods"

      it "does not record an event" do
        expect { service }.not_to(change(Event, :count))
      end
    end

    context "when the school has a successor" do
      before do
        FactoryBot.create(:gias_school_link, :successor, from_gias_school: gias_school)
      end

      it_behaves_like "does not destroy or finish any periods"

      it "does not record an event" do
        expect { service }.not_to(change(Event, :count))
      end
    end

    context "when the school has a closure event" do
      before do
        FactoryBot.create(:event, event_type: :school_closed, school: gias_school.school)
      end

      it_behaves_like "does not destroy or finish any periods"

      it "does not record an event" do
        expect { service }.not_to(change(Event, :count))
      end
    end

    context "when there are no ongoing mentor_at_school periods" do
      let(:mentors) { [] }

      it "destroys unstarted periods" do
        expect(MentorAtSchoolPeriods::Destroy).to receive(:call).twice
        expect(ECTAtSchoolPeriods::Destroy).to receive(:call).twice

        service
      end

      it "only finishes ongoing ECT periods" do
        expect(mentor_finish_service).not_to receive(:finish_periods_at_reported_school!)
        expect(ect_finish_service).to receive(:finish!)

        service
      end

      it_behaves_like "records a school closed event"
    end

    context "when there are no ongoing ect_at_school periods" do
      let(:ects) { [] }

      it "destroys unstarted periods" do
        expect(MentorAtSchoolPeriods::Destroy).to receive(:call).twice
        expect(ECTAtSchoolPeriods::Destroy).to receive(:call).twice

        service
      end

      it "only finishes ongoing Mentor periods" do
        expect(mentor_finish_service).to receive(:finish_periods_at_reported_school!)
        expect(ect_finish_service).not_to receive(:finish!)

        service
      end

      it_behaves_like "records a school closed event"
    end

    context "when there are no unstarted ECT periods" do
      let(:unstarted_ects) { [] }

      it "only destroys unstarted mentor periods" do
        expect(MentorAtSchoolPeriods::Destroy).to receive(:call).twice
        expect(ECTAtSchoolPeriods::Destroy).not_to receive(:call)

        service
      end

      it "finishes ongoing periods" do
        expect(mentor_finish_service).to receive(:finish_periods_at_reported_school!).exactly(3).times
        expect(ect_finish_service).to receive(:finish!).exactly(3).times

        service
      end

      it_behaves_like "records a school closed event"
    end

    context "when there are no unstarted Mentor periods" do
      let(:unstarted_mentors) { [] }

      it "does not destroy unstarted periods" do
        expect(MentorAtSchoolPeriods::Destroy).not_to receive(:call)
        expect(ECTAtSchoolPeriods::Destroy).to receive(:call).twice

        service
      end

      it "finishes ongoing periods" do
        expect(mentor_finish_service).to receive(:finish_periods_at_reported_school!).exactly(3).times
        expect(ect_finish_service).to receive(:finish!).exactly(3).times

        service
      end

      it_behaves_like "records a school closed event"
    end

    context "when there are no unstarted or ongoing periods" do
      let!(:mentors) { FactoryBot.create_list(:mentor_at_school_period, 3, :with_training_period, school:, finished_on: Date.yesterday) }
      let!(:ects) { FactoryBot.create_list(:ect_at_school_period, 3, :with_training_period, school:, finished_on: Date.yesterday) }
      let(:unstarted_mentors) { [] }
      let(:unstarted_ects) { [] }
      let(:mentorship_finished_on) { Date.yesterday }

      it_behaves_like "does not destroy or finish any periods"
      it_behaves_like "records a school closed event"
    end
  end

  def create_mentorship_period(ects, mentors, finished_on: mentorship_finished_on)
    mentee = ects.first
    mentor = mentors.first

    return unless mentee.present? && mentor.present?

    started_on = [mentee.started_on, mentor.started_on].max

    attributes = { mentee:, mentor:, started_on:, finished_on: }.compact

    FactoryBot.create(:mentorship_period, **attributes)
  end
end
