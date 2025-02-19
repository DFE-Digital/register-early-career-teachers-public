describe 'Admin::UserSearch' do
  describe '.find_by_email_case_insensitively!' do
    subject { Admin::UserSearch.new }
    context 'when the user exists' do
      it 'lower cases the email address column and search term' do
        shaggy = FactoryBot.create(:user, email: 'shaggy@EXAMPLE.com')
        expect(subject.find_by_email_case_insensitively!('SHAGGY@example.com')).to eq(shaggy)
      end
    end

    context 'when the user does not exist' do
      it 'raises record not found error' do
        expect { subject.find_by_email_case_insensitively!('SHAGGY@example.com') }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
