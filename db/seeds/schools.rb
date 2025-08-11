def describe_school(school)
  print_seed_info("#{school.name} (URN #{school.urn})", indent: 2)
end

school_types = {
  independent: GIAS::Types::INDEPENDENT_SCHOOLS_TYPES,
  state: GIAS::Types::STATE_SCHOOL_TYPES
}

[
  {
    urn: 3_375_958,
    name: "Ackley Bridge",
    school_type: :state,
    induction_tutor_email: "Monique.Friesen@example.com",
    induction_tutor_name: "Monique Friesen"
  },
  {
    urn: 1_759_427,
    name: "Abbey Grove School",
    school_type: :state
  },
  {
    urn: 2_472_261,
    name: "Grange Hill",
    school_type: :state
  },
  {
    urn: 3_583_173,
    name: "Coal Hill School",
    school_type: :state,
    induction_tutor_email: "Carmelina.Hegmann@example.com",
    induction_tutor_name: "Carmelina Hegmann"
  },
  {
    urn: 5_279_293,
    name: "Malory Towers",
    school_type: :state
  },
  {
    urn: 2_921_596,
    name: "St Clare's School",
    school_type: :state
  },
  {
    urn: 2_976_163,
    name: "Brookfield School",
    school_type: :independent,
    induction_tutor_email: "Percy.Konopelski@example.com",
    induction_tutor_name: "Percy Konopelski"
  },
  {
    urn: 4_594_193,
    name: "Crunchem Hall Primary School",
    school_type: :state
  },
  {
    urn: 6_384_201,
    name: "Greyfriars School",
    school_type: :state
  }
].map do |data|
  # FIXME: this is a bit nasty but gets the seeds working again
  GIAS::School.create!(data.merge(
    funding_eligibility: :eligible_for_fip,
    induction_eligibility: :eligible,
    local_authority_code: rand(20),
    establishment_number: data[:urn],
    type_name: school_types.fetch(data.delete(:school_type)).sample,
    in_england: true,
    section_41_approved: false
  ).except(
    :induction_tutor_name,
    :induction_tutor_email
  ))

  School.create!(data.except(:name)).tap { |school| describe_school(school) }
end
