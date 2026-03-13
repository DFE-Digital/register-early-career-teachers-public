module ProductReview
  module OutputPayments
    DECLARATION_BOUNDARIES = [
      { min: 1, max: 5 },
      { min: 6, max: 10 },
      { min: 11, max: 20 },
      { min: 21, max: 40 },
    ].freeze

    # Counts chosen so declarations spread across all four bands (A-D).
    # Band allocation is independent per declaration type:
    #   started:    25 → A=5, B=5, C=10, D=5
    #   retained-1: 15 → A=5, B=5, C=5
    #   retained-2:  8 → A=5, B=3
    #   completed:   3 → A=3
    ECT_DECLARATION_COUNTS = {
      "started" => 25,
      "retained-1" => 15,
      "retained-2" => 8,
      "completed" => 3,
    }.freeze

    MENTOR_DECLARATION_COUNTS = {
      "started" => 5,
      "completed" => 3,
    }.freeze

    class << self
      def log(message, indent: 0)
        puts "#{'  ' * indent}#{message}"
      end

      def add_bands!(contract)
        bfs = FactoryBot.create(:contract_banded_fee_structure, :with_bands, declaration_boundaries: DECLARATION_BOUNDARIES)
        contract.update!(banded_fee_structure_id: bfs.id)
      end

      def find_or_create_output_statement!(contract)
        alp = contract.active_lead_provider

        existing = Statement.where(contract:, fee_type: "output", status: :paid).first
        return existing if existing

        reassignable = Statement
          .joins(:contract)
          .where(contracts: { active_lead_provider: alp }, fee_type: "output", status: :paid)
          .first
        if reassignable
          reassignable.update!(contract:)
          return reassignable
        end

        FactoryBot.create(:statement, :paid, :output_fee, contract:, active_lead_provider: alp)
      end

      def create_declarations!(statement:, declaration_counts:, participant_type:)
        alp = statement.contract.active_lead_provider
        schedule = Schedule.find_by!(contract_period: alp.contract_period, identifier: "ecf-standard-september")

        declaration_counts.each do |declaration_type, count|
          milestone = schedule.milestones.find_by(declaration_type:)
          unless milestone
            log "Skipping #{declaration_type} — no milestone found", indent: 3
            next
          end

          count.times do
            training_period = FactoryBot.create(
              :training_period,
              participant_type == :ect ? :for_ect : :for_mentor,
              :with_active_lead_provider,
              active_lead_provider: alp,
              schedule:
            )

            FactoryBot.create(
              :declaration,
              training_period:,
              declaration_type:,
              declaration_date: milestone.start_date,
              payment_status: :paid,
              payment_statement: statement
            )
          end

          log "#{count}x #{declaration_type}", indent: 3
        end
      end
    end
  end
end

namespace :product_review do
  desc "Populate output payment data on finance statements for product review"
  task output_payments: :environment do
    abort("Only available for non-production environments") if Rails.env.production?

    helper = ProductReview::OutputPayments

    lead_provider = LeadProvider.order(:name).first!
    helper.log "Lead provider: #{lead_provider.name}"

    ActiveRecord::Base.transaction do
      # --- Pre-2025 (ECF) ---
      ecf_contract = Contract
        .joins(active_lead_provider: %i[lead_provider contract_period])
        .where(contract_type: :ecf, lead_providers: { id: lead_provider.id })
        .merge(ContractPeriod.where(mentor_funding_enabled: false))
        .first!
      helper.add_bands!(ecf_contract)

      ecf_statement = helper.find_or_create_output_statement!(ecf_contract)
      helper.log "ECF (#{ecf_contract.active_lead_provider.contract_period.year}): statement ##{ecf_statement.id}, #{Date::MONTHNAMES[ecf_statement.month]}", indent: 1

      helper.create_declarations!(statement: ecf_statement, declaration_counts: helper::ECT_DECLARATION_COUNTS, participant_type: :ect)

      # --- Post-2025 (ITTECF_ECTP) ---
      ittecf_contract = Contract
        .joins(active_lead_provider: %i[lead_provider contract_period])
        .where(contract_type: :ittecf_ectp, lead_providers: { id: lead_provider.id })
        .merge(ContractPeriod.where(mentor_funding_enabled: true))
        .first!
      helper.add_bands!(ittecf_contract)

      ittecf_statement = helper.find_or_create_output_statement!(ittecf_contract)
      helper.log "ITTECF_ECTP (#{ittecf_contract.active_lead_provider.contract_period.year}): statement ##{ittecf_statement.id}, #{Date::MONTHNAMES[ittecf_statement.month]}", indent: 1

      helper.log "ECT declarations:", indent: 2
      helper.create_declarations!(statement: ittecf_statement, declaration_counts: helper::ECT_DECLARATION_COUNTS, participant_type: :ect)

      helper.log "Mentor declarations:", indent: 2
      helper.create_declarations!(statement: ittecf_statement, declaration_counts: helper::MENTOR_DECLARATION_COUNTS, participant_type: :mentor)
    end

    helper.log "Done! View statements in the finance console for '#{lead_provider.name}'."
  end
end
