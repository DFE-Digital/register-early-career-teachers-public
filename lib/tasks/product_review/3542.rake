namespace :product_review do
  desc "Set up mentor training content scenarios at Abbey Grove (#3542)"
  task "3542" => :environment do
    school = School.find_by!(urn: 1_759_427) # Abbey Grove
    contract_period = ContractPeriod.find_by!(year: 2025)

    lead_provider = LeadProvider.find_by!(name: "Ambition Institute")
    active_lead_provider = ActiveLeadProvider.find_by!(contract_period:, lead_provider:)
    delivery_partner = DeliveryPartner.find_by!(name: "Artisan Education Group")

    lpdp = LeadProviderDeliveryPartnership.find_or_create_by!(active_lead_provider:, delivery_partner:)
    partnership = SchoolPartnership.find_or_create_by!(school:, lead_provider_delivery_partnership: lpdp)
    schedule = Schedule.find_by!(contract_period:, identifier: "ecf-standard-september")

    scenarios = []

    hugh_laurie = Teacher.find_by(trn: "0000011")
    if hugh_laurie
      scenarios << {
        ac: "1 + 5a",
        name: "#{hugh_laurie.trs_first_name} #{hugh_laurie.trs_last_name}",
        list: "No training content shown (completion date takes priority)",
        details: "Shows 'completed mentor training on [date]'",
        note: "From seeds — completed_during_early_roll_out"
      }
    end

    teacher_5b = find_or_create_teacher!("0000041", "Peter", "Sellers")
    teacher_5b.update!(
      mentor_became_ineligible_for_funding_on: Date.new(2024, 3, 15),
      mentor_became_ineligible_for_funding_reason: "started_not_completed"
    )
    find_or_create_mentor!(teacher_5b, school, Date.new(2023, 9, 1))
    scenarios << {
      ac: "1 + 5b",
      name: "Peter Sellers",
      list: "No training content shown (completion date takes priority)",
      details: "Shows 'cannot do further mentor training'"
    }

    teacher_5a_cdr = find_or_create_teacher!("0000042", "Maggie", "Smith")
    teacher_5a_cdr.update!(
      mentor_became_ineligible_for_funding_on: Date.new(2024, 6, 1),
      mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
    )
    find_or_create_mentor!(teacher_5a_cdr, school, Date.new(2023, 9, 1))
    scenarios << {
      ac: "1 + 5a",
      name: "Maggie Smith",
      list: "No training content shown (completion date takes priority)",
      details: "Shows 'completed mentor training on 1 June 2024'"
    }

    teacher_2 = find_or_create_teacher!("0000043", "Michael", "Caine")
    mentor_2 = find_or_create_mentor!(teacher_2, school, Date.new(2023, 9, 1))
    unless mentor_2.training_periods.exists?
      FactoryBot.create(:training_period,
                        :for_mentor,
                        mentor_at_school_period: mentor_2,
                        started_on: Date.new(2023, 9, 1),
                        finished_on: Date.new(2024, 6, 30),
                        school_partnership: partnership,
                        schedule:,
                        training_programme: "provider_led")
    end
    scenarios << {
      ac: "2",
      name: "Michael Caine",
      list: "No training content shown (training finished, not deferred/withdrawn)",
      details: "No 'ECTE mentor training details' section shown"
    }

    teacher_7 = find_or_create_teacher!("0000044", "Judi", "Dench")
    find_or_create_mentor!(teacher_7, school, Date.new(2024, 9, 1))
    scenarios << {
      ac: "2 + 7",
      name: "Judi Dench",
      list: "No training content shown (no training period)",
      details: "No 'ECTE mentor training details' section shown"
    }

    teacher_3d = find_or_create_teacher!("0000045", "Ian", "McKellen")
    mentor_3d = find_or_create_mentor!(teacher_3d, school, Date.new(2024, 9, 1))
    unless mentor_3d.training_periods.exists?
      FactoryBot.create(:training_period,
                        :for_mentor,
                        :deferred,
                        mentor_at_school_period: mentor_3d,
                        started_on: Date.new(2024, 9, 1),
                        finished_on: Date.new(2025, 1, 15),
                        school_partnership: partnership,
                        schedule:)
    end
    scenarios << {
      ac: "3 + 6",
      name: "Ian McKellen",
      list: "Shows deferred message (training is paused)",
      details: "Shows deferred message + LP/DP summary list"
    }

    teacher_3w = find_or_create_teacher!("0000046", "Patrick", "Stewart")
    mentor_3w = find_or_create_mentor!(teacher_3w, school, Date.new(2024, 9, 1))
    unless mentor_3w.training_periods.exists?
      FactoryBot.create(:training_period,
                        :for_mentor,
                        :withdrawn,
                        mentor_at_school_period: mentor_3w,
                        started_on: Date.new(2024, 9, 1),
                        finished_on: Date.new(2025, 2, 1),
                        school_partnership: partnership,
                        schedule:)
    end
    scenarios << {
      ac: "3 + 6",
      name: "Patrick Stewart",
      list: "Shows withdrawn message (not registered with LP)",
      details: "Shows withdrawn message + 'select a lead provider' link"
    }

    emma = Teacher.find_by(trn: "0000004")
    if emma
      scenarios << {
        ac: "4 + 6",
        name: "#{emma.trs_first_name} #{emma.trs_last_name}",
        list: "Shows LP/DP details on right side",
        details: "Shows LP/DP summary list with Change link",
        note: "From seeds — active training"
      }
    end

    puts
    puts "=" * 80
    puts "  Mentor training scenarios at Abbey Grove (sign in as Bob Belcher)"
    puts "=" * 80
    puts

    scenarios.each do |s|
      puts sprintf("  AC %-6s  %-20s", s[:ac], s[:name])
      puts sprintf("             List page:    %s", s[:list])
      puts sprintf("             Details page: %s", s[:details])
      puts sprintf("             (%s)", s[:note]) if s[:note]
      puts
    end
  end
end

def find_or_create_teacher!(trn, first_name, last_name)
  Teacher.find_or_create_by!(trn:) do |t|
    t.trs_first_name = first_name
    t.trs_last_name = last_name
    t.trs_qts_awarded_on = Date.new(2021, 1, 1)
  end
end

def find_or_create_mentor!(teacher, school, started_on)
  existing = teacher.mentor_at_school_periods.find_by(school:)
  return existing if existing

  MentorAtSchoolPeriod.create!(
    teacher:,
    school:,
    started_on:,
    finished_on: nil
  )
end
