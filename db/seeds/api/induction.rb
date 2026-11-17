@trns = (50_000..).to_enum

ambition = LeadProvider.find_by!(name: "Ambition Institute")
teach_first = LeadProvider.find_by!(name: "Teach First")

# Schools
abbey_grove_school = School.find_by!(urn: 1_759_427)
ackley_bridge = School.find_by!(urn: 3_375_958)
mallory_towers = School.find_by!(urn: 5_279_293)
brookfield_school = School.find_by!(urn: 2_976_163)
ashford_independent_school = School.find_by!(urn: 9_123_458)

# Appropriate bodies
south_yorkshire_studio_hub = AppropriateBodyPeriod.find_by!(name: "South Yorkshire Studio Hub")
golden_leaf_teaching_school_hub = AppropriateBodyPeriod.find_by!(name: "Golden Leaf Teaching School Hub")
umber_teaching_school_hub = AppropriateBodyPeriod.find_by!(name: "Umber Teaching School Hub")

def teacher(...) = TeacherHistories::TeacherBuilder.teacher(...)
def next_trn = (sprintf("%07d", @trns.next))

_nick_knox = teacher(next_trn, "Nick Knox") do
  description("New ECT for provider-led, ready to claim")
  ect_at_school_period(abbey_grove_school, "2026-09-01", school_reported_appropriate_body: golden_leaf_teaching_school_hub) do
    training_period(ambition, 2026, "2026-09-01")
  end
end

_keith_moon = teacher(next_trn, "Keith Moon") do
  description("New ECT for school-led, ready to claim")
  ect_at_school_period(ackley_bridge, "2026-09-01", school_reported_appropriate_body: golden_leaf_teaching_school_hub) do
    school_led_training_period("2026-09-01")
  end
end

_bill_ward = teacher(next_trn, "Bill Ward") do
  description("Previously released ECT, ready to claim")
  ect_at_school_period(ackley_bridge, "2025-09-01") do
    school_led_training_period("2025-09-01")
  end
  induction_period(south_yorkshire_studio_hub, "2025-09-01 -> 2026-01-01")
end

_mitch_mitchell = teacher(next_trn, "Mitch Mitchell") do
  description("ECT with ongoing provider-led training, ready to pass")
  ect_at_school_period(abbey_grove_school, "2024-09-01") do
    training_period(teach_first, 2024, "2024-09-01") do
      declaration("started",    "2024-09-15")
      declaration("retained-1", "2025-01-06")
    end
  end
  induction_period(golden_leaf_teaching_school_hub, "2024-09-01")
end

_phil_taylor = teacher(next_trn, "Phil Taylor") do
  description("ECT with ongoing school-led training, ready to pass")
  ect_at_school_period(brookfield_school, "2024-09-01") do
    school_led_training_period("2024-09-01")
  end
  induction_period(golden_leaf_teaching_school_hub, "2024-09-01")
end

_brian_downey = teacher(next_trn, "Brian Downey") do
  description("ECT with ongoing induction, ready to release")
  ect_at_school_period(abbey_grove_school, "2025-09-01") do
    training_period(ambition, 2025, "2025-09-01") do
      declaration("started",    "2025-09-15")
      declaration("retained-1", "2026-01-06")
    end
  end
  induction_period(golden_leaf_teaching_school_hub, "2025-09-01")
end

_stephen_morris = teacher(next_trn, "Stephen Morris") do
  description("ECT with ongoing induction with another appropriate body, cannot be claimed")
  ect_at_school_period(abbey_grove_school, "2025-09-01") do
    training_period(teach_first, 2025, "2025-09-01") do
      declaration("started",    "2025-09-15")
      declaration("retained-1", "2026-01-06")
    end
  end
  induction_period(umber_teaching_school_hub, "2025-09-01")
end

_joe_morello = teacher(next_trn, "Joe Morello", trs_induction_status: "Passed") do
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

_lars_ulrich = teacher(next_trn, "Lars Ulrich", trs_induction_status: "Failed") do
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

_stewart_copeland = teacher(next_trn, "Stewart Copeland") do
  # no QTS will be checked from TRS query
  description("Teacher without QTS, cannot begin induction")
  ect_at_school_period(abbey_grove_school, "2026-09-01", school_reported_appropriate_body: golden_leaf_teaching_school_hub) do
    training_period(ambition, 2026, "2026-09-01")
  end
end

_steve_jansen = teacher(next_trn, "Steve Jansen", trs_induction_status: "Exempt") do
  # exempt will be checked from TRS query
  description("Teacher exempt from induction, cannot begin induction")
  ect_at_school_period(abbey_grove_school, "2024-09-01", school_reported_appropriate_body: golden_leaf_teaching_school_hub) do
    school_led_training_period("2024-09-01")
  end
end

_john_bonham = teacher(next_trn, "John Bonham") do
  # prohibited checked from TRS query
  description("Teacher prohibited from teaching, cannot begin induction")
  ect_at_school_period(ashford_independent_school, "2025-09-01", school_reported_appropriate_body: golden_leaf_teaching_school_hub) do
    school_led_training_period("2025-09-01")
  end
end

_eloy_casagrande = teacher(next_trn, "Eloy Casagrande") do
  description("ECT ongoing induction, to be released and claimed")
  ect_at_school_period(mallory_towers, "2025-09-01", school_reported_appropriate_body: golden_leaf_teaching_school_hub) do
    school_led_training_period("2025-09-01")
  end
  induction_period(golden_leaf_teaching_school_hub, "2025-09-01")
end
