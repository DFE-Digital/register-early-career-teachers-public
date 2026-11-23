# Appropriate bodies
# ----------------------------------------------------------------------------
#
# - Four body types exist with different rules for each.
# - Periods for TSs and LAs are all closed.
# - Periods for NBs and TSHs can be open, but some are closed.
# - DfE Sign-in is possible as NB or TSH using accounts approved at select organisations.
#
def national_body(name, **) = AppropriateBody::Builder.national_body(name, **)
def teaching_school_hub(name, **) = AppropriateBody::Builder.teaching_school_hub(name, **)
def local_authority(name, **) = AppropriateBody::Builder.local_authority(name, **)
def teaching_school(name, **) = AppropriateBody::Builder.teaching_school(name, **)

# @param abp [AppropriateBodyPeriod]
def describe_appropriate_body_period(abp)
  icons = { national: "🏛️", teaching_school_hub: "🏫", teaching_school: "🎓", local_authority: "🏢" }
  range = abp.finished_on ? "#{abp.started_on} → #{abp.finished_on}" : "#{abp.started_on} → now"
  sign_in = abp.dfe_sign_in_organisation_id.present? ? "🔑" : ""
  icon = icons.fetch(abp.body_type.to_sym)
  print_seed_info("#{icon} #{abp.display_name} #{Colourize.text("(#{range})", :cyan)} #{sign_in}")
end

# Local authorities (until 2024)
# ----------------------------------------------------------------------------
print_seed_info("🏢 Local authorities", colour: :yellow)

oldshire_local_authority = local_authority("Oldshire Local Authority")
oldshire_local_authority.period("1999-09-01 -> 2024-08-31")

ancient_county_council = local_authority("Ancient County Council")
ancient_county_council.period("1999-09-01 -> 2024-08-31")

# Teaching schools (until 2021)
# ----------------------------------------------------------------------------
print_seed_info("🎓 Teaching schools", colour: :yellow)

frame_university_london = teaching_school("Frame University London")
frame_university_london.period("1999-09-01 -> 2021-08-31")

easelcroft_teaching_school = teaching_school("Easelcroft Teaching School")
easelcroft_teaching_school.period("1999-09-01 -> 2021-08-31")

vista_college = teaching_school("Vista College")
vista_college.period("1999-09-01 -> 2021-08-31")

# St Mary's School did not open until 2017 but we permit a TS ABP to have an
# earlier start date to accommodate legacy data. In production using migrated data
# the exact school was not known so an ABP was created using the school at the TS->TSH boundary.
# This is an acceptable compromise.
st_marys_port_out = teaching_school("St Mary's School")
st_marys_port_out.period("2015-09-01 -> 2021-08-31")

# National bodies
# ----------------------------------------------------------------------------
print_seed_info("🏛️ National bodies", colour: :yellow)

istip = national_body(NationalBody::ISTIP)
istip.period(
  "2011-08-31 ->",
  dfe_sign_in: {
    test: "e38652da-b01f-4d14-af2a-d2f55e4fcf7b",
    pp: "99424c22-b0c0-4307-bdf7-fabfe7cac252"
    # prod: "203606a4-4199-46a9-84e4-56fbc5da2a36"
  }
)

esp = national_body(NationalBody::ESP)
esp.period(
  "2024-04-01 ->",
  dfe_sign_in: {
    test: "722ebb41-42f6-4ba3-81b6-61af055246a5",
    pp: "b98cb613-192f-400e-9b50-fd7eea9882a1"
    # prod: "dbb5d311-3154-42c5-a8bb-183b39775da6"
  }
)

nta = national_body(NationalBody::NTA)
nta.period(
  "2013-08-31 -> 2024-09-01"
)

# Teaching school hubs
# ----------------------------------------------------------------------------
print_seed_info("🏫 Teaching school hubs", colour: :yellow)

# Genuine hubs with concurrent appropriate bodies
# ----------------------------------------------------------------------------

# https://fivecountiesalliance.co.uk
five_counties_teaching_school_hub_alliance = teaching_school_hub("Five Counties Teaching School Hub Alliance")
five_counties_teaching_school_hub_alliance.period(
  "2021-09-01 ->",
  name_override: "Five Counties Teaching School Hubs Alliance (Somerset)",
  provisioning_school: 135_959,
  dfe_sign_in: {
    test: "3f4e1f14-ac8c-48b0-a8b9-1c75b471bbcd",
    pp: "d0980f89-eda1-409d-bcd2-a88257ca7760"
    # prod: "1a18807c-2191-4230-9272-31e496f9013a"
  }
) do
  region "SW5", districts: %w[Somerset], lead_school: 135_959
  region "SW9", districts: ["Bristol", "North Somerset"], lead_school: 135_959
end
five_counties_teaching_school_hub_alliance.period(
  "2021-09-01 ->",
  name_override: "Five Counties Teaching School Hubs Alliance (South Glos/BANES)",
  provisioning_school: 149_948,
  dfe_sign_in: {
    test: "473f201b-9f2d-4648-bb9e-750c292bb072",
    pp: "f53af8e7-b303-4e8e-9374-3a18c083f271"
    # prod: "5ac51104-9a6e-4312-ad73-25769a8e801e"
  }
) do
  region "SW6", districts: ["Bath and North East Somerset", "South Gloucestershire"], lead_school: 149_948
end

# https://staracademies.org/our-partnerships/star-teaching-school-hub-network
star_teaching_school_hub_network = teaching_school_hub("Star Teaching School Hub Network")
star_teaching_school_hub_network.period(
  "2021-09-01 ->",
  name_override: "Star Teaching School Hub Birmingham South",
  provisioning_school: 141_969,
  dfe_sign_in: {
    test: "2720e261-f131-4f55-b9d4-b6618a8633d3",
    pp: "49f7ccdb-b1a3-4154-851f-cd872f4b4bbe"
    # prod: "33867e30-4902-4854-97a0-f595f2998df1"
  }
) do
  region "WM10", districts: ["Birmingham South"], lead_school: 141_969
end
star_teaching_school_hub_network.period(
  "2021-09-01 ->",
  name_override: "Star Teaching School Hub Bolton, Bury, Rochdale, North West Lancashire and Pennine Lancashire",
  provisioning_school: 140_959,
  dfe_sign_in: {
    test: "191c7072-bd72-4d1c-989f-3747c6d14eec",
    pp: "b6cac4aa-dba8-4e81-8bbc-6dcad47785c6"
    # prod: "218b2e2f-f869-43aa-a7a3-8bece4b2949b"
  }
) do
  region "NW3", districts: %w[Bolton Bury Rochdale], lead_school: 140_959
  region "NW4", districts: %w[Blackpool Preston Lancaster Wyre], lead_school: 138_220
  region "NW5", districts: ["Hyndburn", "Burnley", "Pendle", "Blackburn with Darwen", "Ribble Valley", "Rossendale"], lead_school: 141_565
end
# This is an edge case that should not exist but that we must accommodate until 2028
star_teaching_school_hub_network.period(
  "2021-09-01 ->",
  name_override: "Star Teaching School Hub Bolton, Bury, Rochdale, North West Lancashire and Pennine Lancashire (alternative provisioner)",
  provisioning_school: 138_220
) do
  region "NW3", districts: %w[Bolton Bury Rochdale], lead_school: 140_959
  region "NW4", districts: %w[Blackpool Preston Lancaster Wyre], lead_school: 138_220
  region "NW5", districts: ["Hyndburn", "Burnley", "Pendle", "Blackburn with Darwen", "Ribble Valley", "Rossendale"], lead_school: 141_565
end

# Genuine hubs with a single period
# ----------------------------------------------------------------------------

# https://tsh.bright-futures.co.uk
bright_futures_teaching_school_hub = teaching_school_hub("Bright Futures Teaching School Hub")
bright_futures_teaching_school_hub.period(
  "2021-09-01 ->",
  name_override: nil,
  provisioning_school: 137_289,
  dfe_sign_in: {
    test: "ca3a5295-d180-4b80-8abc-4b05c5b19210",
    pp: "5942f0f9-a1ac-4e16-8ef8-2d5da63b075c"
    # prod: "c8350beb-f95a-4d03-b24e-3568d1760281"
  }
) do
  region "NW7", districts: %w[Manchester Stockport], lead_school: 137_289
  region "NW9", districts: %w[Salford Trafford], lead_school: 137_289
end

# https://www.stepinstitute.org.uk/teaching-school-hub/teaching-school-hub
step_ahead_teaching_school_hub = teaching_school_hub("STEP Ahead Teaching School Hub")
step_ahead_teaching_school_hub.period(
  "2021-09-01 ->",
  name_override: nil,
  provisioning_school: 141_666,
  dfe_sign_in: {
    test: "83173e6f-ba28-4654-a3df-8279d573ab09",
    pp: "62fafd5e-2c25-4214-91ad-1de69262820a"
    # prod: "7bb6e826-6322-4686-8775-3be78f980d70"
  }
) do
  region "SE1", districts: ["Wealden", "Lewes", "Brighton and Hove", "Rother", "Hastings", "Eastbourne"], lead_school: 141_666
end

# https://www.ktsh.org.uk
kent_teaching_school_hub = teaching_school_hub("Kent Teaching School Hub")
kent_teaching_school_hub.period(
  "2021-09-01 ->",
  name_override: nil,
  provisioning_school: 136_603
) do
  region "SE2", districts: ["Ashford", "Canterbury", "Dover", "Folkestone and Hythe", "Swale", "Thanet"], lead_school: 136_603
  region "SE8", districts: ["Sevenoaks", "Tunbridge Wells", "Tonbridge and Malling", "Maidstone"], lead_school: 136_603
end

# https://www.unityteachingschoolhub.net
unity_teaching_school_hub = teaching_school_hub("Unity Teaching School Hub")
unity_teaching_school_hub.period(
  "2021-09-01 ->",
  name_override: nil,
  provisioning_school: 139_732
) do
  region "EE2", districts: %w[Colchester Tendring Ipswich Babergh], lead_school: 139_732
  region "EE6", districts: ["East Suffolk S.", "Mid Suffolk", "West Suffolk"], lead_school: 139_732
end

# https://www.teaching-school.co.uk
chiltern_tsh = teaching_school_hub("Chiltern TSH")
chiltern_tsh.period(
  "2021-09-01 ->",
  name_override: nil,
  provisioning_school: 136_319
) do
  region "EE8", districts: ["Luton", "North Hertfordshire", "Broxbourne", "Stevenage", "East Hertfordshire"], lead_school: 136_319
  region "EE9", districts: ["Bedford", "Central Bedfordshire", "Milton Keynes"], lead_school: 136_319
end

# https://embrace-education.co.uk/teaching-school-hub
embrace_teaching_school_hub = teaching_school_hub("Embrace Teaching School Hub")
embrace_teaching_school_hub.period(
  "2021-09-01 ->",
  name_override: nil,
  provisioning_school: 143_879
) do
  region "NW6", districts: ["Chorley", "West Lancashire", "South Ribble", "Fylde"], lead_school: 143_879
end

# https://www.exchangeteachinghub.org.uk
exchange_teaching_school_hub = teaching_school_hub("Exchange Teaching School Hub")
exchange_teaching_school_hub.period(
  "2021-09-01 ->",
  name_override: nil,
  provisioning_school: 137_482
) do
  region "YH1", districts: %w[Barnsley Doncaster], lead_school: 137_482
  region "YH8", districts: ["North Yorkshire S.", "Wakefield"], lead_school: 138_332
end

# Mock hubs
# ----------------------------------------------------------------------------

canvas_teaching_school_hub = teaching_school_hub("Canvas Teaching School Hub")
canvas_teaching_school_hub.period(
  "2021-09-01 -> 2024-08-31",
  name_override: nil,
  provisioning_school: 9_400_101
) do
  region "ZZ1", districts: ["Hogsmeade", "Godric's Hollow"], lead_school: 9_400_101
end
canvas_teaching_school_hub.period(
  "2024-09-01 ->",
  name_override: "Canvas Studio",
  provisioning_school: 9_400_101
) do
  region "ZZ2", districts: ["Hogwarts", "Diagon Alley"], lead_school: 9_400_101
end

# A closed hub
south_yorkshire_studio_hub = teaching_school_hub("South Yorkshire Studio Hub")
south_yorkshire_studio_hub.period(
  "2021-09-01 -> 2024-08-31",
  name_override: nil,
  provisioning_school: 9_400_102
) do
  region "ZZ3", districts: %w[Mordor Rohan],
                lead_school: 9_400_102,
                deactivated_on: "2024-08-31",
                reason: "school closed"
end

# Ochre is the shape Exchange TSH could obtain:
#   - The non-provisioning lead school in the first body period leaves to become a provisioner of its own period.
#   - Its region award is moved to the new body.
#   - The teaching school hub rebrands to a new name and the original period is given a distinguishing name.
ochre_education_partnership = teaching_school_hub("Ochre Education Partnership")
ochre_education_partnership.period(
  "2021-09-01 ->",
  name_override: "Ochre Education Partnership (Winterfell)",
  provisioning_school: 9_400_103
) do
  region "ZZ4", districts: %w[Winterfell Riverrun],
                lead_school: 9_400_103
  region "ZZ5", districts: ["Dragonstone", "Storm's End"],
                lead_school: 9_400_104,
                deactivated_on: "2024-08-31",
                reason: "lead school became its own provisioner"
end
ochre_education_partnership.period(
  "2024-09-01 ->",
  name_override: "Ochre Education Partnership (Dragonstone)",
  provisioning_school: 9_400_104
) do
  region "ZZ5", districts: ["Dragonstone", "Storm's End"], lead_school: 9_400_104
end

# Persona: Fred Jones
umber_teaching_school_hub = teaching_school_hub("Umber Teaching School Hub")
umber_period = umber_teaching_school_hub.period(
  "2021-09-01 ->",
  name_override: nil,
  provisioning_school: 141_777
) do
  region "ZZ6", districts: %w[Ankh-Morpork Lancre], lead_school: 141_777
end

# A state-funded school may only remember a teaching school hub as the body it chose last.
School.find_by!(urn: 1_759_427).update!(last_chosen_appropriate_body: umber_period)

# Persona: Velma Dinkley
golden_leaf_teaching_school_hub = teaching_school_hub("Golden Leaf Teaching School Hub")
golden_leaf_teaching_school_hub.period(
  "2021-09-01 ->",
  name_override: nil,
  provisioning_school: 141_888
) do
  region "ZZ7", districts: %w[Camelot Avalon], lead_school: 141_888
end

print_seed_info("")

AppropriateBodyPeriod.ordered_by_display_name.each do
  describe_appropriate_body_period(it)
end
