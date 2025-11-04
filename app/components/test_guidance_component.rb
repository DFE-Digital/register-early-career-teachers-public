class TestGuidanceComponent < ApplicationComponent
  renders_one :trs_example_teacher_details, "TRSExampleTeacherDetails"
  renders_one :trs_fake_api_instructions, "TRSFakeAPIInstructions"

  def render?
    Rails.application.config.enable_test_guidance &&
      (content.present? || trs_example_teacher_details.present? || trs_fake_api_instructions.present?)
  end

  class TRSFakeAPIInstructions < ApplicationComponent
    def list
      [
        '7000001 (QTS not awarded)',
        '7000002 (teacher not found)',
        '7000003 (prohibited from teaching)',
        '7000004 (teacher has been deactivated in TRS)',
        '7000005 (teacher has alerts but is not prohibited)',
        '7000006 (teacher is exempt from mentor funding)',
        '7000007 (teacher has passed their induction)',
        '7000008 (teacher has failed their induction)',
        '7000009 (teacher is exempt from training)',
        '7000010 (teacher has failed their induction in Wales)',
      ]
    end
  end

  class TRSExampleTeacherDetails < ApplicationComponent
  private

    def head = ["Name", "TRN", "Date of birth", "Status", ""]

    def rows
      test_data.map do |row|
        name, trn, dob, ni_number, status, * = row.values_at
        [
          name, trn, dob, status_indicator(status), populate_button(trn, dob, ni_number)
        ]
      end
    end

    def test_data = CSV.read(file_path, headers: true)

    def file_path = Rails.root.join('spec/fixtures/seeds_trs.csv')

    def status_indicator(trs_induction_status)
      govuk_tag(**Teachers::InductionStatus.new(trs_induction_status:).status_tag_kwargs)
    end

    def populate_button(trn, dob, national_insurance_number)
      govuk_button_link_to('Select', '#',
                           class: 'populate-find-ect-form-button',
                           secondary: true,
                           data: {
                             trn:,
                             dob: Date.parse(dob).strftime("%d/%m/%Y"),
                             national_insurance_number:
                           })
    end
  end
end
