RSpec.describe "schools/register_mentor_wizard/programme_choices.html.erb" do
  include SchoolPartnershipHelpers

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school)  { FactoryBot.create(:school) }
  let(:contract_period) { FactoryBot.create(:contract_period, :current) }

  let(:school_partnership) do
    make_partnership_for(school, contract_period, lead_provider_name: "Naruto Ninja Academy")
  end

  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:) }

  let!(:training_period) do
    FactoryBot.create(:training_period,
                      :provider_led,
                      :ongoing,
                      ect_at_school_period:,
                      school_partnership:)
  end

  let(:store) do
    FactoryBot.build(:session_repository,
                     trn: "0000007",
                     trs_first_name: "Sasuke",
                     trs_last_name: "Uchiha",
                     change_name: "no",
                     corrected_name: nil,
                     ect_id: ect_at_school_period.id)
  end

  let(:wizard) do
    FactoryBot.build(:register_mentor_wizard,
                     current_step: :programme_choices,
                     ect_id: ect_at_school_period.id,
                     store:)
  end

  let(:mentor) { wizard.mentor }

  before do
    assign(:wizard, wizard)
    assign(:mentor, mentor)
    assign(:ect_name, "Naruto Uzumaki")
  end

  it "always shows the lead provider row" do
    render
    expect(rendered).to have_element(:dt, text: "Lead provider")
    expect(rendered).to have_element(:dd, text: "Naruto Ninja Academy")
  end

  context "when mentor has expression_of_interest?" do
    before do
      allow(mentor).to receive(:expression_of_interest?).and_return(true)
      render
    end

    it "shows the explanatory text" do
      expect(rendered).to have_text(
        "Naruto Ninja Academy will confirm if they’ll be working with your school and which delivery partner will deliver training events."
      )
    end
  end

  context "when mentor does not have expression_of_interest?" do
    before do
      allow(mentor).to receive(:expression_of_interest?).and_return(false)
      render
    end

    it "does not show explanatory text" do
      expect(rendered).not_to have_text("will confirm if they’ll be working with your school")
    end
  end
end
