RSpec.describe Schools::AssignMentor do
  subject(:service) do
    described_class.new(author:, ect: mentee, mentor: new_mentor)
  end

  let(:mentee_started_on) { 3.years.ago }
  let(:mentor_started_on) { 3.years.ago }

  let(:mentee) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: mentee_started_on) }
  let(:new_mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: mentor_started_on) }
  let(:author) { FactoryBot.create(:school_user, school_urn: mentee.school.urn) }

  describe '#assign!' do
    context 'when there is a current mentorship period' do
      let(:current_mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: 3.years.ago) }
      let!(:current_mentorship) { FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor: current_mentor) }

      it 'ends current mentorship of the ect' do
        expect { service.assign! }.to change { current_mentorship.reload.finished_on }.from(nil).to(Date.current)
      end

      it 'adds a new mentorship for the ect with the new mentor starting today' do
        expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_mentor).to eq(current_mentor)
        expect { service.assign! }.to change(MentorshipPeriod, :count).from(1).to(2)
        expect(ECTAtSchoolPeriods::Mentorship.new(mentee.reload).current_mentor).to eq(new_mentor)
        expect(ECTAtSchoolPeriods::Mentorship.new(mentee).current_or_next_mentorship_period.started_on).to eq(Date.current)
      end
    end

    describe 'future dates' do
      context 'when the mentee (ECT) start date is in the future' do
        let(:mentee_started_on) { 3.weeks.from_now.to_date }

        it 'sets the start date to the mentee start date' do
          service.assign!

          expect(service.mentorship_period.started_on).to eq(mentee_started_on)
        end
      end

      context 'when the mentor start date is in the future' do
        let(:mentor_started_on) { 1.month.from_now.to_date }

        it 'sets the start date to the mentor start date' do
          service.assign!

          expect(service.mentorship_period.started_on).to eq(mentor_started_on)
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
