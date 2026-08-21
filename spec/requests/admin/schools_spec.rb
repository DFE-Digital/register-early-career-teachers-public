RSpec.describe "Admin::Schools", type: :request do
  let(:school) { FactoryBot.create(:school) }

  describe "GET /admin/schools" do
    before { school }

    it "redirects to sign in path when not authenticated" do
      get admin_schools_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get admin_schools_path
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      it "lists the schools" do
        get admin_schools_path
        expect(response.body).to include(school.name)
      end

      it "allows searching for schools" do
        get admin_schools_path(q: school.name.split(" ").first)
        expect(response.body).to include(school.name)
      end
    end
  end

  describe "GET /admin/schools/:urn" do
    it "redirects to sign in path when not authenticated" do
      get admin_school_path(school.urn)
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get admin_school_path(school.urn)
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      it "redirects to overview page" do
        get admin_school_path(school.urn)
        expect(response).to redirect_to(admin_school_overview_path(school.urn))
      end

      it "returns 404 when school not found" do
        get admin_school_overview_path("nonexistent")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /admin/schools/:urn/overview" do
    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      it "returns successful response and renders the overview template" do
        get admin_school_overview_path(school.urn)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(school.name)
        expect(response.body).to include("URN: #{school.urn}")
      end

      it "includes secondary navigation" do
        get admin_school_overview_path(school.urn)

        expect(response.body).to include("x-govuk-secondary-navigation")
        expect(response.body).to include("Overview")
        expect(response.body).to include("Teachers")
        expect(response.body).to include("Partnerships")
      end
    end
  end

  describe "GET /admin/schools/:urn/teachers" do
    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      it "returns successful response and renders the teachers template" do
        get admin_school_teachers_path(school.urn)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(school.name)
        expect(response.body).to include("URN: #{school.urn}")
      end

      context "when school has teachers" do
        let(:teacher) { FactoryBot.create(:teacher) }

        before do
          FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher:)
        end

        it "displays the teacher" do
          get admin_school_teachers_path(school.urn)

          expect(Capybara.string(response.body)).to have_link(
            Teachers::Name.new(teacher).full_name,
            href: admin_teacher_path(teacher)
          )
        end

        it "keeps the teachers navigation item current when filtered" do
          get admin_school_teachers_path(school.urn, role: "mentor")

          expect(Capybara.string(response.body)).to have_css(
            "a[aria-current='page']",
            text: "Teachers"
          )
        end

        it "links to the unfiltered schools index when searching for a teacher" do
          get admin_school_teachers_path(school.urn, q: teacher.trn)

          breadcrumbs = Capybara.string(response.body).find(".govuk-breadcrumbs")

          expect(breadcrumbs.find_link("Schools")[:href]).to eq(admin_schools_path)
        end
      end
    end
  end

  describe "GET /admin/schools/:urn/partnerships" do
    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      it "returns successful response and renders the partnerships template" do
        get admin_school_partnerships_path(school.urn)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(school.name)
        expect(response.body).to include("URN: #{school.urn}")
      end
    end
  end
end
