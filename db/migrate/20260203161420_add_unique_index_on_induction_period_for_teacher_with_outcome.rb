class AddUniqueIndexOnInductionPeriodForTeacherWithOutcome < ActiveRecord::Migration[8.0]
  def change
    duplicates = InductionPeriod
      .where.not(outcome: nil)
      .group(:teacher_id)
      .having("COUNT(*) > 1")
      .exists?

    raise "Cannot add unique index as there are multiple induction periods with outcomes for the same teacher" if duplicates

    add_index :induction_periods,
              :teacher_id,
              unique: true,
              where: "outcome IS NOT NULL",
              name: "index_induction_periods_one_outcome_per_teacher"
  end
end
