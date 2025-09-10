class ParticipantIdChange < ApplicationRecord
  belongs_to :teacher

  validates :teacher, :from_participant_id, :to_participant_id, presence: true
  validates :api_id, uniqueness: { case_sensitive: false, message: "API id already exists for another participant id change" }
end
