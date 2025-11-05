# Entities seeded with dfe_sign_in params are real-world examples, and therefore
# we also seed other model records to reflect the relationships.
#
# Appropriate Bodies authenticate using a DfE Sign-In UUID unique to each ENV.
#
# TODO: remove regions from names if TSHs are consolidated in future
# ----------------------------------------------------------------------------
def describe_lead_school(school)
  school_urn = Colourize.text(school.urn, :yellow)
  print_seed_info("🏫 Lead school: #{school.name} (#{school_urn})", indent: 4)
end

def describe_appropriate_body(appropriate_body)
  type = Colourize.text(appropriate_body.body_type, :cyan)
  uuid = Colourize.text(appropriate_body.dfe_sign_in_organisation_id, :magenta)
  ab_text = "#{appropriate_body.name} (#{type}) #{uuid}"

  print_seed_info(ab_text, indent: 2)
  describe_lead_school(appropriate_body.lead_school) if appropriate_body.lead_school.present?
end

# DfE Sign-In environment domain prefix
def dfe_sign_in_env
  Rails.application.config.dfe_sign_in_issuer.include?("test") ? :test : :pp
end

appropriate_bodies = [
  # National Organisations
  # ----------------------------------------------------------------------------
  {
    name: NationalBody::ISTIP,
    body_type: "national",
    dqt_id: Faker::Internet.uuid,
    dfe_sign_in: {
      test: "e38652da-b01f-4d14-af2a-d2f55e4fcf7b",
      pp: "99424c22-b0c0-4307-bdf7-fabfe7cac252",
      # prod: "203606a4-4199-46a9-84e4-56fbc5da2a36"
    }
  },
  {
    name: NationalBody::ESP,
    body_type: "national",
    dqt_id: Faker::Internet.uuid,
    dfe_sign_in: {
      test: "722ebb41-42f6-4ba3-81b6-61af055246a5",
      pp: "b98cb613-192f-400e-9b50-fd7eea9882a1",
      # prod: "dbb5d311-3154-42c5-a8bb-183b39775da6"
    }
  },

  # Bright Futures Teaching School Hub (shared lead school)
  # ----------------------------------------------------------------------------
  {
    name: "Bright Futures Teaching School Hub (Salford & Trafford)",
    body_type: "teaching_school_hub",
    dqt_id: Faker::Internet.uuid,
    # region: "Salford, Trafford",
    lead_school: {
      urn: 137_289,
      name: "Altrincham Grammar School for Girls",
    },
    dfe_sign_in: {
      test: "ca3a5295-d180-4b80-8abc-4b05c5b19210",
      pp: "5942f0f9-a1ac-4e16-8ef8-2d5da63b075c",
      # prod: "c8350beb-f95a-4d03-b24e-3568d1760281"
    }
  },

  # Five Counties Teaching School Hub Alliance
  # ----------------------------------------------------------------------------
  {
    name: "Five Counties Teaching School Hubs Alliance (Somerset)",
    body_type: "teaching_school_hub",
    dqt_id: Faker::Internet.uuid,
    # region: "Somerset",
    lead_school: {
      urn: 135_959,
      name: "Bristol Metropolitan Academy",
    },
    dfe_sign_in: {
      test: "3f4e1f14-ac8c-48b0-a8b9-1c75b471bbcd",
      pp: "d0980f89-eda1-409d-bcd2-a88257ca7760",
      # prod: "1a18807c-2191-4230-9272-31e496f9013a"
    }
  },
  {
    name: "Five Counties Teaching School Hubs Alliance (South Glos/BANES)",
    body_type: "teaching_school_hub",
    dqt_id: Faker::Internet.uuid,
    # region: "Bath and North East Somerset, South Gloucestershire",
    lead_school: {
      urn: 149_948,
      name: "Mangotsfield Church of England Primary School",
    },
    dfe_sign_in: {
      test: "473f201b-9f2d-4648-bb9e-750c292bb072",
      pp: "f53af8e7-b303-4e8e-9374-3a18c083f271",
      # prod: "5ac51104-9a6e-4312-ad73-25769a8e801e"
    },
    urn: 149_948
  },

  # Star Teaching School Hub
  # ----------------------------------------------------------------------------
  {
    name: "Star Teaching School Hub Birmingham South",
    body_type: "teaching_school_hub",
    dqt_id: Faker::Internet.uuid,
    # region: "Birmingham South",
    lead_school: {
      urn: 141_969,
      name: "Eden Boys' School, Birmingham",
    },
    dfe_sign_in: {
      test: "2720e261-f131-4f55-b9d4-b6618a8633d3",
      pp: "49f7ccdb-b1a3-4154-851f-cd872f4b4bbe",
      # prod: "33867e30-4902-4854-97a0-f595f2998df1"
    },
  },
  {
    name: "Star Teaching School Hub Pennine Lancashire",
    body_type: "teaching_school_hub",
    dqt_id: Faker::Internet.uuid,
    # region: "Blackburn with Darwen, Burnley, Hyndburn, Pendle, Ribble Valley, Rossendale",
    lead_school: {
      urn: 140_959,
      name: "Eden Boys' School, Bolton",
    },
    dfe_sign_in: {
      test: "191c7072-bd72-4d1c-989f-3747c6d14eec",
      pp: "b6cac4aa-dba8-4e81-8bbc-6dcad47785c6",
      # prod: "218b2e2f-f869-43aa-a7a3-8bece4b2949b"
    },
  },

  # ----------------------------------------------------------------------------
  {
    name: "STEP Ahead Teaching School Hub",
    body_type: "teaching_school_hub",
    dqt_id: Faker::Internet.uuid,
    # region: "Brighton and Hove, Eastbourne, Hastings, Lewes, Rother, Wealden",
    lead_school: {
      urn: 141_666,
      name: "Angel Oak Academy",
    },
    dfe_sign_in: {
      test: "83173e6f-ba28-4654-a3df-8279d573ab09",
      pp: "62fafd5e-2c25-4214-91ad-1de69262820a",
      # prod: "7bb6e826-6322-4686-8775-3be78f980d70"
    },
  },

  # Fake Inactive Teaching School Hubs (imported)
  # ----------------------------------------------------------------------------
  {
    name: "Canvas Teaching School Hub",
    body_type: "teaching_school_hub",
    dqt_id: Faker::Internet.uuid,
  },
  {
    name: "South Yorkshire Studio Hub",
    body_type: "teaching_school_hub",
    dqt_id: Faker::Internet.uuid,
  },
  {
    name: "Ochre Education Partnership",
    body_type: "teaching_school_hub",
    dqt_id: Faker::Internet.uuid,
  },
  {
    name: "Umber Teaching School Hub",
    body_type: "teaching_school_hub",
    dqt_id: Faker::Internet.uuid,
  },
  {
    name: "Golden Leaf Teaching School Hub",
    body_type: "teaching_school_hub",
    dqt_id: Faker::Internet.uuid,
  },
  # Fake Inactive Teaching School Hubs (joined since launch)
  # ----------------------------------------------------------------------------
  {
    name: "Frame University London",
    body_type: "teaching_school_hub",
  },
  {
    name: "Easelcroft Teaching School Hub",
    body_type: "teaching_school_hub",
  },
  {
    name: "Vista College",
    body_type: "teaching_school_hub",
  },

  # Fake Local Authorities (imported)
  # ----------------------------------------------------------------------------
  {
    name: "Oldshire Local Authority",
    body_type: "local_authority",
    dqt_id: Faker::Internet.uuid,
  },
  {
    name: "Ancient County Council",
    body_type: "local_authority",
    dqt_id: Faker::Internet.uuid,
  }
]

appropriate_bodies.each do |data|
  name = data[:name]
  dqt_id = data[:dqt_id]
  body_type = data[:body_type]
  dfe_sign_in_organisation_id = data.dig(:dfe_sign_in, dfe_sign_in_env)

  appropriate_body_period = FactoryBot.create(:appropriate_body,
                                              name:,
                                              body_type:,
                                              dqt_id:,
                                              dfe_sign_in_organisation_id:)

  # Skip seeding new Appropriate Body models
  if ENV["SEED_NEW_APPROPRIATE_BODY_MODELS"] != "y"
    describe_appropriate_body(appropriate_body_period)
    next
  end

  # Legacy Appropriate Body
  if dfe_sign_in_organisation_id.present?
    FactoryBot.create(:legacy_appropriate_body,
                      appropriate_body_period:,
                      dqt_id:,
                      name:,
                      body_type:)
  end

  # Skip ABs who can't log in
  next if dfe_sign_in_organisation_id.blank?

  # Teaching School Hubs
  if appropriate_body_period.teaching_school_hub?
    school_name = data.dig(:lead_school, :name)
    urn = data.dig(:lead_school, :urn)
    # region = data[:region]

    # If the AB is a TSH there will be a school acting as its lead school
    gias_school = FactoryBot.create(:gias_school, :with_school, :eligible_type, :in_england,
                                    name: school_name,
                                    urn:)

    teaching_school_hub = FactoryBot.create(:teaching_school_hub,
                                            lead_school: gias_school.school,
                                            name:)

    appropriate_body_period.update!(
      lead_school: gias_school.school,
      teaching_school_hub:
    )

    # Delivery Partner role for TSH
    FactoryBot.create(:delivery_partner,
                      name:)
  end

  # National Bodies
  if appropriate_body_period.national?
    national_body = FactoryBot.create(:national_body, name:)
    appropriate_body_period.update!(national_body:)
  end

  describe_appropriate_body(appropriate_body_period)
end

# Seed Teaching School Hubs with multiple regions
# -----------------------------------------------------------------------------
if ENV["SEED_NEW_APPROPRIATE_BODY_MODELS"] == "y"
  print_seed_info("Teaching School Hubs", colour: :green, blank_lines_before: 1)
  type = Colourize.text("teaching_school_hub", :cyan)

  # Bright Futures' second region
  second_hub = FactoryBot.create(:teaching_school_hub,
                                 lead_school: School.find_by(urn: 137_289),
                                 name: "Bright Futures Teaching School Hub (Manchester & Stockport)")
  #  region: "Manchester, Stockport"

  print_seed_info("#{second_hub.name} (#{type})", indent: 2)
  describe_lead_school(second_hub.lead_school)
end
