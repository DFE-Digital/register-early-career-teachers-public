def describe_school(school)
  school_urn = Colourize.text(school.urn, :yellow)
  print_seed_info("#{school.name} (#{school_urn})", indent: 2)
end

opened_on = Date.parse("1999-09-01")

[
  {
    urn: 3_375_958,
    name: "Ackley Bridge",
    type: :state_school_type,
    induction_tutor_email: "Monique.Friesen@example.com",
    induction_tutor_name: "Monique Friesen"
  },
  {
    urn: 1_759_427,
    name: "Abbey Grove School",
    type: :state_school_type,
    sparsity_uplift: true,
    pupil_premium_uplift: true,
  },
  {
    urn: 2_472_261,
    name: "Grange Hill",
    type: :state_school_type
  },
  {
    urn: 3_583_173,
    name: "Coal Hill School",
    type: :state_school_type,
    induction_tutor_email: "Carmelina.Hegmann@example.com",
    induction_tutor_name: "Carmelina Hegmann"
  },
  {
    urn: 5_279_293,
    name: "Malory Towers",
    type: :state_school_type,
    sparsity_uplift: true,
    pupil_premium_uplift: true,
  },
  {
    urn: 2_921_596,
    name: "St Clare's School",
    type: :state_school_type
  },
  {
    urn: 2_976_163,
    name: "Brookfield School",
    type: :independent_school_type,
    section_41_approved: true,
    induction_tutor_email: "Percy.Konopelski@example.com",
    induction_tutor_name: "Percy Konopelski"
  },
  {
    urn: 9_123_457,
    name: "Abbeymead Independent School",
    type: :independent_school_type,
    section_41_approved: false
  },
  {
    urn: 9_123_458,
    name: "Ashford Independent School",
    type: :independent_school_type,
    section_41_approved: false
  },
  {
    urn: 4_594_193,
    name: "Crunchem Hall Primary School",
    type: :state_school_type
  },
  {
    urn: 6_384_201,
    name: "Greyfriars School",
    type: :state_school_type,
    induction_tutor_email: nil,
    induction_tutor_name: nil,
    induction_tutor_last_nominated_in: nil,
  },

  # Appropriate body teaching school hub provisioning schools
  # ----------------------------------------------------------------------------
  # Star Teaching School Hub Network
  { urn: 141_969, name: "Eden Boys' School, Birmingham", type: :state_school_type, opened_on: },      # Star Teaching School Hub Birmingham South
  { urn: 138_220, name: "Tauheedul Islam Boys' High School", type: :state_school_type, opened_on: },  # Star Teaching School Hub Pennine Lancashire
  { urn: 140_959, name: "Eden Boys' School, Bolton", type: :state_school_type, opened_on: },          # Star Teaching School Hub Pennine Lancashire
  { urn: 141_565, name: "Tauheedul Islam Girls' High School", type: :state_school_type, opened_on: }, # Star Teaching School Hub Pennine Lancashire
  # Exchange Teaching School Hub
  { urn: 138_332, name: "The Vale Primary Academy", type: :state_school_type, opened_on: },
  { urn: 137_482, name: "Grange Lane Infant Academy", type: :state_school_type, opened_on: },
  # Five Counties Teaching School Hub Alliance
  { urn: 135_959, name: "Bristol Metropolitan Academy", type: :state_school_type, opened_on: },                  # Five Counties Teaching School Hubs Alliance (Somerset)
  { urn: 149_948, name: "Mangotsfield Church of England Primary School", type: :state_school_type, opened_on: }, # Five Counties Teaching School Hubs Alliance (South Glos/BANES)
  # Chiltern TSH
  { urn: 136_319, name: "Denbigh High School", type: :state_school_type, opened_on: },
  # Kent Teaching School Hub
  { urn: 136_603, name: "Bennett Memorial Diocesan School", type: :state_school_type, opened_on: },
  # Bright Futures Teaching School Hub
  { urn: 137_289, name: "Altrincham Grammar School for Girls", type: :state_school_type, opened_on: },
  # Unity Teaching School Hub
  { urn: 139_732, name: "Churchill Special Free School", type: :state_school_type, opened_on: },
  # STEP Ahead Teaching School Hub
  { urn: 141_666, name: "Angel Oak Academy", type: :state_school_type, opened_on: },
  # Embrace Teaching School Hub
  { urn: 143_879, name: "Tor View School", type: :state_school_type, opened_on: },

  # Mock hubs ------------------------------------------------------------------

  # Canvas Teaching School Hub
  { urn: 9_400_101, name: "Canvas Academy", type: :state_school_type, opened_on: },
  # South Yorkshire Studio Hub
  { urn: 9_400_102, name: "Dearne Valley Studio School", type: :state_school_type, opened_on:, closed_on: Date.parse("2024-08-31") },
  # Ochre Education Partnership
  { urn: 9_400_103, name: "Ochre Academy", type: :state_school_type, opened_on: },           # Ochre Education Partnership (Winterfell)
  { urn: 9_400_104, name: "Ochre Learning Alliance", type: :state_school_type, opened_on: }, # Ochre Education Partnership (Dragonstone)

  # Personas --------------------------------------------------------------------
  # Fred Jones @ Umber Teaching School Hub
  { urn: 141_777, name: "Umber LS", type: :state_school_type, opened_on: },
  # Velma Dinkley @ Golden Leaf Teaching School Hub
  { urn: 141_888, name: "Golden Leaf LS", type: :state_school_type, opened_on: },

  # Appropriate body teaching schools
  # ----------------------------------------------------------------------------
  { urn: 9_400_001, name: "Frame University London", type: :state_school_type, opened_on:, closed_on: Date.parse("2021-08-31") },
  { urn: 9_400_002, name: "Easelcroft Teaching School", type: :state_school_type, opened_on:, closed_on: Date.parse("2021-08-31") },
  { urn: 9_400_003, name: "Vista College", type: :state_school_type, opened_on:, closed_on: Date.parse("2022-08-31") },
  { urn: 9_400_004, name: "St Mary's School", type: :state_school_type, opened_on: Date.parse("2017-09-01"), closed_on: Date.parse("2021-08-31") },

].uniq { |h| h[:urn] }.map do |data|
  type = data[:type]

  # If a School with this URN already exists (e.g. created by earlier seed files),
  # reuse it rather than trying to create again
  school = School.find_by(urn: data[:urn])

  school ||= FactoryBot.create(
    :gias_school,
    :with_school,
    :eligible_type,
    :in_england,
    type,
    **data.merge(
      establishment_number: data[:urn],
      section_41_approved: data.fetch(:section_41_approved, false)
    ).except(
      :induction_tutor_name,
      :induction_tutor_email,
      :induction_tutor_last_nominated_in,
      :section_41_approved,
      :type,
      :sparsity_uplift,
      :pupil_premium_uplift
    )
  ).school

  # Update School-specific attributes separately
  school.update!(**data.except(:name, :type, :opened_on, :closed_on, :section_41_approved, :sparsity_uplift, :pupil_premium_uplift))

  if data.key?(:section_41_approved)
    school.gias_school&.update!(section_41_approved: data[:section_41_approved])
  end

  if data.key?(:sparsity_uplift) && data.key?(:pupil_premium_uplift)
    ContractPeriod.find_each do |contract_period|
      FactoryBot.create(:school_funding_eligibility,
                        sparsity_uplift: contract_period.uplift_fees_enabled? ? data[:sparsity_uplift] : false,
                        pupil_premium_uplift: contract_period.uplift_fees_enabled? ? data[:pupil_premium_uplift] : false,
                        contract_period:,
                        gias_school: school.gias_school)
    end
  end

  describe_school(school)
  school
end
