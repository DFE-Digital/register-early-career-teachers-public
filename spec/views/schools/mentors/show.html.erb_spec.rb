RSpec.describe "schools/mentors/show.html.erb" do
  include TeacherHelper

  subject { rendered }

  let(:school)      { FactoryBot.create(:school) }
  let(:teacher)     { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
  let(:started_on)  { Date.new(2023, 9, 1) }
  let(:finished_on) { nil }

  let(:mentor_period) do
    FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on:, finished_on:)
  end

  before do
    assign(:mentor, mentor_period)
    assign(:teacher, teacher)
    assign(:school, school)
    assign(:ects, [])
  end

  it "renders a Schools::Mentors::DetailsComponent" do
    expect(Schools::Mentors::DetailsComponent).to receive(:new).with(teacher:, mentor: mentor_period).and_call_original
    render
  end

  it "renders a Schools::Mentors::ECTMentorTrainingDetailsComponent" do
    expect(Schools::Mentors::ECTMentorTrainingDetailsComponent).to receive(:new).with(teacher:, mentor: mentor_period).and_call_original
    render
  end

  describe "leaving section" do
    let(:leaving_wizard_href) { schools_mentors_teacher_leaving_wizard_edit_path(mentor_period) }

    context "when the mentor has not been reported as leaving" do
      before { render }

      it { is_expected.to have_css("h2.govuk-heading-m", text: "Tell us if Naruto Uzumaki has left or is leaving your school permanently") }
      it { is_expected.to have_text("We need to know if Naruto Uzumaki is leaving your school and not expected to return.") }
      it { is_expected.to have_text("You do not need to tell us if Naruto Uzumaki is leaving but expected to return") }
      it { is_expected.to have_link(href: leaving_wizard_href) }
    end

    context "when the mentor has been reported as leaving" do
      let(:finished_on) { 1.week.from_now.to_date }

      before do
        mentor_period.update!(reported_leaving_by_school_id: school.id)
        render
      end

      it { is_expected.to have_css("h2.govuk-heading-m", text: "Naruto Uzumaki is leaving your school") }
      it { is_expected.to have_text("You’ve told us Naruto Uzumaki is leaving your school on #{finished_on.to_fs(:govuk)}.", normalize_ws: true) }
      it { is_expected.to have_text("You will not be able to view or edit Naruto Uzumaki’s details after #{finished_on.to_fs(:govuk)}.", normalize_ws: true) }
      it { is_expected.not_to have_link(href: leaving_wizard_href) }
    end
  end
end
