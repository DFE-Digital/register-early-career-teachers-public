module Types
  AppropriateBodyData = Data.define(:ecf1_id, :name)
  DeliveryPartnerInfo = Data.define(:ecf1_id, :name)
  LeadProviderInfo = Data.define(:ecf1_id, :name)
  SchoolData = Struct.new("SchoolData", :urn, :name, :school_type_name) do
    def ecf2_school = GIAS::School.find_by!(urn:).school
  end
  ScheduleInfo = Data.define(:schedule_id, :identifier, :name, :cohort_year)
  TeacherData = Data.define(:trn, :api_mentor_training_record_id)
end
