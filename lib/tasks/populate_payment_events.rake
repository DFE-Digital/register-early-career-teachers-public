namespace :bulk do
  desc "Generate payment events for ECF1 declarations"
  task populate_payment_events: :environment do
    paid_statements = Statement.status_paid
    results = {}

    Rails.logger.silence do
      paid_statements.find_in_batches(batch_size: 100) do |statements|
        statements.each do |statement|
          results[statement.id] = { id: statement.id, month: " #{statement.month}".rjust(2), year: statement.year, error: "" }

          puts("Processing statement #{statement.id} for #{statement.month}/#{statement.year}")

          counts = Backfill::RecordStatementPaymentEvents.new(statement).process

          results[statement.id].merge!(counts)

          format_counts = Backfill::RecordStatementPaymentEvents::DECLARATION_TYPES.map { |type|
            "#{type.to_s.humanize}: #{counts[type]}"
          }.join(", ")

          puts(
            "Processed statement #{statement.id}: " \
            "#{format_counts}"
          )
        rescue StandardError => e
          puts(
            "Failed processing statement #{statement.id}: #{e.class} #{e.message}"
          )

          results[statement.id][:error] = "#{e.class} #{e.message}"
        end
      end
    end

    puts("Results:")

    puts(
      results.values.map { |result|
        "Statement ID: #{result[:id]}, Month: #{result[:month]}, Year: #{result[:year]}, " \
        "#{Backfill::RecordStatementPaymentEvents::DECLARATION_TYPES.map { |type| "#{type.to_s.humanize}: #{result[type]}" }.join(', ')}" \
        ", Error: #{result[:error]}"
      }.join("\n")
    )
  end
end
