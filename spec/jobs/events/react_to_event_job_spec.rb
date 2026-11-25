RSpec.describe Events::ReactToEventJob do
  it "discards the reaction when its event no longer exists" do
    mentorship_period = FactoryBot.create(:mentorship_period)
    teacher = mentorship_period.mentor.teacher
    event = Events::Record.teacher_name_updated_by_user_event!(old_name: "Old Name", new_name: "New Name", author: Events::SystemAuthor.new, teacher:)
    event.destroy!

    expect { perform_enqueued_jobs }.not_to raise_error
    expect(Event.api_reaction_events).to be_empty
  end
end
