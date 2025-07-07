RSpec.feature "Admin manages ECT extensions", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let!(:teacher) { create(:teacher, trs_first_name: "Sarah", trs_last_name: "Connor", trs_qts_awarded_on: 2.years.ago) }
  let!(:induction_period) { create(:induction_period, teacher:) }

  before do
    sign_in_as_dfe_user(role: :admin, user: admin_user)
    page.goto admin_teacher_path(teacher)
  end

  scenario "Admin can see extension links on ECT page" do
    expect(page.get_by_text("Sarah Connor")).to be_visible
    expect(page.get_by_text("Induction summary")).to be_visible
    expect(page.locator(".govuk-summary-list__key:has-text('Extensions')")).to be_visible
    expect(page.get_by_role('link', name: 'Add extensions')).to be_visible
  end

  scenario "Admin adds an extension for an ECT" do
    page.get_by_role('link', name: 'Add extensions').click
    expect(page).to have_url(admin_teacher_extensions_path(teacher))
    expect(page.get_by_role('heading', name: "Extensions")).to be_visible

    page.get_by_role('link', name: 'Add extension').click
    expect(page).to have_url(new_admin_teacher_extension_path(teacher))

    expect(page.get_by_role('heading', name: "Add an Extension to an ECT's induction")).to be_visible
    page.get_by_label("How many additional terms of induction do you need to add?").fill("1.5")
    page.get_by_role('button', name: 'Add extension').click

    expect(page).to have_url(admin_teacher_path(teacher))
    expect(page.get_by_text("Extension was successfully added.")).to be_visible
    expect(page.get_by_text("Sarah Connor")).to be_visible
    page.get_by_role('link', name: 'View extensions').click
    expect(page).to have_url(admin_teacher_extensions_path(teacher))
    expect(page.get_by_role('heading', name: "Extensions")).to be_visible
    expect(page.get_by_text("1.5 terms")).to be_visible
  end

  context "when an extension exists" do
    let!(:existing_extension) { create(:induction_extension, teacher:, number_of_terms: 1.0) }

    before do
      page.goto admin_teacher_path(teacher)
      page.get_by_role('link', name: 'View extensions').click
    end

    scenario "Admin edits an existing extension for an ECT" do
      expect(page).to have_url(admin_teacher_extensions_path(teacher))
      expect(page.get_by_role('heading', name: "Extensions")).to be_visible
      expect(page.get_by_text("1.0 terms")).to be_visible
      page.get_by_role('link', name: 'Edit').click
      expect(page).to have_url(edit_admin_teacher_extension_path(teacher, existing_extension))

      expect(page.get_by_role('heading', name: "Edit extension")).to be_visible
      page.get_by_label("How many additional terms of induction do you need to add?").fill("2.0")
      page.get_by_role('button', name: 'Update extension').click

      expect(page).to have_url(admin_teacher_path(teacher))
      expect(page.get_by_text("Extension was successfully updated.")).to be_visible
      expect(page.get_by_text("Sarah Connor")).to be_visible
      page.get_by_role('link', name: 'View extensions').click
      expect(page).to have_url(admin_teacher_extensions_path(teacher))
      expect(page.get_by_role('heading', name: "Extensions")).to be_visible
      expect(page.get_by_text("2.0 terms")).to be_visible
    end

    scenario "Admin deletes an existing extension for an ECT" do
      expect(page).to have_url(admin_teacher_extensions_path(teacher))
      expect(page.get_by_text("1.0 terms")).to be_visible
      expect(page.get_by_role('heading', name: "Extensions")).to be_visible
      page.get_by_role('link', name: 'Delete').click
      expect(page).to have_url(confirm_delete_admin_teacher_extension_path(teacher, existing_extension))

      expect(page.get_by_role('heading', name: "Are you sure you want to delete this extension?")).to be_visible
      page.get_by_role('button', name: 'Confirm deletion').click

      expect(page).to have_url(admin_teacher_path(teacher))
      expect(page.get_by_text("Extension was successfully deleted.")).to be_visible
      expect(page.get_by_text("Sarah Connor")).to be_visible
      page.get_by_role('link', name: 'Add extensions').click
      expect(page).to have_url(admin_teacher_extensions_path(teacher))
      expect(page.get_by_role('heading', name: "Extensions")).to be_visible
      expect(page.get_by_text("1.0 terms")).not_to be_visible
      expect(page.get_by_text("No extensions have been added yet.")).to be_visible
    end
  end
end
