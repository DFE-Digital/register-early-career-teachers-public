RSpec.describe "View pending and in-progress parity checks" do
  include ActionView::Helpers::DateHelper

  before do
    sign_in_as_dfe_user(role: :admin)
    allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: true })
  end

  scenario "Viewing the in-progress parity check" do
    run = create(:parity_check_run, :in_progress, requests: [])
    create(:parity_check_request, :pending, run:)
    create(:parity_check_request, :queued, run:)
    create(:parity_check_request, :in_progress, run:)
    create(:parity_check_request, :completed, run:)

    page.goto(new_migration_parity_check_path)

    expect(page.get_by_text("In-progress run")).to be_visible
    expect(page.get_by_text("Run ##{run.id}")).to be_visible
    expect(page.get_by_text("25%")).to be_visible
    expect(page.locator('progress[value="25"]')).to be_visible
  end

  scenario "Viewing the pending parity checks" do
    run = create(:parity_check_run, :in_progress, started_at: 1.hour.ago, requests: [])
    create(:parity_check_request, :in_progress, run:)
    create(:parity_check_request, :completed, run:)

    pending_run_1 = travel_to(1.hour.ago) { create(:parity_check_run, :pending) }
    pending_run_2 = travel_to(25.minutes.ago) { create(:parity_check_run, :pending) }
    pending_run_3 = travel_to(3.minutes.ago) { create(:parity_check_run, :pending) }
    pending_runs = [pending_run_1, pending_run_2, pending_run_3]

    page.goto(new_migration_parity_check_path)

    expect(page.get_by_text("Pending runs")).to be_visible
    expect(page.get_by_text("⏱️ The next run will start in about 2 hours")).to be_visible

    pending_runs.each do |run|
      expect(page.get_by_text("Run ##{run.id}")).to be_visible
      expect(page.get_by_text("Created #{time_ago_in_words(run.created_at)} ago")).to be_visible
    end
  end
end
