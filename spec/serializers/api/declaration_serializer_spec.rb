describe API::DeclarationSerializer, type: :serializer do
  include MentorshipPeriodHelpers

  subject(:response) do
    JSON.parse(described_class.render(declaration))
  end

  let(:declaration) { FactoryBot.create(:declaration) }
  let(:teacher) { declaration.training_period.teacher }
  let(:delivery_partner) { declaration.training_period.delivery_partner }
  let(:lead_provider) { declaration.training_period.lead_provider }
  let(:payment_statement) { declaration.payment_statement }
  let(:clawback_statement) { declaration.clawback_statement }
  let(:mentor_teacher) { declaration.mentorship_period.mentor.teacher }

  describe "core attributes" do
    it "serializes correctly" do
      expect(response["id"]).to be_present
      expect(response["id"]).to eq(declaration.api_id)
      expect(response["type"]).to eq("participant-declaration")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { response["attributes"] }

    it "serializes correctly" do
      expect(attributes["participant_id"]).to eq(teacher.api_id)
      expect(attributes["declaration_type"]).to eq(declaration.declaration_type)
      expect(attributes["declaration_date"]).to eq(declaration.declaration_date.utc.rfc3339)

      expect(attributes["updated_at"]).to eq(declaration.updated_at.utc.rfc3339)
      expect(attributes["created_at"]).to eq(declaration.created_at.utc.rfc3339)
      expect(attributes["delivery_partner_id"]).to eq(delivery_partner.api_id)
      expect(attributes["ineligible_for_funding_reason"]).to be_nil
      expect(attributes["statement_id"]).to be_nil
      expect(attributes["clawback_statement_id"]).to be_nil

      expect(attributes["mentor_id"]).to be_nil
      expect(attributes["evidence_held"]).to be_present
      expect(attributes["evidence_held"]).to eq(declaration.evidence_type)

      expect(attributes["lead_provider_name"]).to eq(lead_provider.name)
    end

    describe "course_identifier" do
      let(:declaration) { FactoryBot.create(:declaration, training_period:) }

      context "when ECT" do
        let(:training_period) { FactoryBot.create(:training_period, :for_ect) }

        it "serializes correctly" do
          expect(attributes["course_identifier"]).to eq("ecf-induction")
        end
      end

      context "when Mentor" do
        let(:training_period) { FactoryBot.create(:training_period, :for_mentor) }

        it "serializes correctly" do
          expect(attributes["course_identifier"]).to eq("ecf-mentor")
        end
      end
    end

    describe "state" do
      %i[no_payment eligible payable paid voided awaiting_clawback clawed_back].each do |status|
        context "when status is `#{status}`" do
          let(:declaration) { FactoryBot.create(:declaration, status) }

          it "serializes correctly" do
            expected_state = status.to_s
            expected_state = "submitted" if expected_state == "no_payment"

            expect(attributes["state"]).to eq(expected_state)
          end
        end
      end
    end

    describe "statement_id" do
      context "when declaration status is `paid`" do
        let(:declaration) { FactoryBot.create(:declaration, :paid) }

        it "serializes correctly" do
          expect(attributes["statement_id"]).to eq(payment_statement.api_id)
          expect(attributes["clawback_statement_id"]).to be_nil
        end
      end
    end

    describe "clawback_statement_id" do
      context "when declaration status is `clawed_back`" do
        let(:declaration) { FactoryBot.create(:declaration, :awaiting_clawback) }

        it "serializes correctly" do
          expect(attributes["statement_id"]).to eq(payment_statement.api_id)
          expect(attributes["clawback_statement_id"]).to eq(clawback_statement.api_id)
        end
      end
    end

    describe "mentor_id" do
      let(:mentee) { FactoryBot.create(:ect_at_school_period, :ongoing) }
      let(:training_period) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period: mentee) }
      let(:mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, school: mentee.school) }
      let!(:mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor:) }
      let(:declaration) { FactoryBot.create(:declaration, mentorship_period:, training_period:) }

      it "serializes correctly" do
        expect(attributes["mentor_id"]).to be_present
        expect(attributes["mentor_id"]).to eq(mentor_teacher.api_id)
      end
    end

    describe "uplift_paid" do
      before { allow(declaration).to receive(:uplift_paid?).and_return(true) }

      it "serializes correctly" do
        expect(attributes["uplift_paid"]).to be_present
        expect(attributes["uplift_paid"]).to be(true)
      end
    end
  end
end
