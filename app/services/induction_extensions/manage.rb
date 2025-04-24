# Perform InductionExtension edits on behalf of an author and track change events:
#
class InductionExtensions::Manage
  attr_reader :author,
              :teacher,
              :appropriate_body,
              :induction_extension

  def initialize(author:, teacher:, appropriate_body:)
    @author = author
    @teacher = teacher
    @appropriate_body = appropriate_body
  end

  def create_or_update!(number_of_terms:, id: nil)
    @induction_extension = teacher.induction_extensions.find_or_initialize_by(id:)
    induction_extension.assign_attributes(number_of_terms:)

    InductionExtension.transaction do
      success = if induction_extension.new_record?
                  [induction_extension.save!, record_create_event!].all?
                else
                  [induction_extension.save!, record_update_event!].all?
                end

      success or raise ActiveRecord::Rollback
    end
  end

private

  def record_create_event!
    Events::Record.record_induction_extension_created_event!(**event_params)
  end

  def record_update_event!
    Events::Record.record_induction_extension_updated_event!(**event_params)
  end

  def event_params
    {
      author:,
      appropriate_body:,
      teacher:,
      induction_extension:,
      modifications: induction_extension.changes
    }
  end
end
