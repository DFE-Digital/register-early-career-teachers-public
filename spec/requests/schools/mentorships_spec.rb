RSpec.describe 'Create mentorship of an ECT to a mentor' do
  include ActionView::Helpers::SanitizeHelper

  let(:ect) { FactoryBot.create(:ect_at_school_period, :active, school:) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, school:) }
  let(:school) { FactoryBot.create(:school) }

  describe 'GET /school/ects/:id/mentorship/new' do
    context 'when not signed in' do
      it 'redirects to the sign in page' do
        get("/school/ects/#{ect.id}/mentorship/new")

        expect(response).to be_redirection
        expect(response.redirect_url).to end_with('/sign-in')
      end
    end

    context 'when signed in as school user' do
      before do
        sign_in_as(:school_user, school_urn: school.urn)
      end

      it 'instantiates a new Schools::AssignMentorForm and renders the page' do
        allow(Schools::AssignMentorForm).to receive(:new).and_call_original

        get("/school/ects/#{ect.id}/mentorship/new")

        expect(response).to be_successful
        expect(Schools::AssignMentorForm).to have_received(:new).with(ect:).once
      end
    end
  end

  describe 'POST /school/ects/:id/mentorship' do
    context 'when not signed in' do
      it 'redirects to the sign in page' do
        post("/school/ects/#{ect.id}/mentorship")

        expect(response).to be_redirection
        expect(response.redirect_url).to end_with('/sign-in')
      end
    end

    context 'when signed in as school user' do
      before do
        sign_in_as(:school_user, school_urn: school.urn)
      end

      context 'when the option selected by the user is to create a new mentor' do
        let(:params) { { schools_assign_mentor_form: { mentor_id: '0' } } }

        it 'redirects to the start of the wizard to add a new mentor to the school' do
          post("/school/ects/#{ect.id}/mentorship", params:)

          expect(response).to be_redirection
          expect(response.redirect_url).to eq(schools_register_mentor_wizard_start_url(ect_id: ect.id))
        end
      end

      context 'when an invalid mentor has been selected for the ect mentorship' do
        let(:params) { { schools_assign_mentor_form: { mentor_id: mentor.id.next } } }

        it 'renders the form again for the user to select a different option' do
          allow(Schools::AssignMentorForm).to receive(:new).and_call_original

          post("/school/ects/#{ect.id}/mentorship", params:)

          expect(response).to be_successful
          expect(Schools::AssignMentorForm).to have_received(:new).with(ect:, mentor_id: mentor.id.next.to_s).once
          expect(sanitize(response.body)).to include("Who will mentor #{Teachers::Name.new(ect.teacher).full_name}?")
        end
      end

      context 'when a valid mentor has been selected for the ect mentorship' do
        let(:params) { { schools_assign_mentor_form: { mentor_id: mentor.id } } }

        it 'creates the mentorship and redirects the user to the confirmation page' do
          allow(Schools::AssignMentorForm).to receive(:new).and_call_original

          post("/school/ects/#{ect.id}/mentorship", params:)

          expect(Schools::AssignMentorForm).to have_received(:new).with(ect:, mentor_id: mentor.id.to_s).once
          expect(ect.current_mentor).to eq(mentor)
          expect(response).to be_redirection
          expect(response.redirect_url).to eq(confirmation_schools_ect_mentorship_url(ect_id: ect.id))
        end
      end
    end
  end

  describe 'GET /school/ects/:id/mentorship/confirmation' do
    context 'when not signed in' do
      it 'redirects to the sign in page' do
        get("/school/ects/#{ect.id}/mentorship/confirmation")

        expect(response).to be_redirection
        expect(response.redirect_url).to end_with('/sign-in')
      end
    end

    context 'when signed in as school user' do
      before do
        sign_in_as(:school_user, school_urn: school.urn)
      end

      it 'instantiates a new Schools::AssignMentorForm and renders the page' do
        Schools::AssignMentor.new(ect:, mentor:).assign
        allow(Schools::AssignMentorForm).to receive(:new).and_call_original

        get("/school/ects/#{ect.id}/mentorship/confirmation")

        expect(response).to be_successful
        expect(sanitize(response.body)).to include("You've assigned #{Teachers::Name.new(mentor.teacher).full_name} as a mentor")
      end
    end
  end
end
