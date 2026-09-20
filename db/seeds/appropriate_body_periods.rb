# Entities seeded with dfe_sign_in params are real-world examples, and therefore
# we also seed other model records to reflect the relationships.
#
# Appropriate Bodies authenticate using a DfE Sign-In UUID unique to each ENV.
# ----------------------------------------------------------------------------
def describe_lead_school(school)
  school_urn = Colourize.text(school.urn, :yellow)
  print_seed_info("🏫 Lead school: #{school.name} (#{school_urn})", indent: 4)
end

def describe_appropriate_body_period(appropriate_body_period)
  type = Colourize.text(appropriate_body_period.body_type, :cyan)
  uuid = Colourize.text(appropriate_body_period.dfe_sign_in_organisation_id, :magenta)
  ab_text = "#{appropriate_body_period.name} (#{type}) #{uuid}"

  # Teaching Schools & Teaching School Hubs
  print_seed_info(ab_text, indent: 2)
  describe_lead_school(appropriate_body_period.provisioning_school) if appropriate_body_period.provisioning_school.present?
end

# DfE Sign-In environment domain prefix
def dfe_sign_in_env
  Rails.application.config.dfe_sign_in_issuer.include?("test") ? :test : :pp
end

appropriate_body_periods = [
  # National Organisations
  # ----------------------------------------------------------------------------
  {
    name: AppropriateBody::ISTIP,
    body_type: "national",
    # started_on: Date.new(2011, 8, 31),
    # finished_on: nil,
    dfe_sign_in: {
      test: "e38652da-b01f-4d14-af2a-d2f55e4fcf7b",
      pp: "99424c22-b0c0-4307-bdf7-fabfe7cac252",
      # prod: "203606a4-4199-46a9-84e4-56fbc5da2a36"
    }
  },
  {
    name: AppropriateBody::ESP,
    body_type: "national",
    # started_on: Date.new(2024, 4, 1),
    # finished_on: nil,
    dfe_sign_in: {
      test: "722ebb41-42f6-4ba3-81b6-61af055246a5",
      pp: "b98cb613-192f-400e-9b50-fd7eea9882a1",
      # prod: "dbb5d311-3154-42c5-a8bb-183b39775da6"
    }
  },
  {
    name: "National Teacher Accreditation", # formerly NIPT
    body_type: "national",
    # started_on: Date.new(2013, 8, 31),
    # finished_on: Date.new(2024, 9, 1),
    dfe_sign_in: nil
  },

  # Bright Futures Teaching School Hub
  # ----------------------------------------------------------------------------
  {
    name: "Bright Futures Teaching School Hub (Salford & Trafford)",
    tsh_name: "Bright Futures TSH",
    body_type: "teaching_school_hub",
    regions: [
      {
        urn: 137_289,
        code: "NW7",
        districts: "Manchester, Stockport",
      },
      {
        urn: 137_289,
        code: "NW9",
        districts: "Salford, Trafford",
      },
    ],
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
    tsh_name: "Five Counties TSH",
    body_type: "teaching_school_hub",
    regions: [
      {
        urn: 135_959,
        code: "SW5",
        districts: "Somerset",
      },
      {
        urn: 135_959,
        code: "SW9",
        districts: "Bristol, North Somerset",
      },
    ],
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
    tsh_name: "Five Counties TSH",
    body_type: "teaching_school_hub",
    regions: [
      {
        urn: 149_948,
        code: "SW6",
        districts: "Bath and North East Somerset, South Gloucestershire",
      }
    ],
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
    tsh_name: "Star TSH",
    body_type: "teaching_school_hub",
    regions: [
      {
        urn: 141_969,
        code: "WM10",
        districts: "Birmingham South",
      }
    ],
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
    tsh_name: "Star TSH",
    body_type: "teaching_school_hub",
    regions: [
      # Eden Boys' (provisioning lead school)
      {
        urn: 140_959,
        code: "NW3",
        districts: "Bolton, Bury, Rochdale",
      },
      # Tauheedul Boys'
      {
        urn: 138_220,
        code: "NW4",
        districts: "Blackpool, Preston, Lancaster, Wyre",
      },
      # Tauheedul Girls'
      {
        urn: 141_565,
        code: "NW5",
        districts: "Hyndburn, Burnley, Pendle, Blackburn with Darwen, Ribble Valley, Rossendale",
      },
    ],
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
    tsh_name: "STEP Ahead TSH",
    body_type: "teaching_school_hub",
    regions: [
      # {
      #   urn: 141_666,
      #   code: "WM2",
      #   districts: "Telford and Wrekin, Shropshire",
      # }
      {
        urn: 141_666,
        code: "SE1",
        districts: "Wealden, Lewes, Brighton and Hove, Rother, Hastings, Eastbourne",
      },
    ],
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

  # Kent Teaching School Hub
  # ----------------------------------------------------------------------------
  {
    name: "Kent Teaching School Hub",
    tsh_name: "Kent TSH",
    body_type: "teaching_school_hub",
    regions: [
      {
        urn: 136_603,
        code: "SE2",
        districts: "Ashford, Canterbury, Dover, Folkestone and Hythe, Swale, Thanet",
      },
      {
        urn: 136_603,
        code: "SE8",
        districts: "Sevenoaks, Tunbridge Wells, Tonbridge and Malling, Maidstone",
      },
    ],
    lead_school: {
      urn: 136_603,
      name: "Bennett Memorial Diocesan School",
    },
  },

  # Unity Teaching School Hub
  # ----------------------------------------------------------------------------
  {
    name: "Unity Teaching School Hub",
    tsh_name: "Unity TSH",
    body_type: "teaching_school_hub",
    regions: [
      {
        urn: 139_732,
        code: "EE2",
        districts: "Colchester, Tendring, Ipswich, Babergh",
      },
      {
        urn: 139_732,
        code: "EE6",
        districts: "East Suffolk S., Mid Suffolk, West Suffolk",
      },
    ],
    lead_school: {
      urn: 139_732,
      name: "Churchill Special Free School",
    },
  },

  # Chiltern Teaching School Hub
  # ----------------------------------------------------------------------------
  {
    name: "Chiltern Teaching School Hub",
    tsh_name: "Chiltern TSH",
    body_type: "teaching_school_hub",
    regions: [
      {
        urn: 136_319,
        code: "EE8",
        districts: "Luton, North Hertfordshire, Broxbourne, Stevenage, East Hertfordshire",
      },
      {
        urn: 136_319,
        code: "EE9",
        districts: "Bedford, Central Bedfordshire, Milton Keynes",
      },
    ],
    lead_school: {
      urn: 136_319,
      name: "Denbigh High School",
    },
  },

  # Fake Inactive Teaching School Hubs (imported)
  # ----------------------------------------------------------------------------
  {
    name: "Canvas Teaching School Hub",
    body_type: "teaching_school_hub",
  },
  {
    name: "South Yorkshire Studio Hub",
    body_type: "teaching_school_hub",
  },
  {
    name: "Ochre Education Partnership",
    body_type: "teaching_school_hub",
  },
  {
    name: "Umber Teaching School Hub",
    body_type: "teaching_school_hub",
    regions: [
      {
        urn: 141_777,
        code: "EE7",
        districts: "St Albans, Welwyn Hatfield, Dacorum, Watford, Three Rivers, Hertsmere",
      }
    ],
    lead_school: {
      urn: 141_777,
      name: "Umber LS",
    },
  },
  {
    name: "Golden Leaf Teaching School Hub",
    body_type: "teaching_school_hub",
    regions: [
      {
        urn: 141_888,
        code: "YH9",
        districts: "Leeds",
      }
    ],
    lead_school: {
      urn: 141_888,
      name: "Golden Leaf LS",
    },
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
  },
  {
    name: "Ancient County Council",
    body_type: "local_authority",
  }
]

appropriate_body_periods.each do |data|
  ab_name = data[:name]
  body_type = data[:body_type]
  dfe_sign_in_organisation_id = data.dig(:dfe_sign_in, dfe_sign_in_env)

  appropriate_body_period = FactoryBot.build(:appropriate_body_period,
                                             name: ab_name,
                                             body_type:,
                                             dfe_sign_in_organisation_id:)

  # 1. Local Authorities
  if body_type == "local_authority"
    local_authority = FactoryBot.create(:local_authority,
                                        name: ab_name)

    appropriate_body_period.update!(
      local_authority:
      # started_on: Date.new(2012, 8, 31),
      # finished_on: Date.new(2023, 9, 1)
    )

  end

  # 2. Teaching School Hubs with Lead schools
  if body_type == "teaching_school_hub"
    tsh_name = data[:tsh_name] || data[:name]
    school_name = data.dig(:lead_school, :name)
    urn = data.dig(:lead_school, :urn)
    regions = data[:regions]

    teaching_school_hub = FactoryBot.create(:teaching_school_hub,
                                            name: tsh_name)

    # Link hubs to body
    appropriate_body_period.update!(
      teaching_school_hub:
      # started_on: Date.new(2021, 9, 1),
      # finished_on: nil
    )

    # If the seed has a school we can link further
    if urn.present?
      gias_school = FactoryBot.create(:gias_school, :eligible_type, :in_england,
                                      urn:,
                                      name: school_name)

      provisioning_school = FactoryBot.create(:school, :eligible, :with_dsi,
                                              urn:,
                                              gias_school:)

      # Link hubs to lead schools through the body pairing
      # Any seeds above without a URN will not have a lead school
      appropriate_body_period.update!(provisioning_school:)

      # Before 2021 when the same school was called a "Teaching School"
      # Backdated second closed ABP for Teaching School i.e. no TSH link
      FactoryBot.create(:appropriate_body_period,
                        name: ab_name + " (closed)",      # idempotent factory needs different name
                        body_type:,                       # this would be "school" if we updated the enum
                        # dfe_sign_in_organisation_id:,     # unique constraint prevents this for now
                        # started_on: Date.new(1999, 9, 1),
                        # finished_on: Date.new(2021, 8, 31)
                        provisioning_school:,
                        teaching_school_hub: nil)

      # Create regions and assign lead schools for an AB
      Array(regions).each do |region_data|
        region = FactoryBot.create(:region,
                                   code: region_data[:code],
                                   districts: region_data[:districts].split(", "))

        lead_school = FactoryBot.create(:school, :eligible,
                                        urn: region_data[:urn])

        FactoryBot.create(:teaching_school_hub_lead_school,
                          region:,
                          school: lead_school,
                          appropriate_body: appropriate_body_period)

        # Populate GIAS regional data
        lead_school.gias_school.update!(administrative_district_name: region.districts.sample)
      end

    end
  end

  # 3. National Bodies
  if appropriate_body_period.national?
    national_body = FactoryBot.create(:national_body,
                                      name: ab_name)

    appropriate_body_period.update!(
      national_body:
      # started_on: data[:started_on],
      # finished_on: data[:finished_on]
    )
  end

  describe_appropriate_body_period(appropriate_body_period)
end
