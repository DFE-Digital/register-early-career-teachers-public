RSpec.shared_examples "does not destroy or finish any periods" do
  it "does not archive unstarted periods" do
    expect(MentorAtSchoolPeriods::Archive).not_to receive(:call)
    expect(ECTAtSchoolPeriods::Archive).not_to receive(:call)
    subject

    unstarted_mentors.each do |period|
      expect(period.reload).not_to be_archived
    end

    unstarted_ects.each do |period|
      expect(period.reload).not_to be_archived
    end
  end

  it "does not finish ongoing periods" do
    expect(mentor_finish_service).not_to receive(:finish_periods_at_reported_school!)
    expect(ect_finish_service).not_to receive(:finish!)

    subject
  end
end

RSpec.shared_examples "archives unstarted mentor_at_school_periods" do
  it "archives unstarted mentor_at_school_periods" do
    expect { service }.not_to change(MentorAtSchoolPeriod, :count)

    unstarted_mentors.each do |period|
      expect(period.reload).to be_archived
    end
  end
end

RSpec.shared_examples "archives unstarted ect_at_school_periods" do
  it "archives unstarted ect_at_school_periods" do
    expect { service }.not_to change(ECTAtSchoolPeriod, :count)

    unstarted_ects.each do |period|
      expect(period.reload).to be_archived
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
    school = gias_school.school

    subject

    event = Event.where(event_type: "school_closed").sole
    expect(event.school_id).to eq(school.id)
    expect(event.metadata).to eq(
      "gias_school_urn" => gias_school.urn,
      "gias_school_name" => gias_school.name
    )
    expect(event.happened_at.to_date).to eq(gias_school.closed_on)
  end
end
