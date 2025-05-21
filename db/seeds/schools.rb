def describe_school(school)
  print_seed_info("#{school.name} (URN #{school.urn})", indent: 2)
end

school_data = [
  { urn: 3_375_958, name: "Ackley Bridge" },
  { urn: 1_759_427, name: "Abbey Grove School" },
  { urn: 2_472_261, name: "Grange Hill" },
  { urn: 3_583_173, name: "Coal Hill School" },
  { urn: 5_279_293, name: "Malory Towers" },
  { urn: 2_921_596, name: "St Clare's School" },
  { urn: 2_976_163, name: "Brookfield School" },
  { urn: 4_594_193, name: "Crunchem Hall Primary School" },
  { urn: 6_384_201, name: "Greyfriars School" }
]

school_data.map do |school_args|
  # FIXME: this is a bit nasty but gets the seeds working again
  GIAS::School.create!(school_args.merge(funding_eligibility: :eligible_for_fip,
                                         induction_eligibility: :eligible,
                                         local_authority_code: rand(20),
                                         establishment_number: school_args[:urn],
                                         type_name: school_args[:name] == 'Brookfield School' ? GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.sample : GIAS::Types::STATE_SCHOOL_TYPES.sample,
                                         in_england: true,
                                         section_41_approved: false))

  School.create!(school_args.except(:name)).tap { |school| describe_school(school) }
end
