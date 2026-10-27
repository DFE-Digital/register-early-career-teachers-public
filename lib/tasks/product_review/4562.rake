namespace :product_review do
  desc "Set up funding eligibility scenarios after TRN merges"
  task "4562" => :environment do
    school = School.find_by!(urn: 1_759_427)
    started_on = Date.new(2026, 9, 1)
    induction_started_on = started_on + 7.days
    existing_eligible_at = started_on - 1.month
    finished_on = started_on + 1.day
    existing_ineligible_on = finished_on - 1.day
    completed_evidenced_at = (finished_on + 7.days).in_time_zone

    scenarios = [
      {
        name: "ECT TRS date",
        role: :ect,
        attributes: { trs_induction_start_date: induction_started_on },
        expected: "ECT eligibility becomes #{induction_started_on}"
      },
      {
        name: "ECT registration date",
        role: :ect,
        expected: "ECT eligibility becomes #{started_on}"
      },
      {
        name: "ECT not started",
        role: :ect,
        attributes: { trs_induction_status: "RequiredToComplete" },
        expected: "ECT eligibility remains unset"
      },
      {
        name: "ECT existing eligibility",
        role: :ect,
        attributes: {
          trs_induction_start_date: induction_started_on,
          ect_first_became_eligible_for_training_at: existing_eligible_at.in_time_zone
        },
        expected: "ECT eligibility stays #{existing_eligible_at}"
      },
      {
        name: "ECT exempt",
        role: :ect,
        attributes: { trs_induction_status: "Exempt" },
        expected: "ECT ineligibility becomes the date the correction runs"
      },
      {
        name: "ECT already ineligible",
        role: :ect,
        attributes: {
          trs_induction_status: "Exempt",
          ect_became_ineligible_for_funding_on: existing_ineligible_on
        },
        expected: "ECT ineligibility stays #{existing_ineligible_on}"
      },
      {
        name: "ECT declarations",
        role: :ect,
        declarations: true,
        attributes: { trs_induction_start_date: induction_started_on },
        expected: "ECT eligibility restored; no_payment becomes eligible; voided stays voided"
      },
      {
        name: "ECT without merge",
        role: :ect,
        merged: false,
        attributes: { trs_induction_start_date: induction_started_on },
        expected: "All eligibility attributes remain unchanged"
      },
      {
        name: "Mentor missing eligibility",
        role: :mentor,
        training: true,
        expected: "Mentor eligibility becomes #{started_on}"
      },
      {
        name: "Mentor without training",
        role: :mentor,
        expected: "Mentor eligibility remains unset"
      },
      {
        name: "Mentor existing eligibility",
        role: :mentor,
        training: true,
        attributes: {
          mentor_first_became_eligible_for_training_at: existing_eligible_at.in_time_zone
        },
        expected: "Mentor eligibility stays #{existing_eligible_at}"
      },
      {
        name: "Mentor declarations",
        role: :mentor,
        declarations: true,
        expected: "Mentor eligibility restored; no_payment becomes eligible; voided stays voided"
      },
      {
        name: "Mentor completed",
        role: :mentor,
        declarations: true,
        completed: true,
        expected: "Mentor ineligibility becomes #{completed_evidenced_at.to_date}, reason completed_declaration_received; eligibility remains unset; declarations stay no_payment and voided"
      },
      {
        name: "Mentor already ineligible",
        role: :mentor,
        declarations: true,
        completed: true,
        attributes: {
          mentor_became_ineligible_for_funding_on: existing_ineligible_on,
          mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out"
        },
        expected: "Mentor ineligibility stays #{existing_ineligible_on}, reason completed_during_early_roll_out; eligibility remains unset; declarations stay no_payment and voided"
      },
      {
        name: "Mentor with past induction",
        role: :mentor,
        training: true,
        attributes: { trs_induction_start_date: started_on - 2.years },
        expected: "Mentor eligibility becomes #{started_on}; ECT eligibility remains unset"
      },
      {
        name: "Mentor ineligible with training",
        role: :mentor,
        training: true,
        attributes: {
          mentor_became_ineligible_for_funding_on: existing_ineligible_on,
          mentor_became_ineligible_for_funding_reason: "started_not_completed"
        },
        expected: "Mentor eligibility remains unset; ineligibility stays #{existing_ineligible_on}, reason started_not_completed"
      },
      {
        name: "Mentor voided completion",
        role: :mentor,
        declarations: true,
        completed: true,
        completion_voided: true,
        expected: "Mentor eligibility becomes #{started_on}; ineligibility remains unset; no_payment becomes eligible; voided declarations stay voided"
      }
    ]

    scenarios.each_with_index do |scenario, index|
      scenario[:trn] = (9_904_001 + index).to_s
    end

    existing_trns = Teacher.where(trn: scenarios.pluck(:trn)).pluck(:trn)

    if existing_trns.any?
      puts "Scenario TRNs already exist: #{existing_trns.join(', ')}. Aborting."
      next
    end

    ApplicationRecord.transaction do
      payment_statement = FactoryBot.create(:statement)
      other_statement = FactoryBot.create(:statement)
      framework_agreement = payment_statement.framework_agreement
      year = payment_statement.contract_period.year

      school_partnership = FactoryBot.create(
        :school_partnership,
        :for_year,
        school:,
        year:,
        framework_agreement:
      )

      scenarios.each do |scenario|
        role = scenario.fetch(:role)

        if scenario[:declarations]
          declaration = FactoryBot.create(
            :declaration,
            :"with_#{role}",
            started_on:,
            payment_statement:,
            school_partnership:
          )

          training_period = declaration.training_period
          school_period = training_period.public_send(:"#{role}_at_school_period")
          teacher = school_period.teacher

          FactoryBot.create(
            :declaration,
            :voided,
            payment_statement: other_statement,
            training_period:
          )

          if scenario[:completed]
            FactoryBot.create(
              :declaration,
              declaration_type: :completed,
              evidenced_at: completed_evidenced_at,
              payment_status: scenario[:completion_voided] ? :voided : :no_payment,
              payment_statement: other_statement,
              training_period:
            )

            training_period.update!(finished_on:)
          end
        else
          teacher = FactoryBot.create(:teacher)

          school_period = FactoryBot.create(
            :"#{role}_at_school_period",
            :unfinished,
            teacher:,
            school:,
            started_on:
          )

          if scenario[:training]
            FactoryBot.create(
              :training_period,
              :for_mentor,
              mentor_at_school_period: school_period,
              started_on:
            )
          end
        end

        unless scenario[:merged] == false
          FactoryBot.create(:event, event_type: :teacher_merged, teacher:)
        end

        teacher.update_columns(
          {
            trn: scenario.fetch(:trn),
            trs_first_name: "Review",
            trs_last_name: scenario.fetch(:name),
            trs_induction_status: role == :ect ? "InProgress" : "RequiredToComplete",
            trs_induction_start_date: nil,
            ect_first_became_eligible_for_training_at: nil,
            ect_became_ineligible_for_funding_on: nil,
            mentor_first_became_eligible_for_training_at: nil,
            mentor_became_ineligible_for_funding_on: nil,
            mentor_became_ineligible_for_funding_reason: nil
          }.merge(scenario.fetch(:attributes, {}))
        )
      end
    end

    puts "Created #{scenarios.size} teachers at Abbey Grove."
    puts

    scenarios.each do |scenario|
      puts "----------------------------------------"
      puts "#{scenario.fetch(:trn)} — Review #{scenario.fetch(:name)}"
      puts "  Expected: #{scenario.fetch(:expected)}"
    end
  end
end
