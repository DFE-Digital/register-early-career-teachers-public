namespace :trn do
  desc "Replace TRNs for teachers with permanent_redirect status"
  task replace: :environment do
    teachers = Teacher.where(trs_response: "permanent_redirect")

    Rails.logger.info("Replacing TRNs for #{teachers.count} teachers with permanent_redirect status")

    teachers.each do |teacher|
      Rails.logger.info("Replacing TRN for teacher with TRN #{teacher.trn} and replacement TRN #{teacher.trs_redirected_to}")
      Teachers::ReplaceTRN.new(teacher:).replace!
    end
  end
end
