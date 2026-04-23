namespace :schools do
  desc "Populate schools' previous choices (appropriate body, training programme, lead provider) from migrated ECT data"
  task populate_previous_choices: :environment do
    result = Schools::PopulatePreviousChoices.new.call

    puts "Done. Updated: #{result[:schools_updated]}, Skipped: #{result[:schools_skipped]}"
  end
end
