describe Teachers::TermsCompleted do
  subject(:service) { described_class.new(teacher) }

  let(:teacher) { create(:teacher) }

  describe '#formatted_terms_completed' do
    context 'when the teacher does not have induction periods' do
      it { expect(service.formatted_terms_completed).to eq("0.0 of 6.0") }
    end

    context 'without extensions' do
      it 'returns the default number of terms' do
        expect(service.formatted_terms_completed).to eq("0.0 of 6.0")
      end

      context "with extensions" do
        before do
          create(:induction_extension, teacher:, number_of_terms: 2)
          create(:induction_extension, teacher:, number_of_terms: 1.1)
        end

        it 'returns the default number of terms plus the extensions' do
          expect(service.formatted_terms_completed).to eq("0.0 of 9.1")
        end
      end
    end

    context 'when the teacher has induction periods' do
      let!(:induction_period) { create(:induction_period, teacher:, number_of_terms: 2) }

      context 'without extensions' do
        it 'returns the default number of terms' do
          expect(service.formatted_terms_completed).to eq("2.0 of 6.0")
        end

        context "with extensions" do
          before do
            create(:induction_extension, teacher:, number_of_terms: 2)
            create(:induction_extension, teacher:, number_of_terms: 1.1)
          end

          it 'returns the default number of terms plus the extensions' do
            expect(service.formatted_terms_completed).to eq("2.0 of 9.1")
          end
        end
      end
    end
  end
end
