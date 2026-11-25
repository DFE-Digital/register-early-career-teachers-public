RSpec.describe Reactor do
  describe ".dispatch" do
    it "does not react to reactions" do
      mentorship_period = FactoryBot.create(:mentorship_period)
      lead_provider = FactoryBot.create(:lead_provider, name: "Ambition Institute")

      expect {
        Events::Record.record_api_mentorship_event!(action: :created, lead_provider:, mentorship_period:, in_reaction_to: nil, payload: {})
      }.not_to have_enqueued_job(Events::ReactToEventJob)
    end
  end
end
