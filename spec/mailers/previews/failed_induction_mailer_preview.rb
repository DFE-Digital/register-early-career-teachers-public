class FailedInductionMailerPreview < ActionMailer::Preview
  def tra_notification
    FailedInductionMailer.tra_notification(induction_period: example_failed_induction_period)
  end

private

  def example_failed_induction_period
    teacher = FactoryBot.build(:teacher, trn: "0000016", trs_first_name: "Imogen", trs_last_name: "Stubbs")
    appropriate_body_period = FactoryBot.build(:appropriate_body_period, name: "Golden Leaf Teaching School Hub")

    FactoryBot.build(:induction_period,
                     teacher:, appropriate_body_period:,
                     outcome: :fail, fail_confirmation_sent_on: 2.days.ago)
  end
end
