module Auditable
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes

  included do
    # @param author [Sessions::User]
    attribute :author
    # @param note [String]
    attribute :note
    # @param zendesk_ticket_id [String]
    attribute :zendesk_ticket_id

    validates :author, presence: true
    validates :zendesk_ticket_id,
              format: {
                with: /\A#?\d{6}\z/,
                message: "Ticket number must be 6 digits"
              },
              if: -> { author.dfe_user? && zendesk_ticket_id.present? }

    validate :note_or_zendesk_ticket_present, if: -> { author.dfe_user? }
  end

private

  def note_or_zendesk_ticket_present
    unless note.present? || zendesk_ticket_id.present?
      errors.add(:base, "Add a note or enter the Zendesk ticket number")
    end
  end
end
