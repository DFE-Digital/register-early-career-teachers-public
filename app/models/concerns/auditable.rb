module Auditable
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes

  included do
    attribute :author
    attribute :note
    attribute :zendesk_ticket_id

    validates :author, presence: true
    validates :zendesk_ticket_id,
              numericality: {
                only_integer: true,
                message: "ID must be a number"
              },
              if: -> { author.dfe_user? && zendesk_ticket_id.present? }

    validate :note_or_zendesk_ticket_present, if: -> { author.dfe_user? }
  end

private

  def note_or_zendesk_ticket_present
    unless note.present? || zendesk_ticket_id.present?
      errors.add(:base, "Enter a Zendesk ID or add a note")
    end
  end
end
