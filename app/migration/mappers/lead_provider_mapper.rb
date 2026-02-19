module Mappers
  class LeadProviderMapper
    Result = Struct.new(:trait_name, :name, :id, :cpd_lead_provider_id, keyword_init: true)

    DATA = [
      Result.new(
        trait_name: "ambition",
        name: "Ambition Institute",
        id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
        cpd_lead_provider_id: "22727fdc-816a-4a3c-9675-030e724bbf89"
      ),
      Result.new(
        trait_name: "bpn",
        name: "Best Practice Network",
        id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
        cpd_lead_provider_id: "dfad2a9c-527d-4d71-ae9a-492ab307e6c3"
      ),
      Result.new(
        trait_name: "capita",
        name: "Capita",
        id: "7a6753ef-6bb1-4fb3-ba93-fcbf3b20541b",
        cpd_lead_provider_id: "9ad41410-677f-4da3-86a1-cda62b42e176"
      ),
      Result.new(
        trait_name: "edt",
        name: "Education Development Trust",
        id: "9f0a1bdd-b9af-4603-abfd-c1af01aded76",
        cpd_lead_provider_id: "af89cf02-bbe0-423b-b2f6-bb2dbb97d141"
      ),
      Result.new(
        trait_name: "ucl",
        name: "UCL Institute of Education",
        id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
        cpd_lead_provider_id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9"
      ),
      Result.new(
        trait_name: "tf",
        name: "Teach First",
        id: "99317668-2942-4292-a895-fdb075af067b",
        cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
      ),
      Result.new(
        trait_name: "niot",
        name: "National Institute of Teaching",
        id: "82bfbad3-349f-44fb-bb60-621eab1b349b",
        cpd_lead_provider_id: "51ff9a95-3f48-4117-8466-4cd5b91fcd5c"
      )
    ].freeze

    attr_reader :index_by

    def initialize(index_by:)
      @index_by = index_by.to_sym
    end

    def get(target)
      # NOTE: Even through we only have 7 actual lead providers our tests will create
      #       an unlimited number of randomised lead provider records which aren't
      #       mapped here, so use [] instead of fetch...
      # DATA.index_by(&index_by).fetch(target)
      DATA.index_by(&index_by)[target]
    end
  end
end
