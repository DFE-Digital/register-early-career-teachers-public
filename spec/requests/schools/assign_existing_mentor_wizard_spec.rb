RSpec.describe 'Assign existing mentor wizard', :enable_schools_interface do
  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { Date.new(2023, 9, 1) }
  let(:ect)    { FactoryBot.create(:ect_at_school_period, :ongoing, school:, started_on:) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on:) }

  around do |example|
    travel_to(started_on + 1.day) do
      example.run
    end
  end

  before do
    contract_period = FactoryBot.create(:contract_period, :with_schedules, year: 2023)
    school_partnership = FactoryBot.create(:school_partnership)
    school_partnership.lead_provider_delivery_partnership.active_lead_provider.update!(contract_period:)

    FactoryBot.create(:training_period,
                      :ongoing,
                      :provider_led,
                      ect_at_school_period: ect,
                      started_on:,
                      school_partnership:)
  end

  def kickoff_wizard!
    allow(Teachers::MentorFundingEligibility).to receive(:new)
      .with(trn: mentor.teacher.trn)
      .and_return(instance_double(Teachers::MentorFundingEligibility, eligible?: true))

    post(
      "/school/ects/#{ect.id}/mentorship",
      params: { schools_assign_mentor_form: { mentor_id: mentor.id } }
    )
  end

  describe 'GET /school/assign-existing-mentor/:step' do
    context 'when signed in as a school user' do
      before { sign_in_as(:school_user, school:) }

      context 'when the wizard is not yet started' do
        it 'redirects to the root path' do
          get schools_assign_existing_mentor_wizard_review_mentor_eligibility_path
          expect(response).to redirect_to(root_path)
        end
      end

      context 'when the mentor is eligible for funding' do
        before { kickoff_wizard! }

        it 'renders the review_mentor_eligibility step' do
          get schools_assign_existing_mentor_wizard_review_mentor_eligibility_path
          expect(response).to have_http_status(:ok)
        end

        it 'renders the lead_provider step' do
          get schools_assign_existing_mentor_wizard_lead_provider_path
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when visiting an invalid step' do
        it 'renders a 404 page' do
          get '/school/assign-existing-mentor/fake-step'
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'POST /school/assign-existing-mentor/:step' do
    before { sign_in_as(:school_user, school:) }

    context 'when the wizard is not started' do
      it 'redirects to the root path' do
        post schools_assign_existing_mentor_wizard_review_mentor_eligibility_path
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when mentor is eligible for funding' do
      before { kickoff_wizard! }

      it 'redirects to the confirmation step' do
        post schools_assign_existing_mentor_wizard_review_mentor_eligibility_path
        expect(response).to redirect_to(schools_assign_existing_mentor_wizard_confirmation_path)
      end
    end

    context 'when visiting an invalid step' do
      it 'renders a 404 page' do
        post '/school/assign-existing-mentor/fake-step'
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
