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

RSpec.shared_examples "does not change the schools URN or record an event" do
  it "does not update the school's URN" do
    expect { subject }.not_to(change { gias_school.school.reload.urn })
  end

  it "does not record a school changed event" do
    expect { subject }.not_to change(Event, :count)
  end
end
