module Types
  AppropriateBodyData = Data.define(:ecf1_id, :name)
  DeliveryPartnerInfo = Data.define(:ecf1_id, :name)
  LeadProviderInfo = Data.define(:ecf1_id, :name)
  SchoolData = Data.define(:urn, :name) do
    def ecf2_school = GIAS::School.find_by!(urn:).school
  end
  ScheduleInfo = Data.define(:schedule_id, :identifier, :name, :cohort_year)
end
