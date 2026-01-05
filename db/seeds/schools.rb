def describe_school(school)
  print_seed_info("#{school.name} (URN #{school.urn})", indent: 2)
end

[
  {
    urn: 141_666,
    name: "Angel Oak Academy", # Used by developers for DfE Sign In
    type: :state_school_type
  },
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
    type: :state_school_type
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
    type: :state_school_type
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
    induction_tutor_email: "Percy.Konopelski@example.com",
    induction_tutor_name: "Percy Konopelski"
  },
  {
    urn: 4_594_193,
    name: "Crunchem Hall Primary School",
    type: :state_school_type
  },
  {
    urn: 6_384_201,
    name: "Greyfriars School",
    type: :state_school_type
  }
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
      section_41_approved: false
    ).except(
      :induction_tutor_name,
      :induction_tutor_email,
      :type
    )
  ).school

  # Update School-specific attributes separately
  school.update!(**data.except(:name, :type))

  describe_school(school)
  school
end
