describe MentorshipPeriods::Finish do
  subject { MentorshipPeriods::Finish.new(mentorship_period:, finished_on:, author:) }

  let(:started_on) { 1.year.ago.to_date }
  let(:existing_dates) { { started_on:, finished_on: nil } }
  let(:finished_on) { 1.week.ago.to_date }
  let(:author) { FactoryBot.build(:school_user, school_urn: ect_at_school_period.school.urn) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, **existing_dates) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school: ect_at_school_period.school, **existing_dates) }
  let(:mentorship_period) { FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: ect_at_school_period, **existing_dates) }

  describe "initialization" do
    it "assigns the mentorship_period" do
      expect(subject.mentorship_period).to eql(mentorship_period)
    end

    it "assigns the finished_on" do
      expect(subject.finished_on).to eql(finished_on)
    end

    it "assigns the mentor_at_school_period" do
      expect(subject.mentor_at_school_period).to eql(mentor_at_school_period)
    end

    it "assigns the ect_at_school_period" do
      expect(subject.ect_at_school_period).to eql(ect_at_school_period)
    end
  end

  describe "#finish!" do
    it "closes the mentorship_period" do
      subject.finish!

      mentorship_period.reload

      expect(mentorship_period.finished_on).to eql(finished_on)
    end

    it "records an event for the mentor" do
      expect {
        subject.finish!
      }.to change(Event, :count).by(2)

      event = Event.where(event_type: "teacher_finishes_mentoring").sole
      expect(event).to have_attributes(
        mentorship_period_id: mentorship_period.id,
        mentor_at_school_period_id: mentor_at_school_period.id,
        teacher_id: mentor_at_school_period.teacher_id,
        school_id: mentor_at_school_period.school_id
      )
      expect(event.metadata).to eq(
        "mentor_id" => mentor_at_school_period.teacher_id,
        "mentee_id" => ect_at_school_period.teacher_id
      )
      expect(event.happened_at.to_date).to eq(finished_on)
    end

    it "records an event for the ECT" do
      expect {
        subject.finish!
      }.to change(Event, :count).by(2)

      event = Event.where(event_type: "teacher_finishes_being_mentored").sole
      expect(event).to have_attributes(
        mentorship_period_id: mentorship_period.id,
        ect_at_school_period_id: ect_at_school_period.id,
        teacher_id: ect_at_school_period.teacher_id,
        school_id: ect_at_school_period.school_id
      )
      expect(event.metadata).to eq(
        "mentor_id" => mentor_at_school_period.teacher_id,
        "mentee_id" => ect_at_school_period.teacher_id
      )
      expect(event.happened_at.to_date).to eq(finished_on)
    end

    context "when record_event is false" do
      subject { MentorshipPeriods::Finish.new(mentorship_period:, finished_on:, author:, record_event: false) }

      it "does not record any events" do
        expect {
          subject.finish!
        }.not_to change(Event, :count)

        expect(Event.where(event_type: %w[teacher_finishes_mentoring teacher_finishes_being_mentored])).to be_empty
      end
    end
  end
end
