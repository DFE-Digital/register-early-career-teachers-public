RSpec.describe Schools::AssignMentor do
  subject(:service) do
    described_class.new(author:, ect: mentee, mentor: new_mentor, started_on:)
  end

  let(:mentee) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }
  let(:current_mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }
  let!(:current_mentorship) { FactoryBot.create(:mentorship_period, :active, mentee:, mentor: current_mentor) }
  let(:new_mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }
  let(:started_on) { Date.yesterday }
  let(:author) { FactoryBot.create(:school_user, school_urn: mentee.school.urn) }

  describe '#assign!' do
    it 'ends current mentorship of the ect' do
      expect { service.assign! }.to change { current_mentorship.reload.finished_on }.from(nil).to(started_on)
    end

    it 'adds a new mentorship for the ect with the new mentor started the date given' do
      expect(mentee.current_mentor).to eq(current_mentor)
      expect { service.assign! }.to change(MentorshipPeriod, :count).from(1).to(2)
      expect(mentee.current_mentor).to eq(new_mentor)
      expect(mentee.current_mentorship.started_on).to eq(started_on)
    end

    context "when no start date is provided" do
      subject(:service) { described_class.new(author:, ect: mentee, mentor: new_mentor) }

      it "the current date is assigned" do
        service.assign!

        expect(mentee.current_mentorship.started_on).to eq(Date.current)
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
