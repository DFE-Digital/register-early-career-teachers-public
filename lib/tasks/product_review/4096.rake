namespace :product_review do
  desc "Point two Abbey Grove ECTs at a lead provider with no current framework agreement (#4096)"
  task "4096" => :environment do
    capita = LeadProvider.find_by!(name: "Capita")
    lapsed_contract_period = ContractPeriod.find_by!(year: 2023)
    expression_of_interest = FrameworkAgreement.find_by!(lead_provider: capita, contract_period: lapsed_contract_period)

    lapse_current_training = ->(trn) do
      ect_at_school_period = ECTAtSchoolPeriod.find_by!(teacher: Teacher.find_by!(trn:), finished_on: nil)

      ect_at_school_period.training_periods.sole.update!(
        school_partnership: nil,
        expression_of_interest:,
        finished_on: nil
      )
    end

    ApplicationRecord.transaction do
      lapse_current_training.call("0000008") # Kate Winslet, no mentor
      lapse_current_training.call("0000011") # Anthony Hopkins, mentored by Hugh Grant
    end

    puts
    puts "=" * 78
    puts "  Mentor training when the ECT's lead provider has no current agreement (#4096)"
    puts "=" * 78
    puts
    puts "  Changed by this task, both at Abbey Grove School:"
    puts "    - Kate Winslet and Anthony Hopkins are now training with #{capita.name} through an"
    puts "      expression of interest from #{lapsed_contract_period.year}, and their training is ongoing."
    puts "      #{capita.name} has no framework agreement for #{ContractPeriod.current&.year}, so it can no longer"
    puts "      train their mentors."
    puts
    puts "  To verify, signed in as the Abbey Grove school user:"
    puts "    1. Go to Kate Winslet and choose 'Assign a mentor for this ECT'"
    puts "    2. Pick Hugh Grant and continue"
    puts "       Expect 'Which lead provider would you like to contact your school"
    puts "       about training Hugh Grant?' — NOT the '#{capita.name} can train them' page,"
    puts "       which is where the reported error happened"
    puts "    3. Check the providers listed are the ones active for #{ContractPeriod.current&.year},"
    puts "       and that #{capita.name} is not among them"
    puts "    4. Choose one and continue. Expect the mentorship confirmation page."
    puts "    5. For the change mentor journey, go to Anthony Hopkins and change his"
    puts "       mentor from Hugh Grant to Emma Thompson. Expect the same question."
    puts
  end
end
