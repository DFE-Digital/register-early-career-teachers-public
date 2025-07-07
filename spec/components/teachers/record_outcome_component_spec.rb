RSpec.describe Teachers::RecordOutcomeComponent, type: :component do
  let(:teacher) { create(:teacher) }
  let(:appropriate_body) { build(:appropriate_body) }
  let(:pending_induction_submission) { PendingInductionSubmission.new }
  let(:teacher_name) { Teachers::Name.new(teacher).full_name }

  describe "admin mode with passed outcome" do
    subject(:component) do
      described_class.new(
        teacher:,
        pending_induction_submission:,
        mode: :admin,
        outcome_type: :passed
      )
    end

    it "has the correct title" do
      expect(component.title).to eq("Record passed outcome for #{teacher_name}")
    end

    it "has the correct backlink" do
      render_inline(component)
      expect(component.backlink_href).to eq("/admin/teachers/#{teacher.id}")
    end

    it "has the correct form URL" do
      render_inline(component)
      expect(component.form_url).to eq("/admin/teachers/#{teacher.id}/record-passed-outcome")
    end

    it "has the correct submit text" do
      expect(component.submit_text).to eq("Record pass outcome for #{teacher_name}")
    end

    it "does not show appeal notice" do
      expect(component.show_appeal_notice?).to be false
    end

    it "is not a warning button" do
      expect(component.warning?).to be false
    end
  end

  describe "admin mode with failed outcome" do
    subject(:component) do
      described_class.new(
        teacher:,
        pending_induction_submission:,
        mode: :admin,
        outcome_type: :failed
      )
    end

    it "has the correct title" do
      expect(component.title).to eq("Record failed outcome for #{teacher_name}")
    end

    it "has the correct form URL" do
      render_inline(component)
      expect(component.form_url).to eq("/admin/teachers/#{teacher.id}/record-failed-outcome")
    end

    it "has the correct submit text" do
      expect(component.submit_text).to eq("Record failing outcome for #{teacher_name}")
    end

    it "does not show appeal notice" do
      expect(component.show_appeal_notice?).to be false
    end

    it "is a warning button" do
      expect(component.warning?).to be true
    end
  end

  describe "appropriate body mode with passed outcome" do
    subject(:component) do
      described_class.new(
        teacher:,
        pending_induction_submission:,
        mode: :appropriate_body,
        outcome_type: :passed,
        appropriate_body:
      )
    end

    it "has the correct backlink" do
      render_inline(component)
      expect(component.backlink_href).to eq("/appropriate-body/teachers/#{teacher.id}")
    end

    it "has the correct form URL" do
      render_inline(component)
      expect(component.form_url).to eq("/appropriate-body/teachers/#{teacher.id}/record-passed-outcome")
    end

    it "does not show appeal notice" do
      expect(component.show_appeal_notice?).to be false
    end
  end

  describe "appropriate body mode with failed outcome" do
    subject(:component) do
      described_class.new(
        teacher:,
        pending_induction_submission:,
        mode: :appropriate_body,
        outcome_type: :failed,
        appropriate_body:
      )
    end

    it "has the correct form URL" do
      render_inline(component)
      expect(component.form_url).to eq("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome")
    end

    it "shows appeal notice" do
      expect(component.show_appeal_notice?).to be true
    end

    it "is a warning button" do
      expect(component.warning?).to be true
    end
  end
end
