namespace :bulk do
  desc "Generate payment events for ECF1 declarations"
  task :populate_payment_events, %i[year month] => :environment do |_task, args|
    year = args[:year]&.to_s&.to_i
    month = args[:month]&.to_s&.to_i

    raise ArgumentError, "Year is required" if year.blank?
    raise ArgumentError, "Month must be between 1 and 12" if month.present? && !month.between?(1, 12)

    paid_statements = Statement.output_fee.status_paid.where(year:)

    paid_statements = paid_statements.where(month:) if month.present?

    puts "Found #{paid_statements.count} paid output fee statements for year #{year}#{month.present? ? ", month #{month}" : ''}"

    Rails.logger.silence do
      paid_statements.find_in_batches(batch_size: 20).with_index do |statements, index|
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
            declaration_results =
              Backfill::RecordStatementPaymentEvents::DECLARATION_TYPES.map { |type|
                "#{type.to_s.humanize}: #{result[type].to_s.rjust(7)}"
              }.join(", ")

            "Statement ID: #{result[:id]}, " \
              "Month: #{sprintf('%02d', result[:month])}, " \
              "Year: #{result[:year]}, " \
              "#{declaration_results}, " \
              "Error: #{result[:error]}"
          }.join("\n")
        )
      end
    end
  end
end
