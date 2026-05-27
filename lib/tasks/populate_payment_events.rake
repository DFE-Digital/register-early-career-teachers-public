namespace :bulk do
  desc "Generate payment events for ECF1 declarations"
  task populate_payment_events: :environment do
    paid_statements = Statement.status_paid

    Rails.logger.silence do
      paid_statements.find_in_batches(batch_size: 100).with_index do |statements, index|
        puts(
          "------------------------------------------------------------------------------\n" \
          "Starting batch #{index + 1} " \
          "(statement ids #{statements.first.id} - #{statements.last.id})"
        )

        results = {}

        statements.each do |statement|
          results[statement.id] = { id: statement.id, month: statement.month, year: statement.year, error: "" }

          counts = Backfill::RecordStatementPaymentEvents.new(statement).process

          results[statement.id].merge!(counts)
        rescue StandardError => e
          puts(
            "Failed processing statement #{statement.id}: #{e.class} #{e.message}"
          )

          results[statement.id][:error] = "#{e.class} #{e.message}"
        end

        puts(
          "------------------------------------------------------------------------------\n" \
          "Results:"
        )

        puts(
          results.values.map { |result|
            "Statement ID: #{result[:id]}, Month: #{sprintf('%02d', result[:month])}, Year: #{result[:year]}, " \
            "#{Backfill::RecordStatementPaymentEvents::DECLARATION_TYPES.map { |type| "#{type.to_s.humanize}: #{result[type].to_s.rjust(3)}" }.join(', ')}" \
            ", Error: #{result[:error]}"
          }.join("\n")
        )
      end
    end
  end
end
