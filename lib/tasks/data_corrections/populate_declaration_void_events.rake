namespace :data_corrections do
  desc "Backfill missing voided and awaiting clawback events for declarations"
  task populate_declaration_void_events: :environment do
    created = 0
    skipped = 0

    declarations = Declaration
      .where.not(voided_by_user_id: nil)
      .includes(
        :voided_by_user,
        training_period: {
          ect_at_school_period: :teacher,
          mentor_at_school_period: :teacher
        }
      )

    Rails.logger.silence do
      declarations.find_each do |declaration|
        if Backfill::RecordDeclarationVoidEvent.new(declaration:).process
          created += 1
        else
          skipped += 1
        end
      end
    end

    puts "Created: #{created}, skipped: #{skipped}"
  end
end
