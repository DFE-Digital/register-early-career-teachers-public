RSpec.describe Admin::Teachers::TableComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:rendered) { render_inline(described_class.new(rows:, teacher_path:)) }

  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Goku") }
  let(:rows) do
    [
      Admin::Teachers::Rows::Row.new(teacher:, role: "ect", contract_period: "2024"),
      Admin::Teachers::Rows::Row.new(
        teacher:,
        role: "mentor",
        contract_period: Admin::Teachers::Rows::CONTRACT_PERIOD_NOT_APPLICABLE
      )
    ]
  end
  let(:teacher_path) { ->(teacher_row) { admin_teacher_path(teacher_row.teacher_id) } }
  let(:teacher_name) { Teachers::Name.new(teacher).full_name }

  describe "table headers" do
    it { expect(rendered).to have_css("thead th", text: "Name") }
    it { expect(rendered).to have_css("thead th", text: "TRN") }
    it { expect(rendered).to have_css("thead th", text: "Role") }
    it { expect(rendered).to have_css("thead th", text: "Contract period") }
  end

  it "renders a separate row for each role" do
    table_rows = rendered.css("tbody tr").map do |row|
      row.css("td").map(&:text)
    end

    expect(table_rows).to eq([
      [teacher_name, teacher.trn, "Early career teacher", "2024"],
      [teacher_name, teacher.trn, "Mentor", "Not available"]
    ])
    expect(rendered).to have_link(teacher_name, href: admin_teacher_path(teacher), count: 2)
  end

  context "with a custom teacher path" do
    let(:teacher_path) do
      ->(teacher_row) { admin_teacher_path(teacher_row.teacher_id, q: "Goku", role: "mentor") }
    end

    it "uses the supplied teacher path" do
      expect(rendered).to have_link(
        teacher_name,
        href: admin_teacher_path(teacher, q: "Goku", role: "mentor"),
        count: 2
      )
    end
  end
end
