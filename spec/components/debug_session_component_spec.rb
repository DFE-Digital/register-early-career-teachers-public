RSpec.describe DebugSessionComponent, type: :component do
  subject(:component) do
    described_class.new(current_session:, current_user:)
  end

  let(:current_session) do
    {
      'Type'	=> 'Sessions::Users::DfEUser',
      'Email'	=> current_user.email,
      'Last active at' =>	'1999-01-01 00:00:01 +0100'
    }
  end

  let(:current_user) do
    FactoryBot.create(:dfe_user, role: 'super_admin')
  end

  context 'when disabled' do
    before do
      allow(Rails.application.config).to receive(:enable_test_guidance).and_return(false)
      render_inline(component)
    end

    it { expect(rendered_content).to be_blank }
  end

  context 'when enabled' do
    before do
      allow(Rails.application.config).to receive(:enable_test_guidance).and_return(true)
      render_inline(component)
    end

    it { expect(rendered_content).not_to be_blank }

    it 'summarises session and user details' do
      aggregate_failures do
        expect(rendered_content).to have_text('Type')
        expect(rendered_content).to have_text('Sessions::Users::DfEUser')
        expect(rendered_content).to have_text('Email')
        expect(rendered_content).to have_text('@example.com')
        expect(rendered_content).to have_text('Last active at')
        expect(rendered_content).to have_text('1999-01-01 00:00:01 +0100')
        expect(rendered_content).to have_text('Role')
        expect(rendered_content).to have_text('Super admin')
      end
    end

    context 'and the user is not a DfE user' do
      let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
      let(:current_user) do
        FactoryBot.create(:appropriate_body_user,
                          dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id)
      end

      it 'does not display role information' do
        expect(rendered_content).to have_text('RoleN/A')
      end
    end
  end
end
