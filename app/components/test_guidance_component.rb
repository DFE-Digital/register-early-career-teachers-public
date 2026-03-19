class TestGuidanceComponent < ApplicationComponent
  renders_one :trs_example_teacher_details, "TestGuidance::TRSExampleTeacherDetails"
  renders_one :trs_fake_api_instructions, "TestGuidance::TRSFakeAPIInstructions"

  def render?
    Rails.application.config.enable_test_guidance &&
      (content.present? || trs_example_teacher_details.present? || trs_fake_api_instructions.present?)
  end
end
