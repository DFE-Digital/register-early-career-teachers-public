def describe_appropriate_body(appropriate_body)
  print_seed_info(appropriate_body.name, indent: 2)
end

[
  {
    body_type: "teaching_school_hub",
    name: "Angel Oak Academy", # Used by developers for DfE Sign In
  },
  {
    body_type: "national",
    name: AppropriateBodies::Search::ISTIP,
    dfe_sign_in_organisation_id: "203606a4-4199-46a9-84e4-56fbc5da2a36",
    dqt_id: "6ae042bb-c7ae-e311-b8ed-005056822391"
  },
  {
    body_type: "teaching_school_hub",
    name: "Canvas Teaching School Hub",
  },
  {
    body_type: "teaching_school_hub",
    name: "South Yorkshire Studio Hub",
  },
  {
    body_type: "teaching_school_hub",
    name: "Ochre Education Partnership",
  },
  {
    body_type: "teaching_school_hub",
    name: "Umber Teaching School Hub",
    dfe_sign_in_organisation_id: "d245ec79-534e-4547-a7e4-ccd98803b627"
  },
  {
    body_type: "teaching_school_hub",
    name: "Golden Leaf Teaching School Hub",
  },
  {
    body_type: "teaching_school_hub",
    name: "Frame University London",
  },
  {
    body_type: "teaching_school_hub",
    name: "Easelcroft Teaching School Hub",
  },
  {
    body_type: "teaching_school_hub",
    name: "Vista College",
  }
].each do |describe_appropriate|
  FactoryBot.create(:appropriate_body, **describe_appropriate).tap do |appropriate_body|
    describe_appropriate_body(appropriate_body)
  end
end

# - local development environment uses the test UUID
# - staging environment uses the pre-prod UUID
test_uuid = "83173E6F-BA28-4654-A3DF-8279D573AB09"
pre_prod_uuid = "62FAFD5E-2C25-4214-91AD-1DE69262820A"
dfe_sign_in_organisation_id = Rails.env.development? ? test_uuid : pre_prod_uuid

AppropriateBody.find_by(name: "Angel Oak Academy").update!(dfe_sign_in_organisation_id:)
