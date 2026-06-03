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
      processed = DECLARATION_TYPES.index_with { 0 }
      updated = DECLARATION_TYPES.index_with { 0 }

      ActiveRecord::Base.transaction do
        paid_declarations.find_each do |declaration|
          processed[declaration_type(declaration)] += 1

          next unless declaration_event_created?(declaration, statement, :paid)

          updated[declaration_type(declaration)] += 1
        end

        clawed_back_declarations.find_each do |declaration|
          processed[:clawed_back] += 1

          next unless declaration_event_created?(declaration, declaration.clawback_statement, :clawed_back)

          updated[:clawed_back] += 1
        end

        record_statement_authorised_for_payment_event!
      end

      format_output(processed, updated)
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

    def record_statement_authorised_for_payment_event!
      if statement_authorised_event_exists?
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

    def statement_authorised_event_exists?
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

    def format_output(processed, updated)
      DECLARATION_TYPES.index_with do |type|
        "#{updated[type]} / #{processed[type]}"
      end
    end
  end
end
