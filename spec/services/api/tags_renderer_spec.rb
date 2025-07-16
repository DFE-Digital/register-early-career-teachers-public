describe API::TagsRenderer do
  describe "initialization" do
    subject { described_class.new(tags) }

    let(:tags) { ["#bug-fix", "#new-feature"] }

    describe '#initialize' do
      it 'sets it to the injected object if provided' do
        expect(subject.tags).to eq(tags)
      end
    end

    describe "#render" do
      subject { described_class.new(tags).render }

      let(:expected_output) do
        %(<div class=\"tag-group\">) +
          %(<strong class=\"govuk-tag govuk-tag--green govuk-!-font-weight-bold\">NEW FEATURE</strong>) +
          %(<strong class=\"govuk-tag govuk-tag--yellow govuk-!-font-weight-bold\">BUG FIX</strong></div>)
      end

      it { is_expected.to eq(expected_output) }

      context "when a tag is are not mapped" do
        let(:tags) { ["#new-tag"] }

        it "raises an error" do
          expect {
            subject
          }.to raise_error(described_class::UnknownTagError, "Tag not recognised: #new-tag")
        end
      end

      context "when tags is empty" do
        let(:tags) { [] }

        it { is_expected.to be_nil }
      end
    end
  end
end
