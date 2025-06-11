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
                  induction_extension.save && record_create_event!
                else
                  induction_extension.save && record_update_event!
                end

      success or raise ActiveRecord::Rollback
    end
  end

  def delete!(id:)
    @induction_extension = teacher.induction_extensions.find(id)
    number_of_terms = induction_extension.number_of_terms

    InductionExtension.transaction do
      success = [induction_extension.destroy!, record_delete_event!(number_of_terms:)].all?

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

  def record_delete_event!(number_of_terms:)
    Events::Record.record_induction_extension_deleted_event!(
      author:,
      appropriate_body:,
      teacher:,
      number_of_terms:
    )
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
