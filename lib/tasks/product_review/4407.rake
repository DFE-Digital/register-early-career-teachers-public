namespace :product_review do
  desc "Add enough active and deactivated appropriate bodies to page through the admin list (#4407)"
  task "4407" => :environment do
    if AppropriateBodyPeriod.exists?(name: "Review Teaching School Hub 01")
      puts "Already set up."
      next
    end

    # 38 takes the seeds' 8 active bodies past two pages of 20, so the list
    # paginates and Shared::PaginationSummaryComponent stops hiding itself.
    ApplicationRecord.transaction do
      38.times { AppropriateBodyPeriod.create!(name: sprintf("Review Teaching School Hub %02d", it + 1), dfe_sign_in_organisation_id: SecureRandom.uuid) }
      12.times { AppropriateBodyPeriod.create!(name: sprintf("Deactivated Review Teaching School Hub %02d", it + 1)) }
    end

    puts "Done. #{AppropriateBodyPeriod.active.count} active, #{AppropriateBodyPeriod.inactive.count} deactivated."
  end
end
