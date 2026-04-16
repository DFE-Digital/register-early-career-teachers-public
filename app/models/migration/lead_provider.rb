module Migration
  class LeadProvider < Migration::Base
    AMBITION = "c3bc3cee-a636-42d6-8324-c033a6c38d31"
    BPN = "da470c27-05a6-4f5b-b9a9-58b04bfcc408"
    CAPITA = "7a6753ef-6bb1-4fb3-ba93-fcbf3b20541b"
    EDT = "9f0a1bdd-b9af-4603-abfd-c1af01aded76"
    NIOT = "82bfbad3-349f-44fb-bb60-621eab1b349b"
    UCL = "3d7d8c90-a5a3-4838-84b2-563092bf87ee"
    TEACHFIRST = "99317668-2942-4292-a895-fdb075af067b"

    has_many :partnerships
    has_and_belongs_to_many :cohorts
    belongs_to :cpd_lead_provider
  end
end
