describe Navigation::Primary, type: :component do
  let(:instance) { Navigation::Primary.new(current_path:, current_user:) }

  let(:current_user) { FactoryBot.build(:dfe_user, role: :admin) }
  let(:current_path) { "/" }
  let(:current_user_type) { nil }

  describe "#govuk_header_arguments" do
    it "sets :service_url to the root path" do
      expect(instance.govuk_header_arguments.fetch(:service_url)).to eql("/")
    end

    it "sets :service_name to 'Register early career teachers'" do
      expect(instance.govuk_header_arguments.fetch(:service_name)).to eql("Register early career teachers")
    end

    it "sets :navigation_id to 'register-early-career-teachers-service-navigation-list'" do
      expect(instance.govuk_header_arguments.fetch(:navigation_id)).to eql("register-early-career-teachers-service-navigation-list")
    end

    describe "navigation items" do
      subject do
        instance
          .govuk_header_arguments
          .fetch(:navigation_items)
          .map { |item| item.values_at(:text, :href) }
          .to_h
      end

      context "when logged in as a dfe_staff_user" do
        let(:current_path) { "/admin" }

        let(:expected_admin_visible_items) do
          {
            "Teachers" => "/admin/teachers",
            "Schools" => "/admin/schools",
            "Organisations" => "/admin/organisations"
          }
        end

        let(:expected_user_manager_visible_items) do
          {
            **expected_admin_visible_items,
            "Users" => "/admin/users"
          }
        end

        let(:expected_finance_visible_items) do
          {
            **expected_admin_visible_items,
            "Finance" => "/admin/finance",
            "Users" => "/admin/users"
          }
        end

        context "when the user is a regular admin" do
          let(:current_user) { FactoryBot.build(:dfe_user, role: :admin) }

          it { is_expected.to eql(expected_admin_visible_items) }
        end

        context "when the user is a user manager" do
          let(:current_user) { FactoryBot.build(:dfe_user, role: :user_manager) }

          it { is_expected.to eql(expected_user_manager_visible_items) }
        end

        context "when the user is a finance manager" do
          let(:current_user) { FactoryBot.build(:dfe_user, role: :finance) }

          it { is_expected.to eql(expected_finance_visible_items) }
        end
      end

      context "when logged in as a school user" do
        let(:current_path) { "/school/home/ects" }
        let(:current_user) { FactoryBot.build(:school_user, :at_random_school) }
        let(:expected_visible_items) do
          { "ECTs" => "/school/home/ects", "Mentors" => "/school/home/mentors", "Induction tutor" => "/school/home/induction-tutor" }
        end

        it { is_expected.to eql(expected_visible_items) }
      end

      context "when logged in as a DfE staff user but impersonating a school user" do
        let(:school) { FactoryBot.create(:school) }
        let(:school_user) { FactoryBot.create(:user) }
        let(:current_path) { "/school/home/ects" }
        let(:current_user) { FactoryBot.build(:dfe_user_impersonating_school_user, email: school_user.email, school_urn: school.urn) }
        let(:expected_visible_items) do
          { "ECTs" => "/school/home/ects", "Mentors" => "/school/home/mentors", "Induction tutor" => "/school/home/induction-tutor" }
        end

        it { is_expected.to eql(expected_visible_items) }
      end

      context "when logged in as an appropriate body user" do
        let(:current_path) { "/appropriate-body/teachers" }
        let(:current_user) { FactoryBot.build(:appropriate_body_user, :at_random_appropriate_body) }

        it { is_expected.to be_empty }
      end

      context "when looking at the API guidance" do
        let(:current_path) { "/api/guidance" }
        let(:expected_visible_items) do
          {
            "Home" => "/api/guidance",
            "Swagger API documentation" => "/api/docs/v3",
            "Release notes" => "/api/guidance/release-notes",
            "Guidance" => "/api/guidance/guidance-for-lead-providers"
          }
        end

        it { is_expected.to eql(expected_visible_items) }
      end

      describe "Areas and sections" do
        describe "appropriate_body_user" do
          subject { instance.send(:items_by_area).fetch(:appropriate_body_user) }

          it { is_expected.to be_blank }
        end

        describe "dfe_staff_user" do
          subject { instance.send(:items_by_area).fetch(:dfe_staff_user) }

          it "has the correct nodes and paths" do
            expect(subject).to eql(
              [
                { text: "Teachers", href: "/admin/teachers", active_when: "/admin/teachers" },
                { text: "Schools", href: "/admin/schools", active_when: "/admin/schools" },
                { text: "Organisations", href: "/admin/organisations", active_when: "/admin/organisations" },
                { text: "Finance", href: "/admin/finance", active_when: "/admin/finance", if: :can_see_finance? },
                { text: "Users", href: "/admin/users", active_when: "/admin/users", if: :can_manage_users? }
              ]
            )
          end
        end

        describe "school_user" do
          subject { instance.send(:items_by_area).fetch(:school_user) }

          it "has the correct nodes and paths" do
            expect(subject).to eql(
              [
                { text: "ECTs", href: "/school/home/ects", active_when: "/school/ects" },
                { text: "Mentors", href: "/school/home/mentors", active_when: "/school/mentors" },
                { text: "Induction tutor", href: "/school/home/induction-tutor", active_when: "/school/induction-tutor" },
              ]
            )
          end
        end

        describe "api guidance" do
          subject { instance.send(:items_by_area).fetch(:api_guidance) }

          it "has the correct nodes and paths" do
            expect(subject).to eql(
              [
                { text: "Home", href: "/api/guidance" },
                { text: "Swagger API documentation", href: "/api/docs/v3", active_when: "/api/docs" },
                { text: "Release notes", href: "/api/guidance/release-notes", active_when: "/api/guidance/release-notes" },
                { text: "Guidance", href: "/api/guidance/guidance-for-lead-providers", active_when: "/api/guidance/guidance-for-lead-providers" },
              ]
            )
          end
        end
      end
    end

    describe "inverting the colours" do
      subject { Navigation::Primary.new(current_path:, current_user:, **inverse_kwarg).govuk_header_arguments.fetch(:inverse) }

      context "by default" do
        let(:inverse_kwarg) { {} }

        it { is_expected.to be(false) }
      end

      context "when true" do
        let(:inverse_kwarg) { { inverse: true } }

        it { is_expected.to be(true) }
      end

      context "when false" do
        let(:inverse_kwarg) { { inverse: false } }

        it { is_expected.to be(false) }
      end
    end
  end
end
