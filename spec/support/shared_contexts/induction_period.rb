RSpec.shared_examples 'an induction period' do
  describe 'shared validations' do
    let(:factory) { described_class.name.underscore.to_sym }

    describe '#started_on_from_september_2021_onwards' do
      context 'when start date is before September 2021' do
        subject { FactoryBot.build(factory, started_on: '2021-8-31') }

        before { subject.valid?(:register_ect) }

        it { expect(subject.errors.messages[:started_on]).to include("Enter a start date after 1 September 2021") }
      end

      it { is_expected.not_to allow_values('2021-8-30', '2021-8-31').on(:register_ect).for(:started_on) }
      it { is_expected.to allow_values('2021-9-1', '2021-9-2').on(:register_ect).for(:started_on) }
    end

    describe '#started_on_from_september_1999_onwards' do
      context 'when start date is before September 1999' do
        subject { FactoryBot.build(factory, started_on: '1999-8-31') }

        before { subject.valid? }

        it { expect(subject.errors.messages[:started_on]).to include("Enter a start date after 1 September 1999") }
      end

      it { is_expected.not_to allow_values('1999-8-30', '1999-8-31').for(:started_on) }
      it { is_expected.to allow_values('1999-9-1', '1999-9-2').for(:started_on) }
    end
  end
end
