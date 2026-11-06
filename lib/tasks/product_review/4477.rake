namespace :product_review do
  desc "Reset the persona schools' induction tutors for the new, update and confirm existing induction tutor journeys (#4477)"
  task "4477" => :environment do
    abort("Only available for non-production environments") if Rails.env.production?

    contract_period = ContractPeriod.current_or_upcoming or abort("There is no current or upcoming contract period")
    previous_contract_period = ContractPeriod.find_by!(year: contract_period.year - 1)

    abbey_grove = School.find_by!(urn: 1_759_427)
    brookfield = School.find_by!(urn: 2_976_163)
    greyfriars = School.find_by!(urn: 6_384_201)

    ApplicationRecord.transaction do
      abbey_grove.update!(induction_tutor_name: "Ada Lovelace", induction_tutor_email: "ada.lovelace@example.com", induction_tutor_last_nominated_in: contract_period)
      brookfield.update!(induction_tutor_name: "Grace Hopper", induction_tutor_email: "grace.hopper@example.com", induction_tutor_last_nominated_in: previous_contract_period)
      greyfriars.update!(induction_tutor_name: nil, induction_tutor_email: nil, induction_tutor_last_nominated_in: nil)
    end

    puts
    puts "=" * 78
    puts "  Induction tutor journeys (#4477)"
    puts "=" * 78
    puts
    puts "  Update (Bob Belcher, Abbey Grove School):"
    puts "    Ada Lovelace, confirmed for #{contract_period.year}"
    puts "  Confirm existing (Serena Moon, Brookfield School):"
    puts "    Grace Hopper, last confirmed for #{previous_contract_period.year}"
    puts "  New (Felix Starling, Greyfriars School):"
    puts "    no induction tutor"
    puts
    puts "  Run this task again to reset all three schools."
    puts
  end
end
