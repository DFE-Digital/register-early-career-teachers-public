def describe_appropriate_body(appropriate_body)
  print_seed_info(appropriate_body.name, indent: 2)
end

AppropriateBody.create!([
  {
    body_type: 'national',
    name: AppropriateBodies::Search::ISTIP,
    local_authority_code: 50,
    dfe_sign_in_organisation_id: "203606a4-4199-46a9-84e4-56fbc5da2a36",
    dqt_id: "6ae042bb-c7ae-e311-b8ed-005056822391"
  },
  {
    body_type: 'teaching_school_hub',
    name: 'Canvas Teaching School Hub',
    local_authority_code: 109,
    establishment_number: 2367
  },
  {
    body_type: 'teaching_school_hub',
    name: 'South Yorkshire Studio Hub',
    local_authority_code: 678,
    establishment_number: 9728
  },
  {
    body_type: 'teaching_school_hub',
    name: 'Ochre Education Partnership',
    local_authority_code: 238,
    establishment_number: 6582
  },
  {
    body_type: 'teaching_school_hub',
    name: 'Umber Teaching School Hub',
    local_authority_code: 957,
    establishment_number: 7361,
    dfe_sign_in_organisation_id: 'd245ec79-534e-4547-a7e4-ccd98803b627'
  },
  {
    body_type: 'teaching_school_hub',
    name: 'Golden Leaf Teaching School Hub',
    local_authority_code: 648,
    establishment_number: 3986
  },
  {
    body_type: 'teaching_school_hub',
    name: 'Frame University London',
    local_authority_code: 832,
    establishment_number: 6864
  },
  {
    body_type: 'teaching_school_hub',
    name: 'Easelcroft Teaching School Hub',
    local_authority_code: 573,
    establishment_number: 9273
  },
  {
    body_type: 'teaching_school_hub',
    name: 'Vista College',
    local_authority_code: 418,
    establishment_number: 3735
  }
]).each do |describe_appropriate|
  describe_appropriate_body(describe_appropriate)
end
