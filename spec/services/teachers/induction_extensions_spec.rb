describe Teachers::InductionExtensions do
  let(:teacher) { create(:teacher) }

  describe '#yes_or_no' do
    subject(:yes_or_no) { described_class.new(teacher).yes_or_no }

    context 'without extensions' do
      it { expect(yes_or_no).to eq("No") }
    end

    context 'with extensions' do
      let!(:extension) { create(:induction_extension, teacher:) }

      it { expect(yes_or_no).to eq("Yes") }
    end
  end

  describe "#formatted_number_of_terms" do
    subject(:formatted_number_of_terms) { described_class.new(teacher).formatted_number_of_terms }

    before do
      allow(teacher.induction_extensions).to receive(:sum).and_return(total)
    end

    context "when greater than 1" do
      let(:total) { 5.1 }

      it { expect(formatted_number_of_terms).to eql("#{total} terms") }
    end

    context "when less than 1" do
      let(:total) { 0.777777 }

      it { expect(formatted_number_of_terms).to eql("#{total} terms") }
    end

    context "when 1" do
      let(:total) { 1.0 }

      it { expect(formatted_number_of_terms).to eql("#{total} term") }
    end

    context "when 1.2" do
      let(:total) { 1.2 }

      it { expect(formatted_number_of_terms).to eql("#{total} terms") }
    end
  end
end
