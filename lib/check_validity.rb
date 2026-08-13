class CheckValidity
  TABLES = %w[
    teachers
    appropriate_body_periods
    induction_periods
    induction_extensions
    training_periods
    declarations
  ].freeze

  BATCH_SIZE = 1_000

  def call(tables: TABLES)
    raise StandardError, "Do not query live production data" if Rails.env.production?
    raise ArgumentError, "No tables specified" if tables.blank?

    tables.each do |table_name|
      model = table_name.singularize.camelize.constantize

      model.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        rows = batch.reject(&:valid?).map do |record|
          {
            table_name:,
            record_id: record.id,
            error_messages: record.errors.full_messages.join("; "),
          }
        end

        next if rows.empty?

        InvalidRecord.upsert_all(rows, unique_by: %i[table_name record_id])
      end
    end
  end
end
