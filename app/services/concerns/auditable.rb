module Auditable
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Dirty
  include ActiveModel::Validations::Callbacks
  include ActiveRecord::Normalization

  class_methods do
    def auditable_params
      { model_name.param_key => %i[zendesk_ticket_id note] }
    end
  end

  included do
    # @param author [Sessions::User]
    attribute :author
    # @param note [String]
    attribute :note
    # @param zendesk_ticket_id [String]
    attribute :zendesk_ticket_id

    validates :author, presence: true
    validates :zendesk_ticket_id,
              if: -> { author&.dfe_user? && zendesk_ticket_id.present? },
              format: {
                with: /\A\d{6}\z/,
                message: "Ticket number must be 6 digits"
              }

    validate :note_or_zendesk_ticket_present,
             if: -> { author&.dfe_user? }

    normalizes :zendesk_ticket_id,
               with: ->(ticket) { ticket.delete_prefix("#").strip }
  end

private

  def note_or_zendesk_ticket_present
    unless note.present? || zendesk_ticket_id.present?
      errors.add(:base, "Add a note or enter the Zendesk ticket number")
    end
  end
end
