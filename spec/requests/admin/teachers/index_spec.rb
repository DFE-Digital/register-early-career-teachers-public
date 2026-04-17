RSpec.describe "Admin teachers index", type: :request do
  describe "GET /admin/teachers" do
    it "redirects to sign in path" do
      get "/admin/teachers"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get "/admin/teachers"
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      context "when a teacher has both ECT and mentor roles" do
        let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
        let!(:ect_contract_period) { FactoryBot.create(:contract_period, year: 2024) }
        let!(:mentor_contract_period) { FactoryBot.create(:contract_period, year: 2025) }
        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, :with_training_period, teacher:, contract_period: ect_contract_period) }
        let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, :with_training_period, teacher:, contract_period: mentor_contract_period) }

        it "renders role based rows with contract periods" do
          get "/admin/teachers"

          expect(response.status).to eq(200)
          expect(response.body.scan("Naruto Uzumaki").size).to eq(2)
          expect(response.body).to include("Early career teacher")
          expect(response.body).to include("Mentor")
          expect(response.body).to include("2024")
          expect(response.body).to include("2025")
        end
      end

      context "when a teacher has no role history" do
        let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki", trn: "1234567") }

        it "renders no role assigned" do
          get "/admin/teachers"

          expect(response.status).to eq(200)
          expect(response.body).to include("Naruto Uzumaki")
          expect(response.body).to include("1234567")
          expect(response.body).to include("No role assigned")
        end
      end

      context "with a search query" do
        context "when searching by name" do
          it "filters teachers by name" do
            teacher = FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki")
            other_teacher = FactoryBot.create(:teacher, trs_first_name: "Sasuke", trs_last_name: "Uchiha")

            FactoryBot.create(:induction_period, teacher:)
            FactoryBot.create(:induction_period, teacher: other_teacher)

            get "/admin/teachers", params: { q: "Naruto Uzumaki" }

            expect(response.status).to eq(200)
            expect(response.body).to include("Naruto Uzumaki")
            expect(response.body).not_to include("Sasuke Uchiha")
          end
        end

        context "when searching by TRN" do
          it "filters teachers by TRN" do
            teacher = FactoryBot.create(:teacher, trn: "1234567")
            other_teacher = FactoryBot.create(:teacher, trn: "7654321")

            FactoryBot.create(:induction_period, teacher:)
            FactoryBot.create(:induction_period, teacher: other_teacher)

            get "/admin/teachers", params: { q: "1234567" }

            expect(response.status).to eq(200)
            expect(response.body).to include("1234567")
            expect(response.body).not_to include("7654321")
          end
        end

        context "when searching by API participant ID" do
          let!(:teacher) { FactoryBot.create(:teacher, api_id: "123e4567-e89b-12d3-a456-426614174000") }
          let!(:other_teacher) { FactoryBot.create(:teacher, api_id: "999e4567-e89b-12d3-a456-426614174999") }
          let!(:teacher_contract_period) { FactoryBot.create(:contract_period, year: 2024) }
          let!(:other_teacher_contract_period) { FactoryBot.create(:contract_period, year: 2024) }
          let!(:teacher_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, :with_training_period, teacher:, contract_period: teacher_contract_period) }
          let!(:other_teacher_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, :with_training_period, teacher: other_teacher, contract_period: other_teacher_contract_period) }

          it "filters teachers by API participant ID" do
            get "/admin/teachers", params: { q: "4266141740" }

            expect(response.status).to eq(200)
            expect(response.body).to include(teacher.trn)
            expect(response.body).not_to include(other_teacher.trn)
          end
        end

        context "when the query generates an invalid tsquery" do
          it "returns successfully" do
            get "/admin/teachers", params: { q: "<?'" }

            expect(response.status).to eq(200)
            expect(response.body).to include("Teachers")
            expect(response.body).to include("There are no teachers that match your search.")
          end
        end

        context "when the search returns no teachers" do
          it "renders an empty state message" do
            get "/admin/teachers", params: { q: "No matches here" }

            expect(response.status).to eq(200)
            expect(response.body).to include("There are no teachers that match your search.")
          end
        end
      end
    end
  end
end
