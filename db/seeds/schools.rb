def describe_school(school)
  print_seed_info("#{school.name} (URN #{school.urn})", indent: 2)
end

[
  {
    urn: 141_666,
    name: 'Angel Oak Academy', # Used by developers for DfE Sign In
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
].map do |data|
  FactoryBot.create(
    :gias_school,
    :with_school,
    :eligible_type,
    :in_england,
    data.delete(:type),
    **data.merge(
      establishment_number: data[:urn],
      section_41_approved: false
    ).except(
      :induction_tutor_name,
      :induction_tutor_email
    )
  ).school.tap do |s|
    s.update!(**data.except(:name))
    describe_school(s)
  end
end
