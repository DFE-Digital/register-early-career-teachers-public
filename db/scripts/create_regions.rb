# Populate all Teaching School Hub regions
#
regions = [
  # East of England
  ["EE1", "Chelmsford, Braintree, Uttlesford, Epping Forest, Harlow"],
  ["EE2", "Colchester, Tendring, Ipswich, Babergh"],
  ["EE3", "Cambridge, South Cambridgeshire, Huntingdonshire, Peterborough, Fenland, East Cambridgeshire"],
  ["EE4", "North Norfolk, King's Lynn and West Norfolk, Norwich, Broadland"],
  ["EE5", "Southend-on-Sea, Basildon, Maldon, Castle Point, Rochford, Brentwood, Thurrock"],
  ["EE6", "East Suffolk S., Mid Suffolk, West Suffolk"],
  ["EE7", "St Albans, Welwyn Hatfield, Dacorum, Watford, Three Rivers, Hertsmere"],
  ["EE8", "Luton, North Hertfordshire, Broxbourne, Stevenage, East Hertfordshire"],
  ["EE9", "Bedford, Central Bedfordshire, Milton Keynes"],
  ["EE10", "Breckland, East Suffolk N, Great Yarmouth, South Norfolk"],
  # East Midlands
  ["EM1", "Charnwood, North West Leicestershire, Melton, Hinckley and Bosworth, Rutland"],
  ["EM2", "Gedling, Bassetlaw, Newark and Sherwood"],
  ["EM3", "High Peak, Amber Valley, Derbyshire Dales, Bolsover, North East Derbyshire, Chesterfield"],
  ["EM4", "Ashfield, Nottingham, Mansfield, Broxtowe, Rushcliffe"],
  ["EM5", "Harborough, Blaby, Oadby and Wigston, Leicester"],
  ["EM6", "South Kesteven, Lincoln, North Kesteven, South Holland, Boston, East Lindsey, West Lindsey"],
  ["EM7", "Derby, South Derbyshire, Erewash"],
  ["EM8", "North Northamptonshire, West Northamptonshire"],
  # London
  ["L1", "Hackney, Tower Hamlets"],
  ["L2", "Newham, Barking and Dagenham, Havering"],
  ["L3", "Haringey, Redbridge, Waltham Forest"],
  ["L4", "Barnet, Enfield, Brent"],
  ["L5", "Ealing, Harrow, Hillingdon, Hounslow"],
  ["L6", "City of London, Camden, Hammersmith and Fulham, Islington, Kensington and Chelsea, Westminster"],
  ["L7", "Wandsworth, Kingston upon Thames, Merton, Richmond upon Thames"],
  ["L8", "Croydon, Sutton, Epsom and Ewell"],
  ["L9", "Lambeth, Southwark, Lewisham"],
  ["L10", "Greenwich, Bexley, Bromley"],
  # North East
  ["NE1", "Northumberland, Newcastle upon Tyne, North Tyneside"],
  ["NE2", "Stockton-on-Tees, Redcar and Cleveland, Middlesbrough, Hartlepool, Darlington"],
  ["NE3", "Gateshead, South Tyneside, Sunderland"],
  ["NE4", "County Durham"],
  # North West
  ["NW1", "Wirral, Liverpool"],
  ["NW2", "Wigan, Halton, Warrington"],
  ["NW3", "Bolton, Bury, Rochdale"],
  ["NW4", "Blackpool, Preston, Lancaster, Wyre"],
  ["NW5", "Hyndburn, Burnley, Pendle, Blackburn with Darwen, Ribble Valley, Rossendale"],
  ["NW6", "Chorley, West Lancashire, South Ribble, Fylde"],
  ["NW7", "Manchester, Stockport"],
  ["NW8", "Knowsley, St. Helens, Sefton"],
  ["NW9", "Salford, Trafford"],
  ["NW10", "Oldham, Tameside"],
  ["NW11", "Cumberland, Westmorland and Furness"],
  ["NW12", "Cheshire East, Cheshire West and Chester"],
  # South East
  ["SE1", "Wealden, Lewes, Brighton and Hove, Rother, Hastings, Eastbourne"],
  ["SE2", "Ashford, Canterbury, Dover, Folkestone and Hythe, Swale, Thanet"],
  ["SE3", "Havant, Gosport, Eastleigh, Fareham, Portsmouth, Isle of Wight"],
  ["SE4", "Arun, Chichester, Horsham, Adur, Crawley, Worthing, Mid Sussex"],
  ["SE5", "Runnymede, Mole Valley, Reigate and Banstead, Elmbridge, Tandridge, Surrey Heath, Woking, Spelthorne"],
  ["SE6", "Buckinghamshire"],
  ["SE7", "Southampton, Test Valley, New Forest, Winchester"],
  ["SE8", "Sevenoaks, Tunbridge Wells, Tonbridge and Malling, Maidstone"],
  ["SE9", "Oxford, South Oxfordshire, West Oxfordshire, Cherwell, Vale of White Horse"],
  ["SE10", "Wokingham, Reading, Windsor and Maidenhead, West Berkshire, Slough, Bracknell Forest"],
  ["SE11", "Rushmoor, East Hampshire, Basingstoke and Deane, Hart, Waverley, Guildford"],
  ["SE12", "Gravesham, Dartford, Medway"],
  # South West
  ["SW1", "Bournemouth, Christchurch and Poole, Dorset"],
  ["SW2", "Gloucester, Tewkesbury, Forest of Dean"],
  ["SW3", "Exeter, Plymouth, South Hams, Teignbridge, Torbay, West Devon"],
  ["SW4", "Mid Devon, East Devon, Torridge, North Devon"],
  ["SW5", "Somerset"],
  ["SW6", "Bath and North East Somerset, South Gloucestershire"],
  ["SW7", "Swindon, Wiltshire"],
  ["SW8", "Cornwall, Isles of Scilly"],
  ["SW9", "Bristol, North Somerset"],
  ["SW10", "Stroud, Cotswold, Cheltenham"],
  ["SW11", "Cornwall"],
  # West Midlands
  ["WM1", "Herefordshire, Wychavon, Malvern Hills, Worcester, Wyre Forest"],
  ["WM2", "Telford and Wrekin, Shropshire"],
  ["WM3", "Cannock Chase, East Staffordshire, Lichfield, Tamworth, North Warwickshire, Nuneaton and Bedworth"],
  ["WM4", "Solihull, Bromsgrove, Redditch, Stratford-on-Avon"],
  ["WM5", "Newcastle-under-Lyme, Stoke-on-Trent, Staffordshire Moorlands, Stafford"],
  ["WM6", "Coventry, Warwick, Rugby"],
  ["WM7", "Sandwell, Dudley"],
  ["WM8", "Walsall, Wolverhampton, South Staffordshire"],
  ["WM9", "Birmingham North"],
  ["WM10", "Birmingham South"],
  # Yorkshire & Humber
  ["YH1", "Barnsley, Doncaster"],
  ["YH2", "Rotherham, Sheffield"],
  ["YH3", "North Yorkshire E., York"],
  ["YH4", "North East Lincolnshire, North Lincolnshire"],
  ["YH5", "Kingston upon Hull, East Riding of Yorkshire"],
  ["YH6", "Bradford"],
  ["YH7", "Calderdale, Kirklees"],
  ["YH8", "North Yorkshire S., Wakefield"],
  ["YH9", "Leeds"],
  ["YH10", "North Yorkshire W."],

]

ActiveRecord::Base.transaction do
  Region.delete_all

  regions.each do |code, districts|
    districts = districts.split(", ")

    Region.create!(code:, districts:)
  end
end
