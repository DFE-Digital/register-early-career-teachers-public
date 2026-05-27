module Backfill
  class RecordStatementPaymentEvents
    attr_reader :statement

    DECLARATION_TYPES = %i[
      started
      retained
      extended
      completed
      clawed_back
    ].freeze

    def initialize(statement)
      @statement = statement
    end

    def process
      counts = DECLARATION_TYPES.index_with { 0 }

      ActiveRecord::Base.transaction do
        paid_declarations.find_each do |declaration|
          next unless declaration_event_created?(declaration, statement, :paid)

          counts[declaration_type(declaration)] += 1
        end

        clawed_back_declarations.find_each do |declaration|
          next unless declaration_event_created?(declaration, declaration.clawback_statement, :clawed_back)

          counts[:clawed_back] += 1
        end

        record_statement_authorized_for_payment_event!
      end

      counts
    end

  private

    delegate :active_lead_provider, to: :statement
    delegate :lead_provider, to: :active_lead_provider

    def declaration_type(declaration)
      declaration.declaration_type.split("-").first.to_sym
    end

    def declaration_event_created?(declaration, statement, status)
      RecordDeclarationEvent.new(
        declaration:,
        status:,
        statement:
      ).process
    end

    def record_statement_authorized_for_payment_event!
      if statement_authorized_event_exists?
        puts("Statement: #{statement.id} Authorised for payment event already exists")
        return
      end

      Event.create!(
        event_type: "statement_authorised_for_payment",
        heading: "Statement authorised for payment",
        happened_at: statement.payment_date,
        statement:,
        lead_provider:,
        active_lead_provider:,
        metadata: {
          contract_period_year: active_lead_provider.contract_period_year
        },
        author_name: "System",
        author_type: "system"
      )

      puts("Statement: #{statement.id} Authorised for payment event created")
    end

    def statement_authorized_event_exists?
      Event.where(
        event_type: "statement_authorised_for_payment",
        statement:
      ).exists?
    end

    def paid_declarations
      statement.payment_declarations.payment_status_paid
    end

    def clawed_back_declarations
      statement
        .clawback_declarations
        .clawback_status_clawed_back
        .includes(:clawback_statement)
    end
  end
end
