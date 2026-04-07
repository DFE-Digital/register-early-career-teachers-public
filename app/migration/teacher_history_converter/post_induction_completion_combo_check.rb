class TeacherHistoryConverter::PostInductionCompletionComboCheck
  CSV_DATA_PATH = Rails.root.join("app/migration/csv/post_induction_completion_combos_to_keep.csv")

  attr_reader :profile_id, :lead_provider_id, :cohort_year, :csv_path

  def initialize(profile_id:, lead_provider_id:, cohort_year:, csv_path: CSV_DATA_PATH)
    @profile_id = profile_id
    @lead_provider_id = lead_provider_id
    @cohort_year = cohort_year
    @csv_path = csv_path
  end

  def keep?
    combos_to_keep.find {
      it[:participant_profile_id] == profile_id &&
        it[:lead_provider_id] == lead_provider_id &&
        it[:cohort_year] == cohort_year
    }.present?
  end

private

  def combos_to_keep
    @combos_to_keep ||= CSV.table(csv_path)
  end
end
