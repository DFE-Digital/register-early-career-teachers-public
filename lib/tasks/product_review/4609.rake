namespace :product_review do
  desc "Set up all training period partnership and EOI merge scenarios (#4609)"
  task "4609" => :environment do
    abort("Only available for non-production environments") if Rails.env.production?

    scenario_names = %w[
      matching_partnership_different_eois
      source_eoi_destination_partnership
      source_partnership_destination_eoi
      matching_eois
      different_eois
      mismatched_eoi_destination_partnership
      different_partnerships
    ]

    scenario_trns = scenario_names.each_with_index.to_h do |scenario, index|
      [
        scenario,
        {
          source: sprintf("%07d", 4609 + (index * 10)),
          destination: sprintf("%07d", 4611 + (index * 10)),
          mentor: sprintf("%07d", 4610 + (index * 10))
        }
      ]
    end

    trns = scenario_trns.values.flat_map(&:values)
    abort("All source, destination and mentor TRNs must be distinct.") unless trns.uniq.size == trns.size

    existing_trns = Teacher.where(trn: trns).pluck(:trn)
    if existing_trns.any?
      abort("No records created. These TRNs already exist in RECT: #{existing_trns.join(', ')}")
    end

    school = School.find_by!(urn: 1_759_427)
    contract_period = ContractPeriod.find_by!(year: 2025)
    teach_first = LeadProvider.find_by!(name: "Teach First")
    ambition = LeadProvider.find_by!(name: "Ambition Institute")

    school_partnership = SchoolPartnerships::Search.new(
      school:,
      lead_provider: teach_first,
      contract_period:
    ).school_partnerships.first!

    other_school_partnership = SchoolPartnerships::Search.new(
      school:,
      lead_provider: ambition,
      contract_period:
    ).school_partnerships.first!

    schedule = Schedule.find_by!(
      contract_period:,
      identifier: "ecf-standard-september"
    )

    partnership_attributes = { school_partnership: }
    other_partnership_attributes = { school_partnership: other_school_partnership }
    matching_eoi_attributes = { expression_of_interest: school_partnership.framework_agreement }
    other_eoi_attributes = { expression_of_interest: other_school_partnership.framework_agreement }

    scenario_training_attributes = {
      "matching_partnership_different_eois" => [
        partnership_attributes.merge(other_eoi_attributes),
        partnership_attributes.merge(matching_eoi_attributes)
      ],
      "source_eoi_destination_partnership" => [matching_eoi_attributes, partnership_attributes],
      "source_partnership_destination_eoi" => [partnership_attributes, matching_eoi_attributes],
      "matching_eois" => [matching_eoi_attributes, matching_eoi_attributes],
      "different_eois" => [other_eoi_attributes, matching_eoi_attributes],
      "mismatched_eoi_destination_partnership" => [other_eoi_attributes, partnership_attributes],
      "different_partnerships" => [other_partnership_attributes, partnership_attributes]
    }

    previous_queue_adapter = ActiveJob::Base.queue_adapter

    begin
      review_rows = ApplicationRecord.transaction do
        scenario_teachers = scenario_trns.map do |scenario, teacher_trns|
          teacher_attributes = {
            trs_first_name: "Review",
            trs_last_name: "Merge",
            trs_qts_awarded_on: Date.new(2023, 1, 1),
            trs_induction_status: "InProgress"
          }

          source = Teacher.create!(**teacher_attributes, trn: teacher_trns.fetch(:source), trs_response: "ok")
          destination = Teacher.create!(**teacher_attributes, trn: teacher_trns.fetch(:destination), trs_response: "ok")

          mentor = Teacher.create!(
            trn: teacher_trns.fetch(:mentor),
            trs_first_name: "Review",
            trs_last_name: "Mentor",
            trs_qts_awarded_on: Date.new(2020, 7, 1),
            trs_induction_status: "Passed"
          )

          mentor_school_period = MentorAtSchoolPeriod.create!(
            teacher: mentor,
            school:,
            started_on: Date.new(2025, 9, 1),
            finished_on: nil
          )

          source_training_attributes, destination_training_attributes = scenario_training_attributes.fetch(scenario)

          histories = [
            [source, source_training_attributes, Date.new(2025, 9, 1), Date.new(2025, 10, 31), "started"],
            [source, source_training_attributes, Date.new(2025, 11, 1), Date.new(2025, 12, 31), "retained-2"],
            [destination, destination_training_attributes, Date.new(2025, 10, 1), nil, "retained-1"]
          ]

          histories.each do |teacher, training_attributes, started_on, finished_on, declaration_type|
            school_period = ECTAtSchoolPeriod.create!(
              teacher:,
              school:,
              working_pattern: "full_time",
              started_on:,
              finished_on:
            )

            training_period = TrainingPeriod.create!(
              ect_at_school_period: school_period,
              training_programme: "provider_led",
              **training_attributes,
              schedule:,
              started_on:,
              finished_on:
            )

            MentorshipPeriod.create!(
              mentee: school_period,
              mentor: mentor_school_period,
              started_on:,
              finished_on:
            )

            next if training_period.school_partnership.blank?

            Declaration.create!(
              training_period:,
              declaration_type:,
              evidenced_at: started_on + 14.days,
              evidence_type: "training-event-attended",
              payment_status: :no_payment,
              clawback_status: :no_clawback,
              api_id: SecureRandom.uuid,
              delivery_partner_when_created: training_period.delivery_partner
            )
          end

          [scenario, source, destination]
        end

        ActiveJob::Base.queue_adapter = :inline
        scenario_teachers.each do |_scenario, source, destination|
          Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
            trs_data_last_refreshed_at: Time.zone.now,
            redirected_to: destination.trn,
            event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
          )
        end
      end
    ensure
      ActiveJob::Base.queue_adapter = previous_queue_adapter
    end

    puts "| Scenario | Source teacher page | Destination teacher page |"
    puts "| --- | --- | --- |"
    review_rows.each do |scenario, source, destination|
      puts "| `#{scenario}` | `/admin/teachers/#{source.id}` | `/admin/teachers/#{destination.id}` |"
    end
  end
end
