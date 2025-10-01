class AddWithdrawnDeferredToTrainingPeriods < ActiveRecord::Migration[8.0]
  def change
    create_enum :api_withdrawal_reasons, %w[
      left-teaching-profession
      moved-school
      mentor-no-longer-being-mentor
      switched-to-school-led
      other
    ]

    create_enum :api_deferral_reasons, %w[
      bereavement
      long-term-sickness
      parental-leave
      career-break
      other
    ]

    change_table :training_periods, bulk: true do |t|
      t.date :api_deferred_at
      t.enum :api_deferral_reason, enum_type: :api_deferral_reasons
      t.date :api_withdrawn_at
      t.enum :api_withdrawal_reason, enum_type: :api_withdrawal_reasons
    end
  end
end
