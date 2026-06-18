describe "Admin::Schools::OverviewsController" do
  let(:title_suffix) { "- Register early career teachers - GOV.UK" }
  let(:school_name) { "Some School" }
  let(:gias_school) { FactoryBot.create(:gias_school, name: school_name) }
  let(:school) { FactoryBot.create(:school, gias_school:) }

  include_context "sign in as DfE user"

  describe "GET /admin/schools/:urn/overview" do
    it "displays the school name in the title" do
      get "/admin/schools/#{school.urn}/overview"

      expect(response.body).to match("<title>#{school_name} #{title_suffix}</title>")
    end

    context "when the school name contains characters that need to be sanitized" do
      let(:school_name) { "All Saints' Infants & Junior School" }
      let(:sanitized_school_name) { "All Saints&#39; Infants &amp; Junior School" }

      it "displays the school name in the title" do
        get "/admin/schools/#{school.urn}/overview"

        expect(response.body).to match("<title>#{sanitized_school_name} #{title_suffix}</title>")
      end
    end
  end
end
