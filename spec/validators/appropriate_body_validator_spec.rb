require 'rails_helper'

RSpec.describe AppropriateBodyValidator do
  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :appropriate_body_type, :appropriate_body_name

      validates_with AppropriateBodyValidator
    end
  end

  subject { test_class.new(appropriate_body_type:, appropriate_body_name:) }

  context 'when the appropriate_body_type is blank' do
    let(:appropriate_body_type) { '' }
    let(:appropriate_body_name) { '' }

    it 'is not valid' do
      expect(subject).not_to be_valid
      expect(subject.errors[:appropriate_body_type]).to include("Select the appropriate body which will be supporting the ECT's induction")
    end
  end

  context 'when appropriate_body_type is teaching_school_hub' do
    let(:appropriate_body_type) { 'teaching_school_hub' }

    context 'and appropriate_body_name is blank' do
      let(:appropriate_body_name) { '' }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:appropriate_body_name]).to include("Enter the name of the appropriate body which will be supporting the ECT's induction")
      end
    end

    context 'and appropriate_body_name is present' do
      let(:appropriate_body_name) { 'Some Appropriate Body' }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  context 'when appropriate_body_type is not teaching_school_hub' do
    let(:appropriate_body_type) { 'other_type' }
    let(:appropriate_body_name) { '' }

    it 'is valid' do
      expect(subject).to be_valid
    end
  end
end
