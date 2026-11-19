ambition = LeadProvider.find_by!(name: "Ambition Institute")
teach_first = LeadProvider.find_by!(name: "Teach First")

# Schools
abbey_grove_school = School.find_by!(urn: 1_759_427)
ackley_bridge = School.find_by!(urn: 3_375_958)
mallory_towers = School.find_by!(urn: 5_279_293)
brookfield_school = School.find_by!(urn: 2_976_163)
ashford_independent_school = School.find_by!(urn: 9_123_458)

# Appropriate bodies
south_yorkshire_studio_hub = AppropriateBodyPeriod.with_display_name("South Yorkshire Studio Hub").first!
golden_leaf_teaching_school_hub = AppropriateBodyPeriod.with_display_name("Golden Leaf Teaching School Hub").first!
umber_teaching_school_hub = AppropriateBodyPeriod.with_display_name("Umber Teaching School Hub").first!

def teacher(...) = TeacherHistories::TeacherBuilder.teacher(...)

Induction::ScenarioBuilder.define do
  scenario :new_ect_provider_led_claim, id: 1 do |trn, name, _index|
    teacher(trn, name) do
      description("New ECT for provider-led, ready to claim")
      ect_at_school_period(abbey_grove_school, "2026-09-01", school_reported_appropriate_body: golden_leaf_teaching_school_hub) do
        training_period(ambition, 2026, "2026-09-01")
      end
    end
  end

  scenario :new_ect_school_led_claim, id: 2 do |trn, name, _index|
    teacher(trn, name) do
      description("New ECT for school-led, ready to claim")
      ect_at_school_period(ackley_bridge, "2026-09-01", school_reported_appropriate_body: golden_leaf_teaching_school_hub) do
        school_led_training_period("2026-09-01")
      end
    end
  end

  scenario :released_ect_to_claim, id: 3 do |trn, name, _index|
    teacher(trn, name) do
      description("Previously released ECT, ready to claim")
      ect_at_school_period(ackley_bridge, "2025-09-01") do
        school_led_training_period("2025-09-01")
      end
      induction_period(south_yorkshire_studio_hub, "2025-09-01 -> 2026-01-01")
    end
  end

  scenario :ongoing_provider_led_ect_to_pass, id: 4 do |trn, name, _index|
    teacher(trn, name) do
      description("ECT with ongoing provider-led training, ready to pass")
      ect_at_school_period(abbey_grove_school, "2024-09-01") do
        training_period(teach_first, 2024, "2024-09-01") do
          declaration("started",    "2024-09-15")
          declaration("retained-1", "2025-01-06")
        end
      end
      induction_period(golden_leaf_teaching_school_hub, "2024-09-01")
    end
  end

  scenario :ongoing_school_led_ect_to_pass, id: 5 do |trn, name, _index|
    teacher(trn, name) do
      description("ECT with ongoing school-led training, ready to pass")
      ect_at_school_period(brookfield_school, "2024-09-01") do
        school_led_training_period("2024-09-01")
      end
      induction_period(golden_leaf_teaching_school_hub, "2024-09-01")
    end
  end

  scenario :ongoing_provider_led_ect_to_release, id: 6 do |trn, name, _index|
    teacher(trn, name) do
      description("ECT with ongoing induction, ready to release")
      ect_at_school_period(abbey_grove_school, "2025-09-01") do
        training_period(ambition, 2025, "2025-09-01") do
          declaration("started",    "2025-09-15")
          declaration("retained-1", "2026-01-06")
        end
      end
      induction_period(golden_leaf_teaching_school_hub, "2025-09-01")
    end
  end

  scenario :ongoing_provider_led_ect_with_another_ab, id: 7 do |trn, name, _index|
    teacher(trn, name) do
      description("ECT with ongoing induction with another appropriate body, cannot be claimed")
      ect_at_school_period(abbey_grove_school, "2025-09-01") do
        training_period(teach_first, 2025, "2025-09-01") do
          declaration("started",    "2025-09-15")
          declaration("retained-1", "2026-01-06")
        end
      end
      induction_period(umber_teaching_school_hub, "2025-09-01")
    end
  end

  scenario :ect_who_has_passed_induction, id: 8 do |trn, name, _index|
    teacher(trn, name, trs_induction_status: "Passed") do
      # this might also need to be reflected in TRS query
      description("ECT who has passed induction, cannot be claimed")

      ect_at_school_period(ackley_bridge, "2023-09-01 -> 2025-07-30") do
        training_period(ambition, 2023, "2023-09-01 -> 2025-07-30") do
          declaration("started",    "2023-12-05", :paid)
          declaration("retained-1", "2024-03-10", :paid)
          declaration("retained-2", "2024-07-01", :paid)
          declaration("retained-3", "2024-12-20", :paid)
          declaration("retained-4", "2025-03-18", :paid)
          declaration("completed",  "2025-07-30", :no_payment)
        end
      end
      induction_period(umber_teaching_school_hub, "2023-09-01 -> 2025-05-20", :pass)
    end
  end

  scenario :ect_who_has_failed_induction, id: 9 do |trn, name, _index|
    teacher(trn, name, trs_induction_status: "Failed") do
      # this might also need to be reflected in TRS query
      description("ECT who has failed induction, cannot be claimed")

      ect_at_school_period(ackley_bridge, "2023-09-01") do
        training_period(ambition, 2023, "2023-09-01") do
          declaration("started",    "2023-12-05", :paid)
          declaration("retained-1", "2024-03-10", :paid)
          declaration("retained-2", "2024-07-01", :paid)
          declaration("retained-3", "2024-12-20", :paid)
        end
      end
      induction_period(umber_teaching_school_hub, "2023-09-01 -> 2025-05-20", :fail)
    end
  end

  scenario :ect_without_qts, id: 10 do |trn, name, _index|
    teacher(trn, name) do
      # no QTS will be checked from TRS query
      description("Teacher without QTS, cannot begin induction")
      ect_at_school_period(abbey_grove_school, "2026-09-01", school_reported_appropriate_body: golden_leaf_teaching_school_hub) do
        training_period(ambition, 2026, "2026-09-01")
      end
    end
  end

  scenario :ect_exempt_from_induction, id: 11 do |trn, name, _index|
    teacher(trn, name, trs_induction_status: "Exempt") do
      # exempt will be checked from TRS query
      description("Teacher exempt from induction, cannot begin induction")
      ect_at_school_period(abbey_grove_school, "2024-09-01", school_reported_appropriate_body: golden_leaf_teaching_school_hub) do
        school_led_training_period("2024-09-01")
      end
    end
  end

  scenario :ect_prohibited_from_teaching, id: 12 do |trn, name, _index|
    teacher(trn, name) do
      # prohibited checked from TRS query
      description("Teacher prohibited from teaching, cannot begin induction")
      ect_at_school_period(ashford_independent_school, "2025-09-01", school_reported_appropriate_body: golden_leaf_teaching_school_hub) do
        school_led_training_period("2025-09-01")
      end
    end
  end

  scenario :ect_ongoing_to_be_released_and_claimed, id: 13 do |trn, name, _index|
    teacher(trn, name) do
      description("ECT ongoing induction, to be released and claimed")
      ect_at_school_period(mallory_towers, "2025-09-01", school_reported_appropriate_body: golden_leaf_teaching_school_hub) do
        school_led_training_period("2025-09-01")
      end
      induction_period(golden_leaf_teaching_school_hub, "2025-09-01")
    end
  end

  client "ECT Manager", trn_prefix: "90" do
    oauth_client grant_type: :authorization_code

    seed :new_ect_provider_led_claim, count: 1
    seed :new_ect_school_led_claim, count: 1
    seed :released_ect_to_claim, count: 1
    seed :ongoing_provider_led_ect_to_pass, count: 1
    seed :ongoing_school_led_ect_to_pass, count: 1
    seed :ongoing_provider_led_ect_to_release, count: 1
    seed :ongoing_provider_led_ect_with_another_ab, count: 1
    seed :ect_who_has_passed_induction, count: 1
    seed :ect_who_has_failed_induction, count: 1
    seed :ect_without_qts, count: 1
    seed :ect_exempt_from_induction, count: 1
    seed :ect_prohibited_from_teaching, count: 1
    seed :ect_ongoing_to_be_released_and_claimed, count: 1
  end

  client "Mosaic", trn_prefix: "91" do
    oauth_client grant_type: :authorization_code

    seed :new_ect_provider_led_claim, count: 1
    seed :new_ect_school_led_claim, count: 1
    seed :released_ect_to_claim, count: 1
    seed :ongoing_provider_led_ect_to_pass, count: 1
    seed :ongoing_school_led_ect_to_pass, count: 1
    seed :ongoing_provider_led_ect_to_release, count: 1
    seed :ongoing_provider_led_ect_with_another_ab, count: 1
    seed :ect_who_has_passed_induction, count: 1
    seed :ect_who_has_failed_induction, count: 1
    seed :ect_without_qts, count: 1
    seed :ect_exempt_from_induction, count: 1
    seed :ect_prohibited_from_teaching, count: 1
    seed :ect_ongoing_to_be_released_and_claimed, count: 1
  end
end
