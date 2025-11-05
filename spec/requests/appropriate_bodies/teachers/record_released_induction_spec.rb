RSpec.describe "Appropriate body releasing an ECT" do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  let!(:induction_period) do
    FactoryBot.create(:induction_period, :ongoing,
                      teacher:,
                      appropriate_body_period:)
  end

  describe "GET /appropriate-body/teachers/:id/release/new" do
    context "when not signed in" do
      it "redirects to the root page" do
        get("/appropriate-body/teachers/#{teacher.id}/release/new")

        expect(response).to redirect_to(root_url)
      end
    end

    context "when signed in as an appropriate body user" do
      before do
        sign_in_as(:appropriate_body_user, appropriate_body: appropriate_body_period)
      end

      context "and a teacher actively training" do
        it "renders" do
          get("/appropriate-body/teachers/#{teacher.id}/release/new")

          expect(response).to be_successful
        end
      end
    end
  end

  describe "POST /appropriate-body/teachers/:id/release" do
    let(:params) do
      {
        appropriate_bodies_record_release: {
          finished_on: Date.current,
          number_of_terms: 3
        }
      }
    end

    context "when not signed in" do
      it "redirects to the root page" do
        post("/appropriate-body/teachers/#{teacher.id}/release", params:)

        expect(response).to redirect_to(root_url)
      end
    end

    context "when signed in as an appropriate body user" do
      before do
        sign_in_as(:appropriate_body_user, appropriate_body: appropriate_body_period)

        post("/appropriate-body/teachers/#{teacher.id}/release", params:)
      end

      context "with valid params" do
        it "releases the induction and redirects" do
          expect(induction_period.reload).to have_attributes(
            outcome: nil,
            finished_on: Date.current,
            number_of_terms: 3
          )

          expect(response).to redirect_to("/appropriate-body/teachers/#{teacher.id}/release")
        end

        context "with missing params" do
          let(:params) do
            {
              appropriate_bodies_record_release: {
                finished_on: nil,
                number_of_terms: nil
              }
            }
          end

          it "renders errors" do
            expect(response.body).to include("There is a problem")
            expect(response.body).to include("Enter a finish date")
            expect(response.body).to include("Enter a number of terms")
          end
        end

        context "with invalid params" do
          let(:params) do
            {
              appropriate_bodies_record_release: {
                finished_on: induction_period.started_on - 1.month,
                number_of_terms: 16.99,
              }
            }
          end

          it "renders errors" do
            expect(response.body).to include("There is a problem")
            expect(response.body).to include("The end date must be later than the start date")
            expect(response.body).to include("Number of terms must be between 0 and 16")
          end
        end
      end
    end
  end
end
