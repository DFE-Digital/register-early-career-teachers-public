class AddWithdrawnDeferredToTrainingPeriods < ActiveRecord::Migration[8.0]
  def change
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
      t.datetime :deferred_at
      t.enum :deferral_reason, enum_type: :deferral_reasons
      t.datetime :withdrawn_at
      t.enum :withdrawal_reason, enum_type: :withdrawal_reasons
    end
  end
end
