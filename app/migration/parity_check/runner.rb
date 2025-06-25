module ParityCheck
  class Runner
    include ParityCheck::Configuration

    attr_reader :endpoints

    def initialize(endpoints)
      @endpoints = endpoints
    end

    def run
      ensure_parity_check_enabled!

      Run.create!.tap do |run|
        lead_providers.to_a.product(endpoints).each do |lead_provider, endpoint|
          run.requests.create!(lead_provider:, endpoint:)
        end

        ParityCheck::RunDispatcher.new.dispatch
      end
    end

  private

    def lead_providers
      @lead_providers ||= LeadProvider.all
    end
  end
end
