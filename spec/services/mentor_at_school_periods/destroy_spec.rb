describe MentorAtSchoolPeriods::Destroy do
  subject { MentorAtSchoolPeriods::Destroy.call(mentor_at_school_period:, author:) }

  let(:started_on) { Date.tomorrow }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: 1.week.ago) }
  let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, started_on:) }

  let(:school) { mentor_at_school_period.school }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:teacher) { mentor_at_school_period.teacher }
  let(:event_mentor) { FactoryBot.create(:event, :with_mentor_at_school_period, mentor_at_school_period:) }

  describe "#call!" do
    context "when the Mentor at school period does not exist" do
      let(:mentor_at_school_period) { nil }
      let(:school) { FactoryBot.create(:school) }
      let(:teacher) { nil }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "does not delete anything" do
        expect { subject }.not_to(change(MentorAtSchoolPeriod, :count))
      end

      it "does not create any events" do
        expect { subject }.not_to(change(Event, :count))
      end
    end

    context "when the Mentor at school period has not started yet" do
      let(:started_on) { Date.tomorrow }

      it "destroys the Mentor at school period" do
        expect { subject }.to change(MentorAtSchoolPeriod, :count).from(1).to(0)
      end

      it "destroys any events associated with the Mentor at school period" do
        subject
        expect(Event).not_to exist(mentor_at_school_period_id: mentor_at_school_period.id)
      end

      it "records an event for the deletion of the unstarted Mentor at school period" do
        expect(Events::Record).to receive(:record_teacher_mentor_at_school_period_deleted!).with(
          author:,
          teacher:,
          school:,
          started_on:
        )

        subject
      end

      context "with associated mentorship periods" do
        let!(:mentorship_period) { FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on:) }
        let!(:event) { FactoryBot.create(:event, :with_mentorship_period, mentorship_period:) }

        it "destroys any associated mentorship periods" do
          expect { subject }.to change(MentorshipPeriod, :count).from(1).to(0)
        end

        it "destroys any events associated with the mentorship periods" do
          subject
          expect(Event).not_to exist(mentorship_period_id: mentorship_period.id)
        end
      end

      context "with associated training periods" do
        let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:) }
        let!(:event) { FactoryBot.create(:event, :with_training_period, training_period:) }

        it "destroys the periods" do
          expect { subject }.to change(TrainingPeriod, :count).from(1).to(0)
        end

        it "destroys any events associated with the training periods" do
          subject
          expect(Event).not_to exist(training_period_id: training_period.id)
        end
      end
    end

    context "when the Mentor at school period has started today" do
      let(:started_on) { Time.zone.today }

      it "destroys the Mentor at school period" do
        expect { subject }.to change(MentorAtSchoolPeriod, :count).from(1).to(0)
      end

      it "destroys any events associated with the Mentor at school period" do
        subject
        expect(Event).not_to exist(mentor_at_school_period_id: mentor_at_school_period.id)
      end

      it "records an event for the deletion of the unstarted Mentor at school period" do
        expect(Events::Record).to receive(:record_teacher_mentor_at_school_period_deleted!).with(
          author:,
          teacher:,
          school:,
          started_on:
        )

        subject
      end

      context "with associated mentorship periods" do
        let!(:mentorship_period) { FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on:) }
        let!(:event) { FactoryBot.create(:event, :with_mentorship_period, mentorship_period:) }

        it "destroys any associated mentorship periods" do
          expect { subject }.to change(MentorshipPeriod, :count).from(1).to(0)
        end

        it "destroys any events associated with the mentorship periods" do
          subject
          expect(Event).not_to exist(mentorship_period_id: mentorship_period.id)
        end
      end

      context "with associated training periods" do
        let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:) }
        let!(:event) { FactoryBot.create(:event, :with_training_period, training_period:) }

        it "destroys the periods" do
          expect { subject }.to change(TrainingPeriod, :count).from(1).to(0)
        end

        it "destroys any events associated with the training periods" do
          subject
          expect(Event).not_to exist(training_period_id: training_period.id)
        end
      end
    end

    context "when the Mentor at school period has started in the past" do
      let(:started_on) { Date.yesterday }

      it "does not destroy the Mentor at school period" do
        expect { subject }.not_to(change { MentorAtSchoolPeriod.exists?(mentor_at_school_period.id) })
      end

      it "does not create or destroy any events" do
        expect { subject }.not_to(change(Event, :count))
      end

      context "with associated mentorship periods" do
        let!(:mentorship_period) { FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on:) }
        let!(:event) { FactoryBot.create(:event, :with_mentorship_period, mentorship_period:) }

        it "does not destroy any associated mentorship periods" do
          expect { subject }.not_to(change(MentorshipPeriod, :count))
        end

        it "destroys any events associated with the mentorship periods" do
          expect { subject }.not_to(change(Event, :count))
        end
      end

      context "with associated training periods" do
        let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:) }
        let!(:event) { FactoryBot.create(:event, :with_training_period, training_period:) }

        it "does not destroy the periods" do
          expect { subject }.not_to(change(TrainingPeriod, :count))
        end

        it "does not destroy any events associated with the training periods" do
          expect { subject }.not_to(change(Event, :count))
        end
      end
    end
  end
end
