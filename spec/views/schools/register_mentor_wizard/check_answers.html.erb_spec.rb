RSpec.describe "schools/register_mentor_wizard/check_answers.html.erb" do
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "FraggleRock") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, school: ect.school) }

  let(:teacher) do
    FactoryBot.create(:teacher, trn: "1234568")
  end

  let(:ect) do
    FactoryBot.create(:ect_at_school_period, :ongoing, teacher:)
  end

  let!(:training_period) do
    FactoryBot.create(:training_period, :ongoing, ect_at_school_period: ect, school_partnership:)
  end

  let(:store) do
    FactoryBot.build(:session_repository,
                     trn: "1234567",
                     trs_first_name: "John",
                     trs_last_name: "Wayne",
                     change_name: "yes",
                     corrected_name: "Jim Wayne",
                     email: "john.wayne@example.com")
  end

  let(:wizard) do
    FactoryBot.build(:register_mentor_wizard, current_step: :check_answers, ect_id: ect.id, store:)
  end

  let(:mentor) { wizard.mentor }

  before do
    allow(mentor).to receive(:ect_lead_provider_invalid?).and_return(false)
    assign(:wizard, wizard)
    assign(:mentor, mentor)
    assign(:ect_name, "Michael Dixon")
  end

  describe "page title" do
    let(:title) { sanitize(view.content_for(:page_title)) }

    before { render }

    it { expect(title).to eql("Check your answers and confirm mentor details") }
  end

  describe "back link" do
    let(:backlink) { view.content_for(:backlink_or_breadcrumb) }

    context "without exemption" do
      before { render }

      it do
        expect(backlink).to have_link("Back", href: schools_register_mentor_wizard_review_mentor_eligibility_path)
      end
    end

    context "with legacy exemption" do
      before do
        FactoryBot.create(:teacher, :early_roll_out_mentor, trn: mentor.trn)
        render
      end

      it { expect(backlink).to have_link("Back", href: schools_register_mentor_wizard_email_address_path) }
    end

    context "with existing training exemption" do
      before do
        FactoryBot.create(:teacher,
                          trn: mentor.trn,
                          mentor_became_ineligible_for_funding_on: Time.zone.today,
                          mentor_became_ineligible_for_funding_reason: "completed_declaration_received")

        render
      end

      it { expect(backlink).to have_link("Back", href: schools_register_mentor_wizard_email_address_path) }
    end
  end

  describe "summary" do
    context "with school led ect" do
      let(:ect) do
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher:)
      end

      let!(:training_period) do
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period: ect)
      end

      it "hides lead provider" do
        expect(rendered).not_to have_element(:dt, text: "Lead provider")
      end
    end

    context "without exemption" do
      before { render }

      it "displays TRN, Name and Email address, lead provider" do
        expect(rendered).to have_element(:dt, text: "Teacher reference number (TRN)")
        expect(rendered).to have_element(:dd, text: "1234567")
        expect(rendered).to have_element(:dt, text: "Name")
        expect(rendered).to have_element(:dd, text: "Jim Wayne")
        expect(rendered).to have_element(:dt, text: "Email address")
        expect(rendered).to have_element(:dd, text: "john.wayne@example.com")
      end
    end

    context "with legacy exemption" do
      before do
        FactoryBot.create(:teacher, :early_roll_out_mentor, trn: mentor.trn)
        render
      end

      it "hides lead provider" do
        expect(rendered).not_to have_element(:dt, text: "Lead provider")
        expect(rendered).not_to have_element(:dd, text: "FraggleRock")
      end
    end

    context "with existing training exemption" do
      before do
        FactoryBot.create(:teacher,
                          trn: mentor.trn,
                          mentor_became_ineligible_for_funding_on: Time.zone.today,
                          mentor_became_ineligible_for_funding_reason: "completed_declaration_received")

        render
      end

      it "hides lead provider" do
        expect(rendered).not_to have_element(:dt, text: "Lead provider")
        expect(rendered).not_to have_element(:dd, text: "FraggleRock")
      end
    end

    context "when mentor is provider-led and mentoring_at_new_school_only? is true" do
      before do
        allow(mentor).to receive_messages(provider_led_ect?: true, mentoring_at_new_school_only?: true, lead_provider:)
        render
      end

      it "shows the lead provider row" do
        expect(rendered).to have_element(:dt, text: "Lead provider")
        expect(rendered).to have_element(:dd, text: "FraggleRock")
        expect(rendered).to have_link("Change", href: schools_register_mentor_wizard_change_lead_provider_path)
      end
    end

    context "when mentoring_at_new_school_only? is false" do
      before do
        allow(mentor).to receive_messages(provider_led_ect?: true, mentoring_at_new_school_only?: false, lead_provider:, eligible_for_funding?: true)
        render
      end

      it "does not show the lead provider row" do
        expect(rendered).not_to have_element(:dt, text: "Lead provider")
        expect(rendered).not_to have_element(:dd, text: "FraggleRock")
        expect(rendered).not_to have_link("Change", href: schools_register_mentor_wizard_change_lead_provider_path)
      end
    end

    context "when mentoring_at_new_school_only? is not present" do
      before do
        allow(mentor).to receive_messages(provider_led_ect?: true, mentoring_at_new_school_only?: nil, lead_provider:, eligible_for_funding?: true)
        render
      end

      it "does not show the lead provider row" do
        expect(rendered).not_to have_element(:dt, text: "Lead provider")
        expect(rendered).not_to have_element(:dd, text: "FraggleRock")
        expect(rendered).not_to have_link("Change", href: schools_register_mentor_wizard_change_lead_provider_path)
      end
    end

    context "when eligible_for_funding? is false" do
      before do
        allow(mentor).to receive_messages(provider_led_ect?: true, mentoring_at_new_school_only?: true, lead_provider:, eligible_for_funding?: false)
        render
      end

      it "does not show the lead provider row" do
        expect(rendered).not_to have_element(:dt, text: "Lead provider")
        expect(rendered).not_to have_element(:dd, text: "FraggleRock")
        expect(rendered).not_to have_link("Change", href: schools_register_mentor_wizard_change_lead_provider_path)
      end
    end

    context "when eligible_for_funding? is true" do
      before do
        allow(mentor).to receive_messages(provider_led_ect?: true, mentoring_at_new_school_only?: true, lead_provider:, eligible_for_funding?: true)
        render
      end

      it "shows the lead provider row" do
        expect(rendered).to have_element(:dt, text: "Lead provider")
        expect(rendered).to have_element(:dd, text: "FraggleRock")
        expect(rendered).to have_link("Change", href: schools_register_mentor_wizard_change_lead_provider_path)
      end
    end

    context "when provider_led_ect? is false" do
      before do
        allow(mentor).to receive_messages(provider_led_ect?: false, mentoring_at_new_school_only?: true, lead_provider:)
        render
      end

      it "does not show the lead provider row" do
        expect(rendered).not_to have_element(:dt, text: "Lead provider")
      end
    end

    context "when mentoring_at_new_school_only is yes" do
      before do
        allow(mentor).to receive_messages(mentoring_at_new_school_only: "yes")
        render
      end

      it "shows the mentoring only at your school row with Yes and a Change link" do
        expect(rendered).to have_element(:dt, text: "Mentoring only at your school")
        expect(rendered).to have_element(:dd, text: "Yes")
        expect(rendered).to have_link(
          "Change mentoring only at your school",
          href: schools_register_mentor_wizard_mentoring_at_new_school_only_path
        )
      end
    end

    context "when mentoring_at_new_school_only is no" do
      before do
        allow(mentor).to receive_messages(mentoring_at_new_school_only: "no")
        render
      end

      it "shows the mentoring only at your school row with No and a Change link" do
        expect(rendered).to have_element(:dt, text: "Mentoring only at your school")
        expect(rendered).to have_element(:dd, text: "No")
        expect(rendered).to have_link(
          "Change mentoring only at your school",
          href: schools_register_mentor_wizard_mentoring_at_new_school_only_path
        )
      end
    end

    context "when mentoring_at_new_school_only is not present" do
      before do
        allow(mentor).to receive_messages(mentoring_at_new_school_only: nil)
        render
      end

      it "does not show the mentoring only at your school row" do
        expect(rendered).not_to have_element(:dt, text: "Mentoring only at your school")
        expect(rendered).not_to have_link(
          "Change mentoring only at your school",
          href: schools_register_mentor_wizard_mentoring_at_new_school_only_path
        )
      end
    end

    context "when ect lead provider is invalid" do
      before do
        allow(mentor).to receive_messages(
          provider_led_ect?: true,
          mentoring_at_new_school_only?: false,
          eligible_for_funding?: false,
          lead_provider: nil,
          ect_lead_provider: lead_provider,
          ect_lead_provider_invalid?: true
        )
        render
      end

      it "shows the lead provider row even if other conditions are false" do
        expect(rendered).to have_element(:dt, text: "Lead provider")
        expect(rendered).to have_element(:dd, text: "FraggleRock")
        expect(rendered).to have_link("Change", href: schools_register_mentor_wizard_change_lead_provider_path)
      end
    end

    context "when ect lead provider is valid" do
      before do
        allow(mentor).to receive_messages(
          provider_led_ect?: true,
          mentoring_at_new_school_only?: false,
          eligible_for_funding?: false,
          lead_provider: nil,
          ect_lead_provider: lead_provider,
          ect_lead_provider_invalid?: false
        )
        render
      end

      it "does not show the lead provider row" do
        expect(rendered).not_to have_element(:dt, text: "Lead provider")
        expect(rendered).not_to have_element(:dd, text: "FraggleRock")
      end
    end
  end

  it "includes an inset with the names of the mentor and ECT associated" do
    render
    expect(rendered).to have_selector(".govuk-inset-text", text: "Jim Wayne will mentor Michael Dixon", visible: :visible)
  end

  it "includes a Confirm details button that posts to the check answers page" do
    render
    expect(rendered).to have_button("Confirm details")
    expect(rendered).to have_selector("form[action='#{schools_register_mentor_wizard_check_answers_path}']")
  end

  it "has change links" do
    render
    expect(rendered).to have_link("Change", href: schools_register_mentor_wizard_change_mentor_details_path)
    expect(rendered).to have_link("Change", href: schools_register_mentor_wizard_change_email_address_path)
  end
end
