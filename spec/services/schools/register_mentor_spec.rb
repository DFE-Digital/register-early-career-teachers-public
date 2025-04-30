RSpec.describe Schools::RegisterMentor do
  subject(:service) do
    described_class.new(trs_first_name:,
                        trs_last_name:,
                        corrected_name:,
                        trn:,
                        school_urn: school.urn,
                        email:,
                        started_on:,
                        mentor_completion_date:,
                        mentor_completion_reason:,
                        author:)
  end

  let(:author) { FactoryBot.create(:school_user, school_urn: school.urn) }
  let(:trs_first_name) { "Dusty" }
  let(:trs_last_name) { "Rhodes" }
  let(:corrected_name) { "Randy Marsh" }
  let(:trn) { "3002586" }
  let(:school) { FactoryBot.create(:school) }
  let(:email) { "randy@tegridyfarms.com" }
  let(:started_on) { Date.yesterday }
  let(:mentor_completion_date) { Date.new(2021, 4, 19) }
  let(:mentor_completion_reason) { 'completed_during_early_roll_out' }
  let(:teacher) { subject.teacher }

  describe '#register!' do
    let(:mentor_at_school_period) { MentorAtSchoolPeriod.first }

    context "when a Teacher record with the same trn doesn't exist" do
      it 'creates a new Teacher record' do
        expect { service.register! }.to change(Teacher, :count).from(0).to(1)
        expect(teacher.trs_first_name).to eq(trs_first_name)
        expect(teacher.trs_last_name).to eq(trs_last_name)
        expect(teacher.corrected_name).to eq(corrected_name)
        expect(teacher.trn).to eq(trn)
        expect(teacher.mentor_completion_reason).to eq(mentor_completion_reason)
        expect(teacher.mentor_completion_date).to eq(mentor_completion_date)
      end
    end

    context "when a Teacher record with the same trn exists" do
      let!(:teacher) { FactoryBot.create(:teacher, trn:) }

      context "without MentorATSchoolPeriod records" do
        it { expect { service.register! }.not_to change(Teacher, :count) }
      end

      context "with MentorATSchoolPeriod records" do
        before { FactoryBot.create(:mentor_at_school_period, teacher:) }

        it { expect { service.register! }.to raise_error(ActiveRecord::RecordInvalid) }
      end
    end

    it 'creates an associated MentorATSchoolPeriod record' do
      expect { service.register! }.to change(MentorAtSchoolPeriod, :count).from(0).to(1)
      expect(mentor_at_school_period.teacher_id).to eq(Teacher.first.id)
      expect(mentor_at_school_period.started_on).to eq(started_on)
      expect(mentor_at_school_period.email).to eq(email)
    end

    describe 'recording an event' do
      before { allow(Events::Record).to receive(:record_teacher_registered_as_mentor_event!).with(any_args).and_call_original }

      it 'records a mentor_registered event with the expected attributes' do
        service.register!

        expect(Events::Record).to have_received(:record_teacher_registered_as_mentor_event!).with(
          hash_including(author:, mentor_at_school_period:, teacher:, school:)
        )
      end
    end

    context "when no start date is provided" do
      subject(:service) do
        described_class.new(trs_first_name:,
                            trs_last_name:,
                            corrected_name:,
                            trn:,
                            school_urn: school.urn,
                            email:,
                            mentor_completion_date:,
                            mentor_completion_reason:,
                            author:)
      end

      it "current date is assigned" do
        service.register!

        expect(mentor_at_school_period.started_on).to eq(Date.current)
      end
    end
  end
end
