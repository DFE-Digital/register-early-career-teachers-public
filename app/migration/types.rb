module Types
  # FIXME: these :id fields are from ECF1, rename them to :ecf1_id so it's clear
  AppropriateBodyData = Data.define(:id, :name)
  DeliveryPartnerInfo = Data.define(:id, :name)
  LeadProviderInfo = Data.define(:id, :name)
  SchoolData = Data.define(:urn, :name)
  ScheduleInfo = Data.define(:schedule_id, :identifier, :name, :cohort_year)
end
