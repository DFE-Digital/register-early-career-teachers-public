RSpec.describe 'Create mentorship of an ECT to a mentor' do
  include ActionView::Helpers::SanitizeHelper

  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school:) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:) }
  let(:school) { FactoryBot.create(:school, :independent) }

  before do
    allow(Rails.application.config).to receive(:enable_schools_interface).and_return(true)
  end

  describe 'GET /school/ects/:id/mentorship/new' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/school/ects/#{ect_at_school_period.id}/mentorship/new")
        expect(response).to redirect_to(root_url)
      end
    end

    context 'when signed in as school user' do
      before do
        sign_in_as(:school_user, school:, method: :dfe_sign_in)
      end

      it 'instantiates a new Schools::AssignMentorForm and renders the page' do
        allow(Schools::AssignMentorForm).to receive(:new).and_call_original

        get("/school/ects/#{ect_at_school_period.id}/mentorship/new")

        expect(response).to be_successful
        expect(Schools::AssignMentorForm).to have_received(:new).with(ect: ect_at_school_period).once
      end
    end
  end

  describe 'POST /school/ects/:id/mentorship' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        post("/school/ects/#{ect_at_school_period.id}/mentorship")
        expect(response).to redirect_to(root_url)
      end
    end

    context 'when signed in as school user' do
      before do
        sign_in_as(:school_user, school:)
      end

      context 'when the option selected by the user is to create a new mentor' do
        let(:params) { { schools_assign_mentor_form: { mentor_id: '0' } } }

        it 'redirects to the start of the wizard to add a new mentor to the school' do
          post("/school/ects/#{ect_at_school_period.id}/mentorship", params:)
          expect(response).to redirect_to(schools_register_mentor_wizard_start_url(ect_id: ect_at_school_period.id))
        end
      end

      context 'when an invalid mentor has been selected for the ect mentorship' do
        let(:params) { { schools_assign_mentor_form: { mentor_id: mentor.id.next } } }

        it 'renders the form again for the user to select a different option' do
          allow(Schools::AssignMentorForm).to receive(:new).and_call_original

          post("/school/ects/#{ect_at_school_period.id}/mentorship", params:)

          expect(response).to be_successful
          expect(Schools::AssignMentorForm).to have_received(:new).with(ect: ect_at_school_period, mentor_id: mentor.id.next.to_s).once
          expect(sanitize(response.body)).to include("Who will mentor #{Teachers::Name.new(ect_at_school_period.teacher).full_name}?")
        end
      end

      context 'when a valid mentor has been selected for the school led ect mentorship' do
        before do
          FactoryBot.create(:training_period, :ongoing, :school_led, ect_at_school_period:)
        end

        let(:params) { { schools_assign_mentor_form: { mentor_id: mentor.id } } }
        let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school:) }

        it 'creates the mentorship and redirects the user to the confirmation page' do
          allow(Schools::AssignMentorForm).to receive(:new).and_call_original

          post("/school/ects/#{ect_at_school_period.id}/mentorship", params:)

          expect(Schools::AssignMentorForm).to have_received(:new).with(ect: ect_at_school_period, mentor_id: mentor.id.to_s).once
          expect(ECTAtSchoolPeriods::Mentorship.new(ect_at_school_period).current_mentor).to eq(mentor)
          expect(response).to redirect_to(confirmation_schools_ect_mentorship_url(ect_id: ect_at_school_period.id))
        end
      end

      context 'provider led ECT mentorship' do
        before do
          FactoryBot.create(:training_period, :ongoing, :provider_led, ect_at_school_period:)
        end

        let(:params) { { schools_assign_mentor_form: { mentor_id: mentor.id } } }
        let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school:) }

        context 'when the mentor is eligible for funding' do
          before do
            allow(Teachers::MentorFundingEligibility).to receive(:new)
              .with(trn: mentor.teacher.trn)
              .and_return(instance_double(Teachers::MentorFundingEligibility, eligible?: true))

            post("/school/ects/#{ect_at_school_period.id}/mentorship", params:)
          end

          it 'redirects the user to the assign existing mentor wizard' do
            expect(response).to redirect_to(
              schools_assign_existing_mentor_wizard_review_mentor_eligibility_path
            )
          end
        end

        context 'when the mentor is not eligible for funding' do
          before do
            allow(Schools::AssignMentorForm).to receive(:new).and_call_original
            allow(Teachers::MentorFundingEligibility).to receive(:new)
              .with(trn: mentor.teacher.trn)
              .and_return(instance_double(Teachers::MentorFundingEligibility, eligible?: false))

            post("/school/ects/#{ect_at_school_period.id}/mentorship", params:)
          end

          it 'creates the mentorship and redirects the user to the confirmation page' do
            expect(Schools::AssignMentorForm).to have_received(:new).with(ect: ect_at_school_period, mentor_id: mentor.id.to_s).once
            expect(ECTAtSchoolPeriods::Mentorship.new(ect_at_school_period).current_mentor).to eq(mentor)
            expect(response).to redirect_to(confirmation_schools_ect_mentorship_path(ect_id: ect_at_school_period.id))
          end
        end

        context 'when no mentor_at_school_period is found' do
          let(:params) { { schools_assign_mentor_form: { mentor_id: 'non-existent' } } }

          before { post("/school/ects/#{ect_at_school_period.id}/mentorship", params:) }

          it 'redirects to the new form again' do
            expect(response).to have_http_status(:ok)
            expect(response.body).to include('Who will mentor')
          end
        end
      end
    end
  end

  describe 'GET /school/ects/:id/mentorship/confirmation' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/school/ects/#{ect_at_school_period.id}/mentorship/confirmation")
        expect(response).to redirect_to(root_url)
      end
    end

    context 'when signed in as school user' do
      let(:author) { FactoryBot.create(:school_user, school_urn: school.urn) }

      before do
        sign_in_as(:school_user, school:)
      end

      it 'instantiates a new Schools::AssignMentorForm and renders the page' do
        Schools::AssignMentor.new(ect: ect_at_school_period, mentor:, author:).assign!
        allow(Schools::AssignMentorForm).to receive(:new).and_call_original

        get("/school/ects/#{ect_at_school_period.id}/mentorship/confirmation")

        expect(response).to be_successful
        expect(sanitize(response.body)).to include("You've assigned #{Teachers::Name.new(mentor.teacher).full_name} as a mentor")
      end
    end
  end
end
