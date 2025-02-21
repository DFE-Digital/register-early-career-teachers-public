RSpec.describe "schools/register_mentor_wizard/not_found.md.erb" do
  let(:find_a_lost_trn_path) { "https://find-a-lost-trn.education.gov.uk/start" }
  let(:review_teacher_record_path) { "https://www.gov.uk/guidance/check-a-teachers-record" }
  let(:try_again_path) { schools_register_mentor_wizard_find_mentor_path }
  let(:store) { double(trs_first_name: "John", trs_last_name: "Waters") }
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :not_found, store:) }

  before do
    assign(:wizard, wizard)
    render
  end

  context 'page title' do
    it { expect(sanitize(view.content_for(:page_title))).to eql("We're unable to match the mentor with the details you provided") }
  end

  it 'includes no back button' do
    expect(view.content_for(:backlink_or_breadcrumb)).to be_blank
  end

  it 'includes a link to reviewing the teacher record' do
    expect(rendered).to have_link('reviewing their teacher record', href: review_teacher_record_path)
  end

  it 'includes a link to the Find a lost TRN service' do
    expect(rendered).to have_link('Find a lost TRN service', href: find_a_lost_trn_path)
  end

  it 'includes a try again button that links to the find mentor page' do
    expect(rendered).to have_link('Try again', href: try_again_path)
  end
end
