RSpec.describe "View failed parity checks" do
  before do
    sign_in_as_dfe_user(role: :admin)
    allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: true })
  end

  scenario "Viewing failed parity checks" do
    FactoryBot.create_list(:parity_check_run, 2, :failed)

    page.goto(new_migration_parity_check_path)

    expect(page.get_by_role("heading", name: "Failed runs")).to be_visible
    expect(page.get_by_text("2 runs failed")).to be_visible

    details_link = page.get_by_role("link", name: "View failed jobs for more details")

    expect(details_link).to be_visible
    expect(details_link).to have_attribute("href", admin_mission_control_jobs.application_jobs_path(application_id: :registerearlycareerteachers, status: :failed))
  end
end
