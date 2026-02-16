module Migration
  class MentorCallOffContract < Migration::Base
    belongs_to :lead_provider
    belongs_to :cohort

    def attributes
      super.merge("fee_per_declaration" => payment_per_participant)
    end
  end
end
