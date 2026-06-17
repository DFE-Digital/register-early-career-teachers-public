def describe_region(name, region)
  print_seed_info("#{Colourize.text(name, :yellow)} (#{region.code}): #{region.districts}", indent: 2)
end

# rubocop:disable Style/WordArray
{
  "North West" => ["Blackburn with Darwen", "Blackpool", "Bolton", "Bury"],
  # "Cheshire East", "Cheshire West and Chester", "Cumbria", "Halton", "Knowsley", "Lancashire", "Liverpool", "Manchester",
  # "Oldham", "Rochdale", "Salford", "Sefton", "St. Helens", "Stockport", "Tameside", "Trafford", "Warrington", "Wigan", "Wirral",

  "North East" => ["Darlington", "Durham", "Gateshead", "Hartlepool"],
  # "Middlesbrough", "Newcastle upon Tyne", "North Tyneside", "Northumberland", "Redcar and Cleveland", "South Tyneside",
  # "Stockton-on-Tees", "Sunderland",

  "Yorkshire and the Humber" => ["Barnsley", "Bradford", "Calderdale", "Doncaster"],
  # "East Riding of Yorkshire", "Kingston upon Hull, City of", "Kirklees", "Leeds", "North East Lincolnshire", "North Lincolnshire",
  # "North Yorkshire", "Rotherham", "Sheffield", "Wakefield", "York"

  "East Midlands" => ["Derby", "Derbyshire", "Leicester", "Leicestershire"],
  # "Lincolnshire", "North Northamptonshire", "Nottingham", "Nottinghamshire", "Rutland", "West Northamptonshire"

  "West Midlands" => ["Birmingham", "Coventry", "Dudley", "Herefordshire, County of"],
  # "Sandwell", "Shropshire", "Solihull", "Staffordshire", "Stoke-on-Trent", "Telford and Wrekin", "Walsall", "Warwickshire",
  # "Wolverhampton", "Worcestershire"

  "East of England" => ["Bedford", "Cambridgeshire", "Central Bedfordshire", "Essex"],
  # "Hertfordshire", "Luton", "Norfolk", "Peterborough", "Southend-on-Sea", "Suffolk", "Thurrock"

  "London" => ["Barking and Dagenham", "Barnet", "Bexley", "Brent"],
  # "Bromley", "Camden", "City of London", "Croydon", "Ealing", "Enfield", "Greenwich", "Hackney", "Hammersmith and Fulham", "Haringey",
  # "Harrow", "Havering", "Hillingdon", "Hounslow", "Islington", "Kensington and Chelsea", "Kingston upon Thames", "Lambeth", "Lewisham",
  # "Merton", "Newham", "Redbridge", "Richmond upon Thames", "Southwark", "Sutton", "Tower Hamlets", "Waltham Forest", "Wandsworth",
  # "Westminster"

  "South East" => ["Bracknell Forest", "Brighton and Hove", "Buckinghamshire", "East Sussex"],
  # "Hampshire", "Isle of Wight", "Kent", "Medway", "Milton Keynes", "Oxfordshire", "Portsmouth", "Reading", "Slough", "Southampton",
  # "Surrey", "West Berkshire", "West Sussex", "Windsor and Maidenhead", "Wokingham",

  "South West" => ["Bath and North East Somerset", "Bournemouth, Christchurch and Poole", "Bristol, City of", "Cornwall"]
  # "Devon", "Dorset", "Gloucestershire", "Isles Of Scilly", "North Somerset", "Plymouth", "Somerset", "South Gloucestershire",
  # "Swindon", "Torbay", "Wiltshire"

}.each do |region_name, districts|
  FactoryBot.create(:region, districts:).tap do |region|
    describe_region(region_name, region)
  end
end
# rubocop:enable Style/WordArray
