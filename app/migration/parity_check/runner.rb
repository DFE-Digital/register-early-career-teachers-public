module ParityCheck
  class Runner
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ParityCheck::Configuration

    attribute :endpoint_ids
    attribute :mode, default: -> { :concurrent }

    validates :mode, presence: true, inclusion: { in: %w[concurrent sequential] }
    validates :endpoint_ids, presence: { message: "Select at least one endpoint." }
    validate :endpoints_exist
    validate :lead_providers_exist

    def run!
      return unless valid?

      ensure_parity_check_enabled!

      Run.create!(mode:).tap do |run|
        lead_providers.to_a.product(endpoints).each do |lead_provider, endpoint|
          run.requests.create!(lead_provider:, endpoint:)
        end

        ParityCheck::RunDispatcher.new.dispatch
      end
    end

    def endpoint_ids=(ids)
      super(ids&.compact_blank)
    end

  private

    def endpoints
      @endpoints ||= Endpoint.where(id: endpoint_ids)
    end

    def endpoints_exist
      return if endpoints.none? || endpoints.count == endpoint_ids.uniq.count

      errors.add(:endpoint_ids, "One or more selected endpoints do not exist.")
    end

    def lead_providers_exist
      return if lead_providers.any?

      errors.add(:base, "There are no lead providers available; create at least one lead provider to run a parity check.")
    end

    def lead_providers
      @lead_providers ||= LeadProvider.where.not(ecf_id: nil)
    end
  end
end
