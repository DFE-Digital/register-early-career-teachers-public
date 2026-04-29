namespace :product_review do
  desc "Set up teachers who are ineligable for mentor funding (#3878)"
  task "3878" => :environment do
    Rails.logger.info "Setting up teachers who are ineligible for mentor funding"

    reasons = %w[completed_declaration_received completed_during_early_roll_out started_not_completed]

    CANDIDATE_TEACHERS.each_with_index do |teacher_attrs, i|
      teacher = Teacher.find_or_initialize_by(trn: teacher_attrs[:trn])

      teacher_attrs[:started_on] || Date.new(2024, 8 + i, 1)

      teacher.trs_first_name = teacher_attrs[:first_name]
      teacher.trs_last_name = teacher_attrs[:last_name]
      teacher.mentor_became_ineligible_for_funding_on = Date.new(2021 + i, 4, 19)
      teacher.mentor_became_ineligible_for_funding_reason = reasons[i]
      teacher.save!
    end
  end
end

CANDIDATE_TEACHERS = [
  { trn: "3002577", first_name: "Jonas",    last_name: "Bloggs" },
  { trn: "3002578", first_name: "Cynthia",  last_name: "Parks" },
  { trn: "3002579", first_name: "Taylor",   last_name: "Hawkins" },
].freeze
