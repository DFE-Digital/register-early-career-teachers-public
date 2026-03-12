require_relative "../config/environment"

participant_profile_id = ARGV[0]
participant_profile = Migration::ParticipantProfile.find(participant_profile_id)
induction_records = Migration::InductionRecordExporter.new.where_participant_profile_id_is(participant_profile_id).rows
declarations = participant_profile.participant_declarations

gantt = Migration::PreMigrationGantt.new(induction_records, declarations, participant_profile)

File.write("/tmp/#{participant_profile_id}.png", gantt.to_png)
