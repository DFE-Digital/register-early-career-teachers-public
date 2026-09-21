teachers_file = Rails.root.join("db/scripts/remove_wrongly_assigned_ect_first_became_eligible_for_training_at.csv")

# the `Teacher.ect_first_became_eligible_for_training_at` cannot be changed once set so son-of-patch cannot
# update the value without modificiations so handling separately here as a special case.
#
CSV.foreach(teachers_file, headers: true, header_converters: :symbol) do |row|
  teacher = Teacher.find(row[:object_id])
  teacher.update_attribute(:ect_first_became_eligible_for_training_at, nil) # rubocop:disable Rails/SkipsModelValidations
rescue ActiveRecord::RecordNotFound
  Rails.logger.warn("Could not find teacher with id [#{row[:object_id]}]")
end
