RSpec.shared_context "it transfers an induction" do
  subject(:service) do
    described_class.new(from: current_appropriate_body, to: new_appropriate_body, on: cut_off_date)
  end

  let(:current_appropriate_body) { FactoryBot.create(:appropriate_body, name: "Current AB") }
  let(:new_appropriate_body) { FactoryBot.create(:appropriate_body, name: "New AB") }
  let(:cut_off_date) { Date.new(2024, 9, 1) }

  before do
    # Ignore - cut off occurs after induction
    # ========================================================================

    skip_pre_cut_off_induction = FactoryBot.create(:induction_period,
                                                   appropriate_body: current_appropriate_body,
                                                   started_on: 1.year.before(cut_off_date),
                                                   finished_on: 1.month.before(cut_off_date))

    FactoryBot.create(:event,
                      induction_period: skip_pre_cut_off_induction,
                      appropriate_body: skip_pre_cut_off_induction.appropriate_body,
                      teacher: skip_pre_cut_off_induction.teacher,
                      heading: "skip_pre_cut_off_induction: #{current_appropriate_body.name}")

    # Partial transfer - cut off occurs during induction
    # ========================================================================

    partial_completed_induction = FactoryBot.create(:induction_period,
                                                    appropriate_body: current_appropriate_body,
                                                    started_on: 1.year.before(cut_off_date),
                                                    finished_on: 1.week.ago)

    FactoryBot.create(:event,
                      induction_period: partial_completed_induction,
                      appropriate_body: partial_completed_induction.appropriate_body,
                      teacher: partial_completed_induction.teacher,
                      heading: "partial_completed_induction: #{current_appropriate_body.name}")

    partial_in_progress_induction = FactoryBot.create(:induction_period, :ongoing,
                                                      appropriate_body: current_appropriate_body,
                                                      started_on: 10.months.before(cut_off_date))

    FactoryBot.create(:event,
                      induction_period: partial_in_progress_induction,
                      appropriate_body: partial_in_progress_induction.appropriate_body,
                      teacher: partial_in_progress_induction.teacher,
                      heading: "partial_in_progress_induction: #{current_appropriate_body.name}")

    # Full transfer - cut off occurs before induction
    # ========================================================================

    full_completed_induction = FactoryBot.create(:induction_period,
                                                 appropriate_body: current_appropriate_body,
                                                 started_on: 1.day.after(cut_off_date),
                                                 finished_on: 1.day.ago)

    FactoryBot.create(:event,
                      induction_period: full_completed_induction,
                      appropriate_body: full_completed_induction.appropriate_body,
                      teacher: full_completed_induction.teacher,
                      heading: "full_completed_induction: #{current_appropriate_body.name}")

    full_in_progress_induction = FactoryBot.create(:induction_period, :ongoing,
                                                   appropriate_body: current_appropriate_body,
                                                   started_on: 1.week.after(cut_off_date))

    FactoryBot.create(:event,
                      induction_period: full_in_progress_induction,
                      appropriate_body: full_in_progress_induction.appropriate_body,
                      teacher: full_in_progress_induction.teacher,
                      heading: "full_in_progress_induction: #{current_appropriate_body.name}")
  end
end
