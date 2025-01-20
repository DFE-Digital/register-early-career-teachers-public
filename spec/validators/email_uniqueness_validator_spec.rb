require 'rails_helper'

RSpec.describe EmailUniquenessValidator do
  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :id, :email, :teacher_id

      validates :email, email_uniqueness: true
    end
  end

  subject { test_class.new(email:) }

  let(:teacher_1) { FactoryBot.create(:teacher) }
  let(:teacher_2) { FactoryBot.create(:teacher) }
  let(:school) { FactoryBot.create(:school) }
  let(:email) { "test@example.com" }

  context 'when the email is already associated with an existing teacher' do
    it 'is not valid' do
      FactoryBot.create(:ect_at_school_period, teacher: teacher_1, email:, school:)

      expect(subject).not_to be_valid
      expect(subject.errors[:email]).to include("Email address is already in use by another teacher")
    end
  end

  context 'when the email is not currently associated with an existing teacher' do
    it 'is valid' do
      FactoryBot.create(:ect_at_school_period, teacher: teacher_1, email: 'different@email.com', school:)

      expect(subject).to be_valid
    end
  end

  context 'when an email is blank' do
    let(:email) { '' }

    it 'is valid' do
      expect(subject).to be_valid
    end
  end
end
