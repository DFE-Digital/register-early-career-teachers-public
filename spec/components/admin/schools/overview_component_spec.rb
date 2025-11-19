RSpec.describe Admin::Schools::OverviewComponent, type: :component do
  let(:school) { FactoryBot.create(:school) }
  let(:component) { described_class.new(school:) }

  describe "#induction_tutor_name" do
    context "when school has induction tutor name" do
      before { school.update!(induction_tutor_name: "John Smith", induction_tutor_email: "john@school.edu") }

      it "returns the name" do
        expect(component.induction_tutor_name).to eq("John Smith")
      end
    end

    context "when school has no induction tutor name" do
      before { school.update!(induction_tutor_name: nil, induction_tutor_email: nil) }

      it 'returns "Not set"' do
        expect(component.induction_tutor_name).to eq("Not set")
      end
    end

    context "when school has blank induction tutor name" do
      before { allow(school).to receive(:induction_tutor_name).and_return("") }

      it 'returns "Not set"' do
        expect(component.induction_tutor_name).to eq("Not set")
      end
    end
  end

  describe "#induction_tutor_email" do
    context "when school has induction tutor email" do
      before { school.update!(induction_tutor_name: "John Smith", induction_tutor_email: "john@school.edu") }

      it "returns the email" do
        expect(component.induction_tutor_email).to eq("john@school.edu")
      end
    end

    context "when school has no induction tutor email" do
      before { school.update!(induction_tutor_name: nil, induction_tutor_email: nil) }

      it 'returns "Not set"' do
        expect(component.induction_tutor_email).to eq("Not set")
      end
    end

    context "when school has blank induction tutor email" do
      before { allow(school).to receive(:induction_tutor_email).and_return("") }

      it 'returns "Not set"' do
        expect(component.induction_tutor_email).to eq("Not set")
      end
    end
  end

  describe "#local_authority_name" do
    context "when school has local authority name" do
      before { allow(school).to receive(:local_authority_name).and_return("Essex") }

      it "returns the name" do
        expect(component.local_authority_name).to eq("Essex")
      end
    end

    context "when school has no local authority name" do
      before { allow(school).to receive(:local_authority_name).and_return(nil) }

      it 'returns "Not available"' do
        expect(component.local_authority_name).to eq("Not available")
      end
    end
  end

  describe "#address" do
    context "when school has full address" do
      before do
        allow(school).to receive_messages(address_line1: "123 Main St", address_line2: "Suite 100", address_line3: "Business District", postcode: "SW1A 1AA")
      end

      it "returns formatted address with line breaks" do
        result = component.address
        expect(result).to include("123 Main St")
        expect(result).to include("Suite 100")
        expect(result).to include("Business District")
        expect(result).to include("SW1A 1AA")
        # Should contain HTML breaks between lines
        expect(result).to be_html_safe
      end
    end

    context "when school has partial address" do
      before do
        allow(school).to receive_messages(address_line1: "123 Main St", address_line2: "", address_line3: nil, postcode: "SW1A 1AA")
      end

      it "returns formatted address excluding blank lines" do
        result = component.address
        expect(result).to include("123 Main St")
        expect(result).to include("SW1A 1AA")
        expect(result).not_to include("Suite 100")
        expect(result).not_to include("Business District")
      end
    end

    context "when school has no address" do
      before do
        allow(school).to receive_messages(address_line1: nil, address_line2: "", address_line3: nil, postcode: "")
      end

      it 'returns "Not available"' do
        expect(component.address).to eq("Not available")
      end
    end
  end

  describe "#section_41_status" do
    context "when true" do
      let(:school) { FactoryBot.build(:school, :section_41) }

      it { expect(component.section_41_status).to eql("Approved") }
    end

    context "when false" do
      let(:school) { FactoryBot.build(:school, :not_section_41) }

      it { expect(component.section_41_status).to eql("Not approved") }
    end
  end

  describe "#establishment_type" do
    let(:school) { FactoryBot.build(:school) }

    it { expect(component.establishment_type).to eql(school.type_name) }
  end

  describe "#administrative_district" do
    context "when present" do
      let(:school) { FactoryBot.build(:school, :with_administrative_district) }

      it { expect(component.administrative_district).to eql(school.administrative_district_name) }
    end

    context "when missing" do
      let(:school) { FactoryBot.build(:school) }

      it { expect(component.administrative_district).to eql("Not available") }
    end
  end

  describe "#status" do
    let(:school) { FactoryBot.build(:school) }

    it { expect(component.status).to eql(school.status.capitalize) }
  end

  describe "rendering" do
    before do
      school.update!(induction_tutor_name: "Jane Smith", induction_tutor_email: "jane@school.edu")
      allow(school).to receive_messages(
        local_authority_name: "Essex",
        address_line1: "123 Main St",
        address_line2: "",
        address_line3: "",
        postcode: "SW1A 1AA",
        type_name: "Community school",
        section_41_approved?: false,
        status: "Open",
        administrative_district_name: "South Northamptonshire"
      )
    end

    it "renders the summary list with school information" do
      render_inline(component)

      expect(rendered_content).to have_css(".govuk-summary-list")

      expect(rendered_content).to have_css("dt", text: "Induction tutor")
      expect(rendered_content).to have_css("dd", text: "Jane Smith")

      expect(rendered_content).to have_css("dt", text: "Induction tutor email")
      expect(rendered_content).to have_css("dd", text: "jane@school.edu")

      expect(rendered_content).to have_css("dt", text: "Local authority")
      expect(rendered_content).to have_css("dd", text: "Essex")

      expect(rendered_content).to have_css("dt", text: "Address")
      expect(rendered_content).to have_css("dd", text: /123 Main St.*SW1A 1AA/m)

      expect(rendered_content).to have_css("dt", text: "Establishment status")
      expect(rendered_content).to have_css("dd", text: "Open")

      expect(rendered_content).to have_css("dt", text: "Establishment type")
      expect(rendered_content).to have_css("dd", text: "Community school")

      expect(rendered_content).to have_css("dt", text: "Section 41 status")
      expect(rendered_content).to have_css("dd", text: "Not approved")

      expect(rendered_content).to have_css("dt", text: "Administratrive district")
      expect(rendered_content).to have_css("dd", text: "South Northamptonshire")
    end

    it "includes change links for editable fields" do
      render_inline(component)

      expect(rendered_content).to have_css("a", text: "Change")
      expect(rendered_content).to have_css(".govuk-visually-hidden", text: "induction tutor name")
      expect(rendered_content).to have_css(".govuk-visually-hidden", text: "induction tutor email")
    end
  end
end
