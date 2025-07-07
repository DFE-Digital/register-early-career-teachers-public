RSpec.describe Teachers::OutcomeFormComponent, type: :component do
  let(:teacher) { create(:teacher) }
  let(:appropriate_body) { build(:appropriate_body) }
  let(:form) { double("form", govuk_error_summary: "", govuk_date_field: "", govuk_number_field: "") }

  context "when in admin mode" do
    subject(:component) do
      described_class.new(
        form:,
        teacher:,
        is_admin: true
      )
    end

    it "returns the correct date legend text" do
      expect(component.date_legend_text).to eq("When did they complete their induction?")
    end

    it "returns the correct terms label text" do
      expect(component.terms_label_text).to eq("How many terms of induction did they complete?")
    end

    it "returns the correct date hint text" do
      expect(component.teacher_induction_date_hint_text).to eq("For example, 20 4 #{Date.current.year.pred}")
    end
  end

  context "when in appropriate body mode" do
    subject(:component) do
      described_class.new(
        form:,
        teacher:,
        is_admin: false,
        appropriate_body:
      )
    end

    it "returns the correct date legend text" do
      expect(component.date_legend_text).to eq("When did they move from #{appropriate_body.name}?")
    end

    it "returns the correct terms label text" do
      expect(component.terms_label_text).to eq("How many terms of induction did they spend with you?")
    end
  end
end
