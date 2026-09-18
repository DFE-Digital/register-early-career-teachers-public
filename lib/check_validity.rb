# How to:
#
# 1. Deploy pdh/3260-invalid-record-checker to migration
#
# 2. Wait for the following day or trigger:
#    kubectl exec -i -t -n cpd-production deployment/cpd-ec2-migration-worker -- rails runner "CheckValidity.new.call"
#
# 3. Optionally pass in tables and batch size, but if validations cross associations you should consider committing preloads
#
class CheckValidity
  class ProductionGuardError < StandardError; end

  BATCH_SIZE = 10_000

  TABLES = %w[
    induction_periods
    teachers
  ].freeze

  EAGER_LOAD = {
    induction_periods: [{ teacher: :induction_periods }],
    teachers: [],
  }.freeze

  def call(tables: TABLES, batch_size: BATCH_SIZE)
    raise ProductionGuardError, "Do not query live production data" if Rails.env.production?
    raise ArgumentError, "No tables specified" if tables.blank?

    tables.each do |table_name|
      seen_ids = []

      model = table_name.singularize.camelize.constantize
      preloads = EAGER_LOAD.fetch(table_name.to_sym, [])
      scope = preloads.any? ? model.includes(*preloads) : model

      scope.find_in_batches(batch_size:) do |batch|
        rows = batch.reject(&:valid?).map do |record|
          seen_ids << record.id

          {
            table_name:,
            record_id: record.id,
            error_messages: record.errors.full_messages.join("; ").truncate(2_000),
          }
        end

        next if rows.empty?

        InvalidRecord.upsert_all(rows, unique_by: %i[table_name record_id])
      end

      InvalidRecord.where(table_name:)
                   .where.not(record_id: seen_ids)
                   .delete_all
    end

    InvalidRecord.count
  end
end
