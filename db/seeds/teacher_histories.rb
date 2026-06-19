@trns = (1..).to_enum

ambition = LeadProvider.find_by!(name: "Ambition Institute")
teach_first = LeadProvider.find_by!(name: "Teach First")
capita = LeadProvider.find_by!(name: "Capita")

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

_caroline_quentin = teacher(next_trn, "Caroline Quentin") do
  induction_period(south_yorkshire_studio_hub, "2024-09-05")

  ect_at_school_period(ashford_independent_school, "2024-09-01") do
    school_led_training_period("2024-09-01")
  end
end

_emma_thompson = teacher(next_trn, "Emma Thompson", trs_induction_status: "InProgress") do
  mentor_at_school_period(abbey_grove_school, "2022-09-01")
end

felicity_kendall = teacher(next_trn, "Felicity Kendall") do
  induction_period(golden_leaf_teaching_school_hub, "2023-08-28")

  mentor_at_school_period(abbey_grove_school, "2023-09-01 -> 2025-05-05") do
    training_period(ambition, 2023, "2023-09-01 -> 2024-11-20") do
      declaration("started",    "2023-09-15")
      declaration("retained-1", "2024-01-06")
    end
  end
end

hugh_grant = teacher(next_trn, "Hugh Grant") do
  description("Mentor at 3 schools")
  mentor_at_school_period(abbey_grove_school, "2023-09-01")
  mentor_at_school_period(ashford_independent_school, "2022-09-01")
  mentor_at_school_period(brookfield_school, "2022-09-01")
end

_kate_winslet = teacher(next_trn, "Kate Winslet") do
  description("ECT induction complete")

  induction_period(golden_leaf_teaching_school_hub, "2023-08-28 -> 2025-10-28", :pass)

  ect_at_school_period(abbey_grove_school, "2023-09-01") do
    training_period(ambition, 2023, "2023-09-01 -> 2025-08-01") do
      declaration("started",    "2023-12-05", :paid)
      declaration("retained-1", "2024-03-10", :paid)
      declaration("retained-2", "2024-07-01", :paid)
      declaration("retained-3", "2024-12-20", :paid)
      declaration("retained-4", "2025-03-18", :payable)
      declaration("completed",  "2025-07-30", :no_payment)
    end

    mentorship_period(felicity_kendall, "2023-09-01 -> 2025-05-05")
    mentorship_period(hugh_grant, "2025-05-06 -> 2025-07-30")
  end
end

_alan_rickman = teacher(next_trn, "Alan Rickman") do
  induction_period(umber_teaching_school_hub, "2022-09-05 -> 2024-03-30")
  induction_period(golden_leaf_teaching_school_hub, "2024-12-10")

  ect_at_school_period(abbey_grove_school, "2022-09-05") do
    training_period(ambition, 2022, "2022-09-05 -> 2023-05-05") do
      declaration("started", "2022-12-05")
    end

    training_period(ambition, 2022, "2023-06-06 -> 2024-05-05") do
      declaration("retained-1", "2023-03-05")
      declaration("retained-2", "2023-06-01")
    end

    mentorship_period(felicity_kendall, "2023-09-01 -> 2024-05-05")
  end
end

_dominic_west = teacher(next_trn, "Dominic West") do
  description "completed mentor training"

  mentor_at_school_period(mallory_towers, "2022-09-01 -> 2025-07-24") do
    training_period(teach_first, 2022, "2022-09-01 -> 2025-01-17") do
      declaration("started",    "2022-09-15", :paid)
      declaration("retained-1", "2023-03-16", :paid)
      declaration("retained-2", "2023-07-05", :clawed_back)
      declaration("retained-2", "2023-07-08", :paid)
      declaration("retained-3", "2023-12-05", :paid)
      declaration("retained-4", "2024-01-20", :no_payment)
      declaration("completed",  "2024-05-14", :no_payment)
    end
  end
end

_anthony_hopkins = teacher(next_trn, "Anthony Hopkins") do
  induction_period(golden_leaf_teaching_school_hub, "2023-10-05")

  ect_at_school_period(abbey_grove_school, "2023-09-01") do
    training_period(ambition, 2023, "2023-09-01 -> 2024-07-30") do
      declaration("started",    "2023-12-05")
      declaration("retained-1", "2024-03-10")
      declaration("retained-2", "2024-07-01")
    end

    mentorship_period(felicity_kendall, "2023-09-01 -> 2024-07-30")
    mentorship_period(hugh_grant, "2024-07-31")
  end
end

_harriet_walter = teacher(next_trn, "Harriet Walter") do
  induction_period(south_yorkshire_studio_hub, "2022-09-24 -> 2025-04-23")
  induction_period(golden_leaf_teaching_school_hub, "2025-05-18")

  ect_at_school_period(brookfield_school, "2022-09-04") do
    training_period(teach_first, 2022, "2022-09-04") do
      # shorthand way of creating multiple declarations that are submitted 0..60 days before the milestone_date
      declarations(%w[started retained-1 retained-2 retained-3])
    end

    mentorship_period(hugh_grant, "2022-10-31")
  end
end

_hugh_laurie = teacher(next_trn, "Hugh Laurie") do
  induction_period(umber_teaching_school_hub, "2023-01-30")

  ect_at_school_period(brookfield_school, "2022-09-04") do
    training_period(teach_first, 2022, "2022-09-04") do
      # another shorthand way of creating multiple declarations, this time specifying the traits
      declarations({ "started" => :paid, "retained-1" => :paid, "retained-2" => :paid, "retained-3" => :paid, "retained-4" => :payable })
    end

    mentorship_period(hugh_grant, "2022-11-02")
  end
end

_alastair_sim = teacher(next_trn, "Alastair Sim") do
  induction_period(umber_teaching_school_hub, "2023-09-05")

  ect_at_school_period(ackley_bridge, "2023-09-01 -> 2025-06-01") do
    training_period(ambition, 2023, "2023-09-01 -> 2025-06-01") do
      declarations(%w[started retained-1 retained-2 retained-3 retained-4 completed])
    end
  end

  mentor_at_school_period(ackley_bridge, "2025-09-01")
end

_imogen_stubbs = teacher(next_trn, "Imogen Stubbs") do
  description("Changed lead provider")

  induction_period(golden_leaf_teaching_school_hub, "2022-09-24")

  ect_at_school_period(brookfield_school, "2022-09-04") do
    training_period(teach_first, 2022, "2022-09-04 -> 2023-04-08") do
      declarations(%w[started retained-1 retained-2])
    end

    training_period(capita, 2022, "2023-04-09") do
      declarations(%w[retained-3 retained-4])
    end

    mentorship_period(hugh_grant, "2022-11-02 -> 2023-04-08")
    mentorship_period(hugh_grant, "2023-04-09")
  end
end

chiwetel_ejiofor = teacher(next_trn, "Chiwetel Ejiofor") do
  mentor_at_school_period(brookfield_school, "2022-05-28")
end

_alexandar_siddig = teacher(next_trn, "Alexander Siddig") do
  ect_at_school_period(brookfield_school, "2024-09-01") do
    training_period(teach_first, 2024, "2024-09-01") do
      declarations(%w[started retained-1 retained-2 retained-4 retained-5])
    end

    mentorship_period(chiwetel_ejiofor, "2024-09-01")
  end
end

_freya_allan = teacher(next_trn, "Freya Allan") do
  ect_at_school_period(brookfield_school, "2024-09-01") do
    training_period(:auto, 2024, "2024-09-01") do
      declarations(%w[started retained-1 retained-2])
    end

    mentorship_period(chiwetel_ejiofor, "2024-11-24")
  end
end

_kelly_macdonald = teacher(next_trn, "Kelly Macdonald") do
  induction_period(golden_leaf_teaching_school_hub, "2023-08-28")

  ect_at_school_period(abbey_grove_school, "2023-09-01 -> 2026-01-08") do
    school_led_training_period("2023-09-01 -> 2026-01-08")
  end
end

_matthew_goode = teacher(next_trn, "Matthew Goode") do
  description("Expression of interest with teach first")

  ect_at_school_period(mallory_towers, "2025-09-01") do
    training_period(teach_first, 2025, "2025-09-01")
  end
end
