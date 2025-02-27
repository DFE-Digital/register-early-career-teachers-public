RSpec.describe 'Listing and searching ECTs belonging to an appropriate body' do
  describe 'GET /admin/organisations/appropriate-bodies/current-ects' do
    let!(:appropriate_body) { FactoryBot.create(:appropriate_body) }

    context 'when not logged in' do
      it "redirects to sign-in" do
        get "/admin/organisations/appropriate-bodies/#{appropriate_body.id}/current-ects"
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get "/admin/organisations/appropriate-bodies/#{appropriate_body.id}/current-ects"

        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      let!(:teacher_1) { FactoryBot.create(:teacher, trs_first_name: "Pam", trs_last_name: "Ferris") }
      let!(:teacher_2) { FactoryBot.create(:teacher, trs_first_name: "Felicity", trs_last_name: "Kendall") }

      let!(:induction_period_1) { FactoryBot.create(:induction_period, :active, teacher: teacher_1, appropriate_body:) }
      let!(:induction_period_2) { FactoryBot.create(:induction_period, :active, teacher: teacher_2, appropriate_body:) }

      it 'shows lists current ECTs' do
        get "/admin/organisations/appropriate-bodies/#{appropriate_body.id}/current-ects"

        expect(response.body).to include('Pam Ferris', 'Felicity Kendall')
      end

      it 'only shows ECTs who belong to this appropriate body' do
        expect(Teachers::Search).to receive(:new).with(appropriate_bodies: appropriate_body).once.and_call_original
        expect(Teachers::Search).to receive(:new).with(query_string: nil, appropriate_bodies: appropriate_body).once.and_call_original

        get "/admin/organisations/appropriate-bodies/#{appropriate_body.id}/current-ects"
      end

      context 'when searching by name' do
        let(:search_term) { "kend" }

        it 'only shows matching ECTs' do
          get "/admin/organisations/appropriate-bodies/#{appropriate_body.id}/current-ects?q=#{search_term}"

          expect(response.body).to include('Felicity Kendall')
          expect(response.body).not_to include('Pam Ferris')
        end

        it 'only shows ECTs who belong to this appropriate body' do
          expect(Teachers::Search).to receive(:new).with(appropriate_bodies: appropriate_body).once.and_call_original
          expect(Teachers::Search).to receive(:new).with(query_string: search_term, appropriate_bodies: appropriate_body).once.and_call_original

          get "/admin/organisations/appropriate-bodies/#{appropriate_body.id}/current-ects?q=#{search_term}"
        end
      end
    end
  end
end
