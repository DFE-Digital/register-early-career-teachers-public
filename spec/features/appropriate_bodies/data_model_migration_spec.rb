RSpec.describe "Migrating authenticated Appropriate Body Period users" do
  context "when no School records exist" do
    describe "after authentication" do
      let(:appropriate_body_period) do
        FactoryBot.create(:appropriate_body, name: "Valid AB")
      end

      it "does not migrate data" do
        expect {
          sign_in_as_appropriate_body_user(appropriate_body: appropriate_body_period)
        }.not_to change(DfESignInOrganisation, :count)
      end
    end
  end

  context "when School records exist" do
    before do
      FactoryBot.create(:gias_school, :with_school, :eligible_type, :in_england,
                        name: "Lead School",
                        urn: 123_456)
    end

    describe "after authentication" do
      let(:appropriate_body_period) do
        FactoryBot.create(:appropriate_body, :national)
      end

      it "migrates data" do
        expect {
          sign_in_as_appropriate_body_user(appropriate_body: appropriate_body_period)
        }.to change(DfESignInOrganisation, :count).by(1)
      end

      it "updates the login timestamps on subsequent logins" do
        sign_in_as_appropriate_body_user(appropriate_body: appropriate_body_period)
        dsi = DfESignInOrganisation.first

        first_login_time = dsi.last_authenticated_at

        travel 2.hours do
          sign_in_as_appropriate_body_user(appropriate_body: appropriate_body_period)
          dsi.reload
          expect(dsi.last_authenticated_at).to be > first_login_time
        end
      end

      context "when Appropriate Body is a national body (ISTIP or ESP)" do
        it "links AppropriateBodyPeriod to AppropriateBody" do
          expect {
            sign_in_as_appropriate_body_user(appropriate_body: appropriate_body_period)
          }.to change(AppropriateBody, :count).by(1)

          appropriate_body_period.reload
          expect(appropriate_body_period.appropriate_body.name).to eq(appropriate_body_period.name)
          expect(appropriate_body_period.appropriate_body.lead_school).to be_nil
        end
      end

      context "when AppropriateBodyPeriod is a teaching school hub (regional)" do
        let(:appropriate_body_period) do
          FactoryBot.create(:appropriate_body, :teaching_school_hub)
        end
        let(:school) { School.first }

        it "links AppropriateBodyPeriod to AppropriateBody and to a leading School" do
          expect {
            sign_in_as_teaching_school_hub(appropriate_body: appropriate_body_period, school:)
          }.to change(AppropriateBody, :count).by(1)

          appropriate_body_period.reload
          expect(appropriate_body_period.appropriate_body.name).to eq(appropriate_body_period.name)
          expect(appropriate_body_period.appropriate_body.lead_school).to eq(school)
        end
      end
    end
  end
end
