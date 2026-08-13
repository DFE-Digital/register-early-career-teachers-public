class CheckValidity
  class ProductionGuardError < StandardError; end

  TABLES = %w[
    teachers
    appropriate_body_periods
    induction_periods
    induction_extensions
    training_periods
    declarations
  ].freeze

  def call(tables: TABLES, batch_size: 1_000)
    raise ProductionGuardError, "Do not query live production data" if Rails.env.production?
    raise ArgumentError, "No tables specified" if tables.blank?

    tables.each do |table_name|
      InvalidRecord.where(table_name:).delete_all

      model = table_name.singularize.camelize.constantize

      model.find_in_batches(batch_size:) do |batch|
        rows = batch.reject(&:valid?).map do |record|
          {
            table_name:,
            record_id: record.id,
            error_messages: record.errors.full_messages.join("; ").truncate(2_000),
          }
        end

        next if rows.empty?

        InvalidRecord.upsert_all(rows, unique_by: %i[table_name record_id])
      end
    end

    InvalidRecord.count
  end
end
