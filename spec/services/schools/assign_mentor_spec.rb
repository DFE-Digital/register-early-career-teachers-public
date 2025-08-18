RSpec.describe Schools::AssignMentor do
  subject(:service) do
    described_class.new(author:, ect: mentee, mentor: new_mentor, started_on: mentorship_started_on)
  end

  let(:mentee_started_on) { 3.years.ago }
  let(:mentor_started_on) { 3.years.ago }

  let(:mentee) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: mentee_started_on) }
  let(:new_mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: mentor_started_on) }
  let(:mentorship_started_on) { Date.yesterday }
  let(:author) { FactoryBot.create(:school_user, school_urn: mentee.school.urn) }

  describe '#assign!' do
    context 'when there is a current mentorship period' do
      let(:current_mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: 3.years.ago) }
      let!(:current_mentorship) { FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor: current_mentor) }

      it 'ends current mentorship of the ect' do
        expect { service.assign! }.to change { current_mentorship.reload.finished_on }.from(nil).to(mentorship_started_on)
      end

      it 'adds a new mentorship for the ect with the new mentor started the date given' do
        expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_mentor).to eq(current_mentor)
        expect { service.assign! }.to change(MentorshipPeriod, :count).from(1).to(2)
        expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_mentor).to eq(new_mentor)
        expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_mentorship_period.started_on).to eq(mentorship_started_on)
      end

      context "when no start date is provided" do
        subject(:service) { described_class.new(author:, ect: mentee, mentor: new_mentor) }

        it "the current date is assigned" do
          service.assign!

          expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_mentorship_period.started_on).to eq(Date.current)
        end
      end
    end

    describe 'future dates' do
      context 'when the mentee (ECT) start date is in the future' do
        let(:mentorship_started_on) { nil }
        let(:mentee_started_on) { 3.weeks.from_now.to_date }

        it 'sets the start date to the mentee start date' do
          service.assign!

          expect(service.mentorship_period.started_on).to eq(mentee_started_on)
        end
      end

      context 'when the mentor start dates is in the future' do
        let(:mentorship_started_on) { nil }
        let(:mentor_started_on) { 1.month.from_now.to_date }

        it 'sets the start date to the mentee start date' do
          service.assign!

          expect(service.mentorship_period.started_on).to eq(mentor_started_on)
        end
      end

      context 'when the mentee and mentor start dates are in the future but the provided start date is further in the future' do
        let(:mentorship_started_on) { 2.months.from_now.to_date }
        let(:mentor_started_on) { 1.month.from_now.to_date }
        let(:mentee_started_on) { 3.weeks.from_now.to_date }

        it 'sets the start date to the mentee start date' do
          service.assign!

          expect(service.mentorship_period.started_on).to eq(mentorship_started_on)
        end
      end
    end

    describe 'events' do
      let(:mentorship_period) { MentorshipPeriod.last }

      it 'creates the :record_teacher_starts_mentoring_event with the right arguments' do
        allow(Events::Record).to receive(:record_teacher_starts_mentoring_event!).and_call_original

        service.assign!

        expect(Events::Record).to have_received(:record_teacher_starts_mentoring_event!).with(
          hash_including(
            mentee: mentee.teacher,
            mentor: new_mentor.teacher,
            mentorship_period:,
            author:,
            school: new_mentor.school
          )
        )
      end

      it 'creates the :record_teacher_starts_being_mentored_event with the right arguments' do
        allow(Events::Record).to receive(:record_teacher_starts_being_mentored_event!).and_call_original

        service.assign!

        expect(Events::Record).to have_received(:record_teacher_starts_being_mentored_event!).with(
          hash_including(
            mentee: mentee.teacher,
            mentor: new_mentor.teacher,
            mentorship_period:,
            author:,
            school: mentee.school
          )
        )
      end
    end
  end
end
