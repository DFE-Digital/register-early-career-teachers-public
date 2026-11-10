RSpec.describe Events::AppropriateBodyAPIAuthor do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }

  describe "#event_author_params" do
    it "returns the author type and appropriate body name" do
      author = described_class.new(appropriate_body_period:)

      expect(author.event_author_params).to eql({
        author_type: :appropriate_body_api,
        author_name: "Golden Leaf Teaching School Hub",
      })
    end

    it "includes the OAuth client when there is one" do
      oauth_client = FactoryBot.create(:api_oauth_client)
      author = described_class.new(appropriate_body_period:, oauth_client:)

      expect(author.event_author_params).to eql({
        author_type: :appropriate_body_api,
        author_name: "Golden Leaf Teaching School Hub",
        oauth_client:,
      })
    end
  end

  it "acts as an appropriate body user" do
    author = described_class.new(appropriate_body_period:)

    expect(author).to have_attributes(dfe_user?: false, appropriate_body_user?: true)
  end
end
