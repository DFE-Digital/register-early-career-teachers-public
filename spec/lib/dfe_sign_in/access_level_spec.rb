describe 'DfESignIn::AccessLevel' do
  describe '.from_response_body' do
    # https://github.com/DFE-Digital/login.dfe.public-api?tab=readme-ov-file#get-user-access-to-service
    let(:role_data) do
      {
        "userId" => "user-id",
        "serviceId" => "service-id",
        "organisationId" => "organisation-id",
        "roles" => [
          {
            "id" => "role-1",
            "name" => "The name of the first role",
            "code" => "The code of the first role",
            "numericId" => "9998",
            "status" => {
              "id" => 1
            }
          },
          {
            "id" => "role-2",
            "name" => "The name of the second role",
            "code" => "The code of the second role",
            "numericId" => "9999",
            "status" => {
              "id" => 1
            }
          }
        ],
        "identifiers" => [
          {
            "key" => "identifier-key",
            "value" => "identifier-value"
          }
        ]
      }
    end

    subject { DfESignIn::AccessLevel.from_response_body(role_data) }

    it('assigns user_id') { expect(subject.user_id).to eql('user-id') }
    it('assigns service_id') { expect(subject.service_id).to eql('service-id') }
    it('assigns organisation_id') { expect(subject.organisation_id).to eql('organisation-id') }

    describe 'roles' do
      it('creates 2 roles') { expect(subject.roles.count).to eq(2) }

      describe 'role 1' do
        it('sets the id') { expect(subject.roles.first.id).to eql('role-1') }
        it('sets the name') { expect(subject.roles.first.name).to eql('The name of the first role') }
        it('sets the code') { expect(subject.roles.first.code).to eql('The code of the first role') }
        it('sets the numericId') { expect(subject.roles.first.numeric_id).to eql('9998') }
      end

      describe 'role 2' do
        it('sets the id') { expect(subject.roles.second.id).to eql('role-2') }
        it('sets the name') { expect(subject.roles.second.name).to eql('The name of the second role') }
        it('sets the code') { expect(subject.roles.second.code).to eql('The code of the second role') }
        it('sets the numericId') { expect(subject.roles.second.numeric_id).to eql('9999') }
      end
    end
  end

  describe '#has_register_ect_access_role?' do
    let(:role_data) do
      {
        "userId" => "user-id",
        "serviceId" => "service-id",
        "organisationId" => "organisation-id",
        "roles" => [
          {
            "id" => "role-1",
            "name" => "Role A",
            "code" => code,
            "numericId" => "1234",
            "status" => {
              "id" => 1
            }
          }
        ]
      }
    end

    subject { DfESignIn::AccessLevel.from_response_body(role_data).has_register_ect_access_role? }

    context 'when the role is registerECTsAccess' do
      let(:code) { 'registerECTsAccess' }

      it { is_expected.to be(true) }
    end

    context 'when the role is registerECTsAccess' do
      let(:code) { 'somethingElse' }

      it { is_expected.to be(false) }
    end
  end
end
