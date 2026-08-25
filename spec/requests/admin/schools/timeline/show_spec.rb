describe "Admin::Schools::TimelineController" do
  let(:title_suffix) { "- Register early career teachers - GOV.UK" }
  let(:school_name) { "Some School" }
  let(:gias_school) { FactoryBot.create(:gias_school, name: school_name) }
  let(:school) { FactoryBot.create(:school, gias_school:) }

  include_context "sign in as DfE user"

  describe "GET /admin/schools/:urn/timeline" do
    it "displays the school name in the title" do
      get "/admin/schools/#{school.urn}/timeline"

      expect(response.body).to match("<title>#{school_name} #{title_suffix}</title>")
    end

    it "uses Events::List to retrieve events in chronological order" do
      events_list = double(Events::List, for_school: [])
      allow(Events::List).to receive(:new).and_return(events_list)

      get "/admin/schools/#{school.urn}/timeline"

      expect(events_list).to have_received(:for_school).with(school).once
    end
  end
end
