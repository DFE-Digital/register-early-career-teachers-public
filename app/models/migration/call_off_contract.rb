module Migration
  class CallOffContract < Migration::Base
    UNUSED_VERSION_PREFIX = "unused_"

    belongs_to :lead_provider
    belongs_to :cohort
    has_many :participant_bands

    scope :not_flagged_as_unused, -> { where.not("version LIKE ?", "#{UNUSED_VERSION_PREFIX}%") }

    def statements
      Migration::Statement.where(cohort:, cpd_lead_provider: lead_provider.cpd_lead_provider, contract_version: version)
    end

    def bands
      participant_bands.min_nulls_first
    end

    def attributes
      super.merge(
        "uplift_fee_per_declaration" => uplift_amount,
        "setup_fee" => set_up_fee
      )
    end
  end
end
