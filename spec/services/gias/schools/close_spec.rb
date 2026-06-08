RSpec.describe Schools::Close do
  describe ".call" do
    subject(:service) { described_class.call }

    let!(:closed_school) do
      FactoryBot.create(:gias_school, :closed, :with_school)
    end

    let!(:open_school) do
      FactoryBot.create(:gias_school, :open, :with_school)
    end

    let!(:linked_school) do
      FactoryBot.create(:gias_school, :closed, :with_school).tap do |gias_school|
        FactoryBot.create(:gias_school_link, from_gias_school: gias_school)
      end
    end

    it "closes only closed schools without successors" do
      closer = instance_double(described_class, close!: true)

      allow(described_class).to receive(:new).and_return(closer)

      described_class.call

      expect(described_class).to have_received(:new)
        .with(closed_school.school)

      expect(described_class).not_to have_received(:new)
        .with(open_school.school)

      expect(described_class).not_to have_received(:new)
        .with(linked_school.school)

      expect(closer).to have_received(:close!).once
    end
  end

  describe "#close" do
    subject(:service) { described_class.new(school).close! }

    let(:gias_school) { FactoryBot.create(:gias_school, :closed, :with_school) }
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

      allow(MentorAtSchoolPeriods::Destroy).to receive(:call)
      allow(ECTAtSchoolPeriods::Destroy).to receive(:call)
    end

    it "destroys unstarted periods" do
      service

      expect(MentorAtSchoolPeriods::Destroy).to have_received(:call).twice
      expect(ECTAtSchoolPeriods::Destroy).to have_received(:call).twice
    end

    it "finishes ongoing periods" do
      service

      expect(mentor_finish_service).to have_received(:finish_periods_at_reported_school!).exactly(3).times
      expect(ect_finish_service).to have_received(:finish!).exactly(3).times
    end

    it "records a school closed event" do
      allow(Events::Record).to receive(:record_school_closed_event!).once.and_call_original

      service
      expect(Events::Record).to have_received(:record_school_closed_event!)
      .once
      .with(
        hash_including(
          {
            author: an_instance_of(Events::SystemAuthor),
            school:,
          }
        )
      )
    end

    context "when the school is open" do
      let(:gias_school) { FactoryBot.create(:gias_school, :open, :with_school) }

      it "does not destroy unstarted periods" do
        service

        expect(MentorAtSchoolPeriods::Destroy).not_to have_received(:call)
        expect(ECTAtSchoolPeriods::Destroy).not_to have_received(:call)
      end

      it "does not finish ongoing periods" do
        service

        expect(mentor_finish_service).not_to have_received(:finish_periods_at_reported_school!)
        expect(ect_finish_service).not_to have_received(:finish!)
      end

      it "does not record a school closed event" do
        allow(Events::Record).to receive(:record_school_closed_event!).once.and_call_original

        service
        expect(Events::Record).not_to have_received(:record_school_closed_event!)
      end
    end

    context "when the school is linked to another school" do
      before do
        FactoryBot.create(:gias_school_link, from_gias_school: gias_school)
      end

      it "does not destroy unstarted periods" do
        service

        expect(MentorAtSchoolPeriods::Destroy).not_to have_received(:call)
        expect(ECTAtSchoolPeriods::Destroy).not_to have_received(:call)
      end

      it "does not finish ongoing periods" do
        service

        expect(mentor_finish_service).not_to have_received(:finish_periods_at_reported_school!)
        expect(ect_finish_service).not_to have_received(:finish!)
      end

      it "does not record a school closed event" do
        allow(Events::Record).to receive(:record_school_closed_event!).once.and_call_original

        service
        expect(Events::Record).not_to have_received(:record_school_closed_event!)
      end
    end

    context "when there are no ongoing mentor_at_school periods" do
      let(:mentors) { [] }

      it "only destroys unstarted ECT periods" do
        service

        expect(MentorAtSchoolPeriods::Destroy).to have_received(:call).twice
        expect(ECTAtSchoolPeriods::Destroy).to have_received(:call).twice
      end

      it "does not finish ongoing periods" do
        service

        expect(mentor_finish_service).not_to have_received(:finish_periods_at_reported_school!)
        expect(ect_finish_service).to have_received(:finish!).exactly(3).times
      end

      it "records a school closed event" do
        allow(Events::Record).to receive(:record_school_closed_event!).once.and_call_original

        service
        expect(Events::Record).to have_received(:record_school_closed_event!)
        .once
        .with(
          hash_including(
            {
              author: an_instance_of(Events::SystemAuthor),
              school:,
            }
          )
        )
      end
    end

    context "when there are no ongoing ect_at_school periods" do
      let(:ects) { [] }

      it "only destroys unstarted ECT periods" do
        service

        expect(MentorAtSchoolPeriods::Destroy).to have_received(:call).twice
        expect(ECTAtSchoolPeriods::Destroy).to have_received(:call).twice
      end

      it "does not finish ongoing periods" do
        service

        expect(mentor_finish_service).to have_received(:finish_periods_at_reported_school!).exactly(3).times
        expect(ect_finish_service).not_to have_received(:finish!)
      end

      it "records a school closed event" do
        allow(Events::Record).to receive(:record_school_closed_event!).once.and_call_original

        service
        expect(Events::Record).to have_received(:record_school_closed_event!)
        .once
        .with(
          hash_including(
            {
              author: an_instance_of(Events::SystemAuthor),
              school:,
            }
          )
        )
      end
    end

    context "when all the periods are finished periods" do
      let!(:mentors) { FactoryBot.create_list(:mentor_at_school_period, 3, :with_training_period, school:, finished_on: Date.yesterday) }
      let!(:ects) { FactoryBot.create_list(:ect_at_school_period, 3, :with_training_period, school:, finished_on: Date.yesterday) }
      let(:unstarted_mentors) { [] }
      let(:unstarted_ects) { [] }
      let(:mentorship_finished_on) { Date.yesterday }

      it "does not destroy unstarted periods" do
        service

        expect(MentorAtSchoolPeriods::Destroy).not_to have_received(:call)
        expect(ECTAtSchoolPeriods::Destroy).not_to have_received(:call)
      end

      it "does not finish ongoing periods" do
        service

        expect(mentor_finish_service).not_to have_received(:finish_periods_at_reported_school!)
        expect(ect_finish_service).not_to have_received(:finish!)
      end

      it "records a school closed event" do
        allow(Events::Record).to receive(:record_school_closed_event!).once.and_call_original

        service
        expect(Events::Record).to have_received(:record_school_closed_event!)
        .once
        .with(
          hash_including(
            {
              author: an_instance_of(Events::SystemAuthor),
              school:,
            }
          )
        )
      end
    end

    context "when there are no unstarted periods" do
      let(:unstarted_mentors) { [] }
      let(:unstarted_ects) { [] }

      it "does not destroy any unstarted periods" do
        service

        expect(MentorAtSchoolPeriods::Destroy).not_to have_received(:call)
        expect(ECTAtSchoolPeriods::Destroy).not_to have_received(:call)
      end

      it "finishes ongoing periods" do
        service

        expect(mentor_finish_service).to have_received(:finish_periods_at_reported_school!).exactly(3).times
        expect(ect_finish_service).to have_received(:finish!).exactly(3).times
      end

      it "records a school closed event" do
        allow(Events::Record).to receive(:record_school_closed_event!).once.and_call_original

        service
        expect(Events::Record).to have_received(:record_school_closed_event!)
        .once
        .with(
          hash_including(
            {
              author: an_instance_of(Events::SystemAuthor),
              school:,
            }
          )
        )
      end
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
