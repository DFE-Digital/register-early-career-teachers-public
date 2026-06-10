RSpec.shared_examples "does not destroy or finish any periods" do
  it "does not destroy unstarted periods" do
    expect(MentorAtSchoolPeriods::Destroy).not_to receive(:call)
    expect(ECTAtSchoolPeriods::Destroy).not_to receive(:call)

    subject
  end

  it "does not finish ongoing periods" do
    expect(mentor_finish_service).not_to receive(:finish_periods_at_reported_school!)
    expect(ect_finish_service).not_to receive(:finish!)

    subject
  end
end

RSpec.shared_examples "destroys unstarted mentor_at_school_periods" do
  it "destroys unstarted mentor_at_school_periods" do
    expect { service }.to change(MentorAtSchoolPeriod, :count).by(-2)

    unstarted_mentors.each do |period|
      expect { period.reload }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

RSpec.shared_examples "destroys unstarted ect_at_school_periods" do
  it "destroys unstarted ect_at_school_periods" do
    expect { service }.to change(ECTAtSchoolPeriod, :count).by(-2)

    unstarted_ects.each do |period|
      expect { period.reload }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    service
  end
end

RSpec.shared_examples "finishes ongoing mentor_at_school_periods" do
  it "finishes ongoing mentor_at_school_periods" do
    mentors.each do |mentor_at_school_period|
      expect(MentorAtSchoolPeriods::Finish).to receive(:new).with(
        hash_including(teacher: mentor_at_school_period.teacher)
      )
    end

    expect(mentor_finish_service).to receive(:finish_periods_at_reported_school!).exactly(3).times

    service
  end
end

RSpec.shared_examples "finishes ongoing ect_at_school_periods" do
  it "finishes ongoing ect_at_school_periods" do
    ects.each do |ect_at_school_period|
      expect(ECTAtSchoolPeriods::Finish).to receive(:new).with(
        hash_including(ect_at_school_period:)
      )
    end

    expect(ect_finish_service).to receive(:finish!).exactly(3).times

    service
  end
end

RSpec.shared_examples "records a school closed event" do
  it "records a school closed event" do
    expect(Events::Record).to receive(:record_school_closed_event!)
    .once
    .with(school: gias_school.school,
          gias_school:,
          happened_at: gias_school.closed_on,
          author: an_instance_of(Events::SystemAuthor))

    subject
  end
end
