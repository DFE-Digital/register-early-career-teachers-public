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
      unless statement.status_paid?
        puts("- #{statement.id} event cannot be created because statement is not paid")
        return {}
      end

      unless statement.output_fee?
        puts("- #{statement.id} event cannot be created for service statements")
        return {}
      end

      processed = DECLARATION_TYPES.index_with { 0 }
      updated = DECLARATION_TYPES.index_with { 0 }

      paid_declarations.find_in_batches(batch_size: 500) do |declarations|
        ActiveRecord::Base.transaction do
          declarations.each do |declaration|
            type = declaration_type(declaration)

            processed[type] += 1

            next unless declaration_event_created?(declaration, statement, :paid)

            updated[type] += 1
          end
        end
      end

      clawed_back_declarations.find_in_batches(batch_size: 500) do |declarations|
        ActiveRecord::Base.transaction do
          declarations.each do |declaration|
            processed[:clawed_back] += 1

            next unless declaration_event_created?(
              declaration,
              declaration.clawback_statement,
              :clawed_back
            )

            updated[:clawed_back] += 1
          end
        end
      end

      ActiveRecord::Base.transaction do
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
        happened_at:,
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

    def happened_at
      statement.marked_as_paid_at || statement.payment_date
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
        "#{updated[type]}/#{processed[type]}"
      end
    end
  end
end
