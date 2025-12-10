module Types
  AppropriateBodyData = Data.define(:id, :name)
  DeliveryPartner = Data.define(:id, :name)
  LeadProvider = Data.define(:id, :name)
  SchoolData = Data.define(:urn, :name)
  ScheduleInfo = Data.define(:schedule_id, :identifier, :name, :cohort_year)
end
