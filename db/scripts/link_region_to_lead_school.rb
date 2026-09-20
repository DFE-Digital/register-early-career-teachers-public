class LinkRegionToLeadSchool
  # https://www.register-early-career-teachers.education.gov.uk/admin/blazer/queries/531-dfe-sign-in-organisations
  LEAD_SCHOOLS = [
    # East of England
    { appropriate_body_period_id: 378, region_code: "EE1",  school_urn: 136_776 }, # Saffron Walden County High School — Saffron Teaching School Hub
    { appropriate_body_period_id: 507, region_code: "EE2",  school_urn: 139_732 }, # Churchill Special Free School — Unity Teaching School Hub
    { appropriate_body_period_id: 459, region_code: "EE3",  school_urn: 139_087 }, # Histon and Impington Brook Primary School — Cambridgeshire and Peterborough Teaching School Hub
    { appropriate_body_period_id: 6,   region_code: "EE4",  school_urn: 137_913 }, # Notre Dame High School — The Julian Teaching School Hub
    { appropriate_body_period_id: 392, region_code: "EE5",  school_urn: 137_549 }, # Harris Academy Chafford Hundred — Chafford Hundred Teaching School Hub
    { appropriate_body_period_id: 507, region_code: "EE6",  school_urn: 139_732 }, # Churchill Special Free School — Unity Teaching School Hub
    { appropriate_body_period_id: 358, region_code: "EE7",  school_urn: 136_609 }, # Sandringham School — Alban Teaching School Hub
    { appropriate_body_period_id: 336, region_code: "EE8",  school_urn: 136_319 }, # Denbigh High School — Chiltern Teaching School Hub
    { appropriate_body_period_id: 336, region_code: "EE9",  school_urn: 136_319 }, # Denbigh High School — Chiltern Teaching School Hub
    { appropriate_body_period_id: 526, region_code: "EE10", school_urn: 140_188 }, # Hethersett Academy — Inspiration Teaching School Hub
    # East Midlands
    { appropriate_body_period_id: 4,   region_code: "EM1", school_urn: 146_158 }, # Christ the King Catholic Voluntary Academy — Leicestershire & Rutland TS Hub
    { appropriate_body_period_id: 3,   region_code: "EM2", school_urn: 144_932 }, # The Carlton Junior Academy — Redhill Teaching Hub
    { appropriate_body_period_id: 257, region_code: "EM3", school_urn: 113_033 }, # Swanwick School and Sports College — Potentia TSH
    { appropriate_body_period_id: 531, region_code: "EM4", school_urn: 140_398 }, # The Flying High Academy Ladybrook — Flying High Teaching School Hub
    { appropriate_body_period_id: 273, region_code: "EM5", school_urn: 141_916 }, # Rushey Mead Academy — Leicester & Leicestershire TSH
    { appropriate_body_period_id: 416, region_code: "EM6", school_urn: 137_978 }, # Witham St Hughs Academy — L.E.A.D. Teaching School Hub Lincolnshire
    { appropriate_body_period_id: 414, region_code: "EM7", school_urn: 138_070 }, # Chetwynd Primary Academy — Spencer Teaching School Hub
    { appropriate_body_period_id: 422, region_code: "EM8", school_urn: 135_317 }, # Brooke Weston Academy — Northamptonshire Teaching School Hub
    # London
    { appropriate_body_period_id: 27,  region_code: "L1",  school_urn: 143_629 }, # Mulberry School for Girls — East London Teaching School Hub
    { appropriate_body_period_id: 513, region_code: "L2",  school_urn: 143_881 }, # Tollgate Primary School — London District East Teaching School Hub
    { appropriate_body_period_id: 533, region_code: "L3",  school_urn: 139_703 }, # Harris Academy Chobham — North East London Teaching School Hub
    { appropriate_body_period_id: 424, region_code: "L4",  school_urn: 138_457 }, # Wembley High Technology College — North West London Teaching School Hub
    { appropriate_body_period_id: 390, region_code: "L5",  school_urn: 137_546 }, # Twyford CE High School — Teach West London
    { appropriate_body_period_id: 316, region_code: "L6",  school_urn: 130_912 }, # Paddington Academy — Central London Teaching School Hub
    { appropriate_body_period_id: 1,   region_code: "L7",  school_urn: 145_280 }, # Chesterton Primary School — Wandle Teaching School Hub
    { appropriate_body_period_id: 463, region_code: "L8",  school_urn: 135_311 }, # Harris City Academy Crystal Palace — Harris City Academy Crystal Palace Teaching School Hub
    { appropriate_body_period_id: 10,  region_code: "L9",  school_urn: 148_012 }, # Charles Dickens Primary — London South Teaching School Hub
    { appropriate_body_period_id: 388, region_code: "L10", school_urn: 137_069 }, # Pickhurst Infant Academy — Thames South Teaching School Hub
    # North East
    { appropriate_body_period_id: 396, region_code: "NE1", school_urn: 149_328 }, # King Edward VI High School — The Three Rivers Teaching School Hub
    { appropriate_body_period_id: 19,  region_code: "NE2", school_urn: 148_817 }, # St John Vianney Catholic Primary School — Tees Valley Teaching School Hub
    { appropriate_body_period_id: 409, region_code: "NE3", school_urn: 137_831 }, # Benedict Biscop CE Academy — Northern Lights TSH: South Tyne & Wear
    { appropriate_body_period_id: 37,  region_code: "NE4", school_urn: 144_496 }, # Teesdale School and Sixth Form — NELTSH Teaching School Hub
    # North West
    { appropriate_body_period_id: 522, region_code: "NW1",  school_urn: 140_458 }, # Our Lady of Pity Catholic Primary School — Inspire Learning Teaching School Hub NW
    { appropriate_body_period_id: 43,  region_code: "NW2",  school_urn: 143_064 }, # Evelyn Street Primary School — Generate Teaching Hub
    { appropriate_body_period_id: 63,  region_code: "NW3",  school_urn: 140_959 }, # Eden Boys' School Bolton — Star Teaching School Hub Pennine Lancashire
    { appropriate_body_period_id: 63,  region_code: "NW4",  school_urn: 138_220 }, # Tauheedul Islam Boys' High School — Star Teaching School Hub Pennine Lancashire
    { appropriate_body_period_id: 63,  region_code: "NW5",  school_urn: 141_565 }, # Tauheedul Islam Girls' High School — Star Teaching School Hub Pennine Lancashire
    { appropriate_body_period_id: 57,  region_code: "NW6",  school_urn: 143_879 }, # Tor View School — Embrace Teaching School Hub (SW Lancashire)
    { appropriate_body_period_id: 383, region_code: "NW7",  school_urn: 137_289 }, # Altrincham Grammar School for Girls — Bright Futures Teaching School Hub-Salford & Trafford
    { appropriate_body_period_id: 44,  region_code: "NW8",  school_urn: 141_582 }, # St Silas Church of England Primary School — Rainbow Teaching School Hub
    { appropriate_body_period_id: 383, region_code: "NW9",  school_urn: 137_289 }, # Altrincham Grammar School for Girls — Bright Futures Teaching School Hub-Salford & Trafford
    { appropriate_body_period_id: 384, region_code: "NW10", school_urn: 137_133 }, # The Blue Coat CofE School — The East Manchester Teaching Hub
    { appropriate_body_period_id: 534, region_code: "NW11", school_urn: 135_632 }, # West Lakes Academy — One Cumbria Teaching School Hub
    { appropriate_body_period_id: 476, region_code: "NW12", school_urn: 136_460 }, # St Joseph's College — Cheshire Teaching School Hub
    # South East
    { appropriate_body_period_id: 45,  region_code: "SE1",  school_urn: 141_666 }, # Angel Oak Academy — STEP Ahead Teaching School Hub
    { appropriate_body_period_id: 366, region_code: "SE2",  school_urn: 136_603 }, # Bennett Memorial Diocesan School — Kent Teaching School Hub
    { appropriate_body_period_id: 346, region_code: "SE3",  school_urn: 136_715 }, # Thornden School — HISP Teaching School Hub (Thornden School)
    { appropriate_body_period_id: 403, region_code: "SE4",  school_urn: 137_736 }, # Rosebery School — GLF West Sussex Teaching School Hub
    { appropriate_body_period_id: 53,  region_code: "SE5",  school_urn: 143_369 }, # St John the Baptist — Xavier Teaching School Hub
    { appropriate_body_period_id: 329, region_code: "SE6",  school_urn: 136_419 }, # Dr Challoner's Grammar School — Astra Teaching School Hub, Buckinghamshire
    { appropriate_body_period_id: 442, region_code: "SE7",  school_urn: 138_626 }, # Portswood Primary School — HISP Teaching School Hub (Portswood Primary)
    { appropriate_body_period_id: 366, region_code: "SE8",  school_urn: 136_603 }, # Bennett Memorial Diocesan School — Kent Teaching School Hub
    { appropriate_body_period_id: 490, region_code: "SE9",  school_urn: 137_970 }, # The Cherwell School — Oxfordshire Teaching School Hub
    { appropriate_body_period_id: 518, region_code: "SE10", school_urn: 136_521 }, # Langley Grammar School — TSH Berkshire
    { appropriate_body_period_id: 469, region_code: "SE11", school_urn: 136_888 }, # South Farnham School — SFET Teaching School Hub
    { appropriate_body_period_id: 347, region_code: "SE12", school_urn: 136_662 }, # Sir Joseph Williamson's Mathematical School — Thames Gateway Teaching School Hub
    # South West
    { appropriate_body_period_id: 475, region_code: "SW1",  school_urn: 139_498 }, # The Quay School — South Central Teaching School Hub
    { appropriate_body_period_id: 344, region_code: "SW2",  school_urn: 136_353 }, # Pate's Grammar School — Odyssey Teaching School Hub
    { appropriate_body_period_id: 331, region_code: "SW3",  school_urn: 136_367 }, # Kingsbridge Community College — Kingsbridge Teaching School Hub
    { appropriate_body_period_id: 330, region_code: "SW4",  school_urn: 136_366 }, # Colyton Grammar School — Colyton Teaching School Hub
    { appropriate_body_period_id: 326, region_code: "SW5",  school_urn: 135_959 }, # Bristol Metropolitan Academy — Five Counties Teaching School Hubs Alliance (Somerset)
    { appropriate_body_period_id: 20,  region_code: "SW6",  school_urn: 149_948 }, # Mangotsfield Church of England Primary School — Five Counties Teaching School Hubs Alliance (South Glos/BANES)
    { appropriate_body_period_id: 509, region_code: "SW7",  school_urn: 140_008 }, # Glenmoor Academy — Swindon and Wiltshire Teaching School Hub
    { appropriate_body_period_id: 335, region_code: "SW8",  school_urn: 136_312 }, # Trenance Learning Academy — One Cornwall Teaching School Hub (West)
    { appropriate_body_period_id: 326, region_code: "SW9",  school_urn: 135_959 }, # Bristol Metropolitan Academy — Five Counties Teaching School Hubs Alliance (Somerset)
    { appropriate_body_period_id: 355, region_code: "SW10", school_urn: 136_474 }, # Balcarras School — Balcarras
    { appropriate_body_period_id: 364, region_code: "SW11", school_urn: 136_572 }, # The Roseland Academy — One Cornwall Teaching School Hub (East Cornwall)
    # West Midlands
    { appropriate_body_period_id: 356, region_code: "WM1",  school_urn: 136_469 }, # Prince Henry's High School — Prince Henry's Teaching School Hub
    { appropriate_body_period_id: 420, region_code: "WM2",  school_urn: 138_216 }, # The Priory School, Shrewsbury — STEP
    { appropriate_body_period_id: 337, region_code: "WM3",  school_urn: 136_323 }, # John Taylor High School — John Taylor Teaching School Hub
    { appropriate_body_period_id: 340, region_code: "WM4",  school_urn: 136_310 }, # Tudor Grange Academy, Solihull — Tudor Grange Teaching School Hub
    { appropriate_body_period_id: 439, region_code: "WM5",  school_urn: 138_729 }, # Painsley Catholic College — The Golden Thread Teaching School Hub
    { appropriate_body_period_id: 62,  region_code: "WM6",  school_urn: 141_277 }, # Lawrence Sheriff School — Coventry and Central Warwickshire Teaching School Hub
    { appropriate_body_period_id: 520, region_code: "WM7",  school_urn: 136_898 }, # Haybridge High School and Sixth Form — Haybridge Teaching School Hub
    { appropriate_body_period_id: 46,  region_code: "WM8",  school_urn: 141_858 }, # Manor Primary School, Bilston WV14 9UQ — Manor Teaching School Hub
    { appropriate_body_period_id: 288, region_code: "WM9",  school_urn: 138_136 }, # The Arthur Terry School — Arthur Terry Teaching School Hub-North Birmingham
    { appropriate_body_period_id: 25,  region_code: "WM10", school_urn: 141_969 }, # Eden Boys' School, Birmingham — Star Teaching School Hub Birmingham South
    # Yorkshire & Humber
    { appropriate_body_period_id: 376, region_code: "YH1",  school_urn: 137_482 }, # Grange Lane Infant Academy — Exchange Teaching School Hub
    { appropriate_body_period_id: 525, region_code: "YH2",  school_urn: 139_167 }, # Silverdale School — South Yorkshire Teaching Hub
    { appropriate_body_period_id: 359, region_code: "YH3",  school_urn: 136_617 }, # Archbishop Holgate's School — Pathfinder Teaching School Hub
    { appropriate_body_period_id: 386, region_code: "YH4",  school_urn: 137_200 }, # Humberston Academy — DRET Teaching School Hub
    { appropriate_body_period_id: 7,   region_code: "YH5",  school_urn: 144_104 }, # St Mary's College, Voluntary Aided Catholic Academy — The Vantage Teaching School Hub North Humber
    { appropriate_body_period_id: 511, region_code: "YH6",  school_urn: 140_076 }, # Harden Primary Academy School — Exceed Teaching School Hub
    { appropriate_body_period_id: 382, region_code: "YH7",  school_urn: 137_352 }, # Shelley College — Calderdale and Kirklees Teaching School Hub
    { appropriate_body_period_id: 376, region_code: "YH8",  school_urn: 138_332 }, # The Vale Primary Academy — Exchange TSH
    { appropriate_body_period_id: 334, region_code: "YH9",  school_urn: 136_392 }, # The Morley Academy — Leeds Teaching School Hub
    { appropriate_body_period_id: 437, region_code: "YH10", school_urn: 136_497 }, # Harrogate Grammar School — Red Kite Teaching School Hub
  ].freeze

  attr_reader :lead_schools

  def initialize(lead_schools = LEAD_SCHOOLS)
    @lead_schools = lead_schools
  end

  def call
    ActiveRecord::Base.transaction do
      lead_schools.each do |data|
        region = Region.find_by!(code: data[:region_code])
        school = School.find_by!(urn: data[:school_urn])
        appropriate_body = AppropriateBodyPeriod.find(data[:appropriate_body_period_id])

        TeachingSchoolHub::LeadSchool.find_or_create_by!(region:, school:, appropriate_body:)
      end
    end
  end
end
