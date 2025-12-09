module Migration
  class ParticipantProfileState < Migration::Base
    belongs_to :cpd_lead_provider, optional: true
    belongs_to :participant_profile
    has_one :lead_provider, through: :cpd_lead_provider

    def deferred? = state == "deferred"

    def withdrawn? = state == "withdrawn"

    enum :state, {
      active: "active",
      deferred: "deferred",
      withdrawn: "withdrawn",
    }
  end
end
