class TeacherHistoryConverter::CohortCutOffDate
  COHORT_2021_CUTOFF_DATE = Date.new(2024, 7, 31)
  COHORT_2022_CUTOFF_DATE = Date.new(2025, 7, 31)

  def cut_off_date_for(cohort_year:)
    case cohort_year
    when 2021
      Date.new(2024, 7, 31)
    when 2022
      Date.new(2025, 7, 31)
    end
  end
end
