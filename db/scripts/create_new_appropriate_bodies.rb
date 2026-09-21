class CreateNewAppropriateBodies
  TSH_NAMES = [
    "Alban Teaching School Hub",
    "Arthur Terry Teaching School Hub",
    "Astra Teaching School Hub",
    "Balcarras",
    "Bright Futures Teaching School Hub",
    "Calderdale and Kirklees Teaching School Hub",
    "Cambridgeshire and Peterborough Teaching School Hub",
    "Central London Teaching School Hub",
    "Chafford Hundred Teaching School Hub",
    "Cheshire Teaching School Hub",
    "Chiltern Teaching School Hub",
    "Colyton Teaching School Hub",
    "Coventry and Central Warwickshire Teaching School Hub",
    "DRET Teaching School Hub",
    "East London Teaching School Hub",
    "Embrace Teaching School Hub",
    "Exceed Teaching School Hub",
    "Exchange Teaching School Hub",
    "Five Counties Teaching School Hubs Alliance",
    "Flying High Teaching School Hub",
    "Generate Teaching Hub",
    "GLF West Sussex Teaching School Hub",
    "Harris City Academy Crystal Palace Teaching School Hub",
    "Haybridge Teaching School Hub",
    "HISP Teaching School Hub",
    "Inspiration Teaching School Hub",
    "Inspire Learning Teaching School Hub",
    "John Taylor Teaching School Hub",
    "Kent Teaching School Hub",
    "Kingsbridge Teaching School Hub",
    "L.E.A.D. Teaching School Hub",
    "Leeds Teaching School Hub",
    "Leicester & Leicestershire Teaching School Hub",
    "Leicestershire & Rutland Teaching School Hub",
    "London District East Teaching School Hub",
    "London South Teaching School Hub",
    "Manor Teaching School Hub",
    "NELTSH Teaching School Hub",
    "Northamptonshire Teaching School Hub",
    "North East London Teaching School Hub",
    "Northern Lights Teaching School Hub",
    "North West London Teaching School Hub",
    "Odyssey Teaching School Hub",
    "One Cornwall Teaching School Hub",
    "One Cumbria Teaching School Hub",
    "Oxfordshire Teaching School Hub",
    "Pathfinder Teaching School Hub",
    "Potentia Teaching School Hub",
    "Prince Henry's Teaching School Hub",
    "Rainbow Teaching School Hub",
    "Redhill Teaching Hub",
    "Red Kite Teaching School Hub",
    "Saffron Teaching School Hub",
    "SFET Teaching School Hub",
    "South Central Teaching School Hub",
    "South Yorkshire Teaching Hub",
    "Spencer Teaching School Hub",
    "Star Teaching School Hub",
    "STEP Ahead Teaching School Hub",
    "Swindon and Wiltshire Teaching School Hub",
    "Teach West London",
    "Tees Valley Teaching School Hub",
    "Thames Gateway Teaching School Hub",
    "Thames South Teaching School Hub",
    "The East Manchester Teaching Hub",
    "The Golden Thread Teaching School Hub",
    "The Julian Teaching School Hub",
    "The Three Rivers Teaching School Hub",
    "The Vantage Teaching School Hub",
    "TSH Berkshire",
    "Tudor Grange Teaching School Hub",
    "Unity Teaching School Hub",
    "Wandle Teaching School Hub",
    "West Lakes Academy",
    "Xavier Teaching School Hub",
  ].freeze

  attr_reader :tsh_names

  def initialize(tsh_names = TSH_NAMES)
    @tsh_names = tsh_names
  end

  def call
    ActiveRecord::Base.transaction do
      update_nta_type
      create_national_bodies
      create_local_authorities
      create_teaching_school_hubs
    end
  end

private

  def update_nta_type
    AppropriateBodyPeriod.find_by(name: "National Teacher Accreditation")&.update!(body_type: "national")
  end

  def create_national_bodies
    AppropriateBodyPeriod.national.each do |ab|
      NationalBody.find_or_create_by!(name: ab.name)
    end
  end

  def create_local_authorities
    AppropriateBodyPeriod.local_authority.each do |ab|
      LocalAuthority.find_or_create_by!(name: ab.name)
    end
  end

  def create_teaching_school_hubs
    tsh_names.each do |name|
      TeachingSchoolHub.find_or_create_by!(name:)
    end
  end
end
