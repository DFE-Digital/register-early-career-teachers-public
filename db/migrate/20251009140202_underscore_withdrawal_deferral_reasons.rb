class UnderscoreWithdrawalDeferralReasons < ActiveRecord::Migration[8.0]
  def up
    if TrainingPeriod.where.not(withdrawal_reason: nil).exists? || TrainingPeriod.where.not(deferral_reason: nil).exists?
      raise ActiveRecord::IrreversibleMigration, "Cannot change enum because the training_periods table contains data"
    end

    change_table :training_periods, bulk: true do |t|
      t.change :withdrawal_reason, :string
      t.change :deferral_reason, :string
    end

    drop_enum :withdrawal_reasons
    drop_enum :deferral_reasons

    create_enum :withdrawal_reasons, %w[
      left_teaching_profession
      moved_school
      mentor_no_longer_being_mentor
      switched_to_school_led
      other
    ]

    create_enum :deferral_reasons, %w[
      bereavement
      long_term_sickness
      parental_leave
      career_break
      other
    ]

    change_table :training_periods, bulk: true do |t|
      t.change :withdrawal_reason, :withdrawal_reasons, using: "withdrawal_reason::withdrawal_reasons"
      t.change :deferral_reason, :deferral_reasons, using: "deferral_reason::deferral_reasons"
    end
  end

  def down
    if TrainingPeriod.where.not(withdrawal_reason: nil).exists? || TrainingPeriod.where.not(deferral_reason: nil).exists?
      raise ActiveRecord::IrreversibleMigration, "Cannot revert enum because the training_periods table contains data"
    end

    change_table :training_periods, bulk: true do |t|
      t.change :withdrawal_reason, :string
      t.change :deferral_reason, :string
    end

    drop_enum :withdrawal_reasons
    drop_enum :deferral_reasons

    create_enum :withdrawal_reasons, %w[
      left-teaching-profession
      moved-school
      mentor-no-longer-being-mentor
      switched-to-school-led
      other
    ]

    create_enum :deferral_reasons, %w[
      bereavement
      long-term-sickness
      parental-leave
      career-break
      other
    ]

    change_table :training_periods, bulk: true do |t|
      t.change :withdrawal_reason, :withdrawal_reasons, using: "withdrawal_reason::withdrawal_reasons"
      t.change :deferral_reason, :deferral_reasons, using: "deferral_reason::deferral_reasons"
    end
  end
end
