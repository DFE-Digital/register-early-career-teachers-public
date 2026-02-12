class EvidenceTypeValidator < ActiveModel::Validator
  SIMPLE_EVIDENCE_TYPES = %w[
    training-event-attended
    self-study-material-completed
    other
  ].freeze

  def validate(record)
    return if record.errors[:evidence_type].any?
    return if record.training_period.blank?

    evidence_type_is_present(record) if self.class.evidence_type_required?(record)

    if validate_detailed_evidence_types?(record)
      evidence_type_is_valid_detailed_evidence_type(record)
    elsif validate_simple_evidence_types?(record)
      evidence_type_is_valid_simple_evidence_type(record)
    end
  end

  def self.evidence_type_required?(record)
    record.declaration_type.present? && record.declaration_type != "started"
  end

  def self.evidence_type_allowed?(record)
    record.training_period.contract_period.detailed_evidence_types_enabled || evidence_type_required?(record)
  end

private

  def validate_detailed_evidence_types?(record)
    record.training_period.contract_period.detailed_evidence_types_enabled
  end

  def validate_simple_evidence_types?(record)
    record.declaration_type.present?
  end

  def evidence_type_is_present(record)
    return if record.errors[:evidence_type].any?
    return if record.evidence_type.present?

    record.errors.add(:evidence_type, "Enter a '#/evidence_type' value for this participant.")
  end

  def evidence_type_is_valid_simple_evidence_type(record)
    return if record.errors[:evidence_type].any?
    return if record.evidence_type.blank?
    return if record.evidence_type.in?(SIMPLE_EVIDENCE_TYPES)

    record.errors.add(:evidence_type, "Enter an available '#/evidence_type' type for this participant.")
  end

  def evidence_type_is_valid_detailed_evidence_type(record)
    return if record.errors[:evidence_type].any?
    return if record.errors[:declaration_type].any?
    return if record.evidence_type.blank?

    evidences = if record.training_period.for_ect?
                  ect_evidences(record.declaration_type)
                else
                  mentor_evidences(record.declaration_type)
                end
    return if record.evidence_type.in?(evidences)

    record.errors.add(:evidence_type, "Enter an available '#/evidence_type' type for this participant.")
  end

  def ect_evidences(declaration_type)
    case declaration_type
    when "started", "retained-1", "retained-3", "retained-4", "extended-1", "extended-2", "extended-3"
      %w[
        training-event-attended
        self-study-material-completed
        materials-engaged-with-offline
        other
      ]
    when "retained-2"
      %w[
        75-percent-engagement-met
        75-percent-engagement-met-reduced-induction
      ]
    when "completed"
      %w[
        75-percent-engagement-met
        75-percent-engagement-met-reduced-induction
        one-term-induction
      ]
    else
      []
    end
  end

  def mentor_evidences(declaration_type)
    case declaration_type
    when "started"
      %w[
        training-event-attended
        self-study-material-completed
        materials-engaged-with-offline
        other
      ]
    when "completed"
      %w[
        75-percent-engagement-met
        75-percent-engagement-met-reduced-induction
      ]
    else
      []
    end
  end
end
