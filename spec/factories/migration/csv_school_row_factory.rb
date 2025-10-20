FactoryBot.define do
  factory :csv_school_row, class: "CSV::Row" do
    sequence(:name) { |n| "School #{n}" }

    transient do
      header { ["URN", "LA (code)", "LA (name)", "EstablishmentNumber", "EstablishmentName", "TypeOfEstablishment (code)", "TypeOfEstablishment (name)", "EstablishmentStatus (code)", "EstablishmentStatus (name)", "OpenDate", "CloseDate", "PhaseOfEducation (code)", "PhaseOfEducation (name)", "UKPRN", "LastChangedDate", "Street", "Locality", "Address3", "Town", "Postcode", "SchoolWebsite", "MainEmail", "AlternativeEmail", "Section41Approved (name)", "DistrictAdministrative (code)", "DistrictAdministrative (name)", "Easting", "Northing", "PreviousLA (code)", "PreviousLA (name)"] }

      urn { Faker::Number.unique.number(digits: 6).to_s }
      local_authority_code { Faker::Number.unique.number(digits: 3).to_s }
      local_authority_name { "" }
      establishment_number { urn }
      type_code { "47" }
      type_name { "Children's centre" }
      status_code { "1" }
      status { "open" }
      opened_on { "18-12-2009" }
      closed_on { "" }
      phase_code { "0" }
      phase_name { "Not Applicable" }
      ukprn { Faker::Number.unique.number(digits: 5).to_s }
      last_changed_date { "25-06-2025" }
      street { Faker::Address.street_address }
      locality { "" }
      address3 { "Gladeside" }
      town { "Bar Hill" }
      postcode { Faker::Address.postcode }
      website { "https://#{name}.com" }
      main_email { Faker::Internet.unique.email }
      alternative_email { Faker::Internet.unique.email }
      section_41_approved_name { "Approved" }
      administrative_district_code { "E07000012" }
      administrative_district_name { "South Cambridgeshire" }
      easting { "538104" }
      northing { "263602" }
      previous_local_authority_code { "999" }
      previous_local_authority_name { "" }
    end

    skip_create

    initialize_with do
      new(header,
        [urn,
          local_authority_code,
          local_authority_name,
          establishment_number,
          name,
          type_code,
          type_name,
          status_code,
          status,
          opened_on,
          closed_on,
          phase_code,
          phase_name,
          ukprn,
          last_changed_date,
          street,
          locality,
          address3,
          town,
          postcode,
          website,
          main_email,
          alternative_email,
          section_41_approved_name,
          administrative_district_code,
          administrative_district_name,
          easting,
          northing,
          previous_local_authority_code,
          previous_local_authority_name])
    end
  end
end
