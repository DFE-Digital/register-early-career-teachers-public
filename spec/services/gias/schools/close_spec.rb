RSpec.describe GIAS::Schools::Close do
  describe "#close" do
    subject(:service) { described_class.new(gias_school).close! }

    let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :closed, closed_on:) }
    let(:closed_on) { Date.current }
    let(:can_be_closed) { true }
    let(:school) { gias_school.school }
    let!(:mentors) { FactoryBot.create_list(:mentor_at_school_period, 3, :ongoing, :with_training_period, school:) }
    let!(:ects) { FactoryBot.create_list(:ect_at_school_period, 3, :ongoing, :with_training_period, school:) }
    let!(:unstarted_mentors) { FactoryBot.create_list(:mentor_at_school_period, 2, :with_training_period, school:, started_on: closed_on + 1.day) }
    let!(:unstarted_ects) { FactoryBot.create_list(:ect_at_school_period, 2, :with_training_period, school:, started_on: closed_on + 1.day) }
    let(:mentor_finish_service) { instance_double(MentorAtSchoolPeriods::Finish) }
    let(:ect_finish_service) { instance_double(ECTAtSchoolPeriods::Finish) }
    let(:mentorship_finished_on) { nil }

    before do
      create_mentorship_period(ects.first, mentors.first)

      allow(gias_school).to receive(:can_be_closed?).and_return(can_be_closed)

      allow(MentorAtSchoolPeriods::Finish).to receive(:new).and_return(mentor_finish_service)
      allow(mentor_finish_service).to receive(:finish_periods_at_reported_school!)

      allow(ECTAtSchoolPeriods::Finish).to receive(:new).and_return(ect_finish_service)
      allow(ect_finish_service).to receive(:finish!)
    end

    it { is_expected.to be_truthy }

    it_behaves_like "destroys unstarted mentor_at_school_periods"
    it_behaves_like "destroys unstarted ect_at_school_periods"
    it_behaves_like "finishes ongoing mentor_at_school_periods"
    it_behaves_like "finishes ongoing ect_at_school_periods"

    it_behaves_like "records a school closed event"

    context "when there are no ongoing mentor_at_school_periods" do
      let(:mentors) { [] }

      it { is_expected.to be_truthy }

      it_behaves_like "destroys unstarted mentor_at_school_periods"
      it_behaves_like "destroys unstarted ect_at_school_periods"
      it_behaves_like "finishes ongoing ect_at_school_periods"

      it "does not finish any mentor_at_school_periods" do
        expect(MentorAtSchoolPeriods::Finish).not_to receive(:new)

        service
      end

      it_behaves_like "records a school closed event"
    end

    context "when there are no ongoing ect_at_school_periods" do
      let(:ects) { [] }

      it { is_expected.to be_truthy }

      it_behaves_like "destroys unstarted mentor_at_school_periods"
      it_behaves_like "destroys unstarted ect_at_school_periods"
      it_behaves_like "finishes ongoing mentor_at_school_periods"

      it "does not finish any ect_at_school_periods" do
        expect(ECTAtSchoolPeriods::Finish).not_to receive(:new)

        service
      end

      it_behaves_like "records a school closed event"
    end

    context "when there are no unstarted ect_at_school_periods" do
      let(:unstarted_ects) { [] }

      it { is_expected.to be_truthy }

      it_behaves_like "destroys unstarted mentor_at_school_periods"

      it "does not destroy any ect_at_school_periods" do
        expect(ECTAtSchoolPeriods::Destroy).not_to receive(:call)

        expect { service }.not_to change(ECTAtSchoolPeriod, :count)
      end

      it_behaves_like "finishes ongoing mentor_at_school_periods"
      it_behaves_like "finishes ongoing ect_at_school_periods"

      it_behaves_like "records a school closed event"
    end

    context "when there are no unstarted mentor_at_school_periods" do
      let(:unstarted_mentors) { [] }

      it { is_expected.to be_truthy }

      it "does not destroy any mentor_at_school_periods" do
        expect(MentorAtSchoolPeriods::Destroy).not_to receive(:call)
        expect { service }.not_to change(MentorAtSchoolPeriod, :count)
      end

      it_behaves_like "destroys unstarted ect_at_school_periods"
      it_behaves_like "finishes ongoing mentor_at_school_periods"
      it_behaves_like "finishes ongoing ect_at_school_periods"

      it_behaves_like "records a school closed event"
    end

    context "when there are no unstarted or ongoing periods" do
      let!(:mentors) { FactoryBot.create_list(:mentor_at_school_period, 3, :with_training_period, school:, finished_on: Date.yesterday) }
      let!(:ects) { FactoryBot.create_list(:ect_at_school_period, 3, :with_training_period, school:, finished_on: Date.yesterday) }
      let(:unstarted_mentors) { [] }
      let(:unstarted_ects) { [] }
      let(:mentorship_finished_on) { Date.yesterday }

      it { is_expected.to be_truthy }

      it_behaves_like "does not destroy or finish any periods"
      it_behaves_like "records a school closed event"
    end

    context "when there are unstarted mentorship periods" do
      context "when the mentee has started but the mentorship starts in the future" do
        let!(:unstarted_mentorship_period) { create_mentorship_period(ects.second, unstarted_mentors.second, finished_on: nil) }

        it "destroys the mentorship period" do
          service

          expect { unstarted_mentorship_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when the mentor has started but the mentorship starts in the future" do
        let!(:unstarted_mentorship_period) { create_mentorship_period(unstarted_ects.second, mentors.second, finished_on: nil) }

        it "destroys the mentorship period" do
          service

          expect { unstarted_mentorship_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when neither the mentor nor the mentee period is unstarted" do
        let!(:unstarted_mentorship_period) { create_mentorship_period(unstarted_ects.first, unstarted_mentors.first) }

        it "destroys the mentorship period" do
          service

          expect { unstarted_mentorship_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "when the school cannot be closed" do
      let(:can_be_closed) { false }

      it { is_expected.to be_falsy }

      it_behaves_like "does not destroy or finish any periods"

      it "does not record an event" do
        expect { service }.not_to(change(Event, :count))
      end
    end

    context "when the school closed in the past" do
      let(:closed_on) { 1.week.ago.to_date }

      let!(:mentor_started_on_last_day) { FactoryBot.create(:mentor_at_school_period, :with_training_period, school:, started_on: closed_on) }
      let!(:ect_started_on_last_day) { FactoryBot.create(:ect_at_school_period, :with_training_period, school:, started_on: closed_on) }

      it { is_expected.to be_truthy }

      it_behaves_like "destroys unstarted ect_at_school_periods"
      it_behaves_like "destroys unstarted mentor_at_school_periods"

      it "does not destroy mentor_at_school_periods which started on closure date" do
        service

        expect(mentor_started_on_last_day.reload).to be_present
      end

      it "does not destroy ect_at_school_periods which started on closure date" do
        service

        expect(ect_started_on_last_day.reload).to be_present
      end

      it "finishes ongoing ect_at_school_periods which" do
        ects.each do |ect_at_school_period|
          expect(ECTAtSchoolPeriods::Finish).to receive(:new).with(
            hash_including(ect_at_school_period:)
          )
        end

        expect(ECTAtSchoolPeriods::Finish).to receive(:new).with(
          hash_including(ect_at_school_period: ect_started_on_last_day)
        )

        expect(ect_finish_service).to receive(:finish!).exactly(4).times

        service
      end

      it "finishes ongoing mentor_at_school_periods" do
        mentors.each do |mentor_at_school_period|
          expect(MentorAtSchoolPeriods::Finish).to receive(:new).with(
            hash_including(teacher: mentor_at_school_period.teacher)
          )
        end

        expect(MentorAtSchoolPeriods::Finish).to receive(:new).with(
          hash_including(teacher: mentor_started_on_last_day.teacher)
        )

        expect(mentor_finish_service).to receive(:finish_periods_at_reported_school!).exactly(4).times

        service
      end

      it_behaves_like "records a school closed event"
    end
  end

  def create_mentorship_period(mentee, mentor, finished_on: mentorship_finished_on)
    return unless mentee.present? && mentor.present?

    started_on = [mentee.started_on, mentor.started_on].max

    attributes = { mentee:, mentor:, started_on:, finished_on: }.compact

    FactoryBot.create(:mentorship_period, **attributes)
  end
end
