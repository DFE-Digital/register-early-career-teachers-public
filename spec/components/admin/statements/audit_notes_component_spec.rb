RSpec.describe Admin::Statements::AuditNotesComponent, type: :component do
  let(:statement) { FactoryBot.create(:statement) }
  let(:component) { described_class.new statement: }

  context "no audit notes" do
    before do
      render_inline(component)
    end

    it "does not render" do
      expect(page).not_to have_css("h2", text: "Audit notes")
    end
  end

  context "with audit notes" do
    let(:older_created_at) { Time.zone.local(2024, 8, 1, 9, 30) }
    let(:newer_created_at) { Time.zone.local(2024, 9, 2, 17, 5) }

    before do
      FactoryBot.create :statement_audit_note, statement:, body: "Older note", created_at: older_created_at
      FactoryBot.create :statement_audit_note, statement:, body: "Newer note", created_at: newer_created_at

      render_inline(component)
    end

    it "lists the notes oldest first, each below its timestamp" do
      expect(page).to have_css("h2", text: "Audit notes")
      expect(page.all("p").map(&:text)).to eq([
        "1 August 2024, 9:30am",
        "Older note",
        "2 September 2024, 5:05pm",
        "Newer note"
      ])
      expect(page.all("time").map { |element| element[:datetime] }).to eq([older_created_at.iso8601, newer_created_at.iso8601])
    end
  end
end
