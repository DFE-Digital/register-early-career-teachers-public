PARTICIPANT_ENROLMENT = {
  description: "The details of a participant enrolment",
  type: :object,
  required: %i[
    training_record_id
    email
    school_urn
    participant_type
    cohort
    training_status
    participant_status
    eligible_for_funding
    pupil_premium_uplift
    sparsity_uplift
    schedule_identifier
    delivery_partner_id
    created_at
  ],
  properties: {
    training_record_id: {
      description: "The unique identifier of this participant's training record. Should the DfE dedupe a participant, this value will not change.",
      type: :string,
      format: :uuid,
      example: "42a9ef2f-9059-400a-92ff-4830a629d0c5"
    },
    email: {
      description: "The email address registered for this participant",
      type: :string,
      example: "jane.smith@example.com"
    },
    mentor_id: {
      description: "The unique identifier of this participant's mentor",
      type: :string,
      format: :uuid,
      example: "42a9ef2f-9059-400a-92ff-4830a629d0c5",
      nullable: true
    },
    school_urn: {
      description: "The Unique Reference Number (URN) of the school that submitted this participant",
      type: :string,
      example: "123456"
    },
    participant_type: {
      description: "The type of participant this record refers to",
      type: :string,
      enum: %w[ect mentor],
      example: "ect"
    },
    cohort: {
      description: "Indicates which call-off contract funds this participant's training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year.",
      type: :string,
      example: "2021",
    },
    training_status: {
      description: "The training status of this participant, indicated by a lead provider deferring, withdrawing or resuming a participant's training.",
      type: :string,
      example: "active",
      enum: %w[active deferred withdrawn]
    },
    participant_status: {
      description: "Indicates if a participant has started at a school yet or a school or lead provider has reported they have stopped training.",
      type: :string,
      enum: %w[active joining leaving left],
      example: "active"
    },
    eligible_for_funding: {
      description: "Indicates whether this participant has become eligible to receive DfE funded induction",
      type: :boolean,
      example: true,
      nullable: true
    },
    pupil_premium_uplift: {
      description: "Indicates whether this ECT qualifies for an uplift payment due to pupil premium. It does not apply to mentors.",
      type: :boolean,
      example: true
    },
    sparsity_uplift: {
      description: "Indicates whether this ECT qualifies for an uplift payment due to sparsity. It does not apply to mentors.",
      type: :boolean,
      example: true
    },
    schedule_identifier: {
      description: "The schedule of the participant",
      type: :string,
      enum: Schedule.identifiers.keys,
      example: "ecf-standard-january"
    },
    delivery_partner_id: {
      description: "Unique ID of the delivery partner associated with the participant",
      type: :string,
      format: :uuid,
      example: "42a9ef2f-9059-400a-92ff-4830a629d0c5"
    },
    withdrawal: {
      description: "The details of a participant withdrawal",
      type: :object,
      required: %I[reason date],
      properties: {
        reason: {
          description: "The reason a participant was withdrawn",
          type: :string,
          enum: TrainingPeriod.withdrawal_reasons.keys.map(&:dasherize),
          example: "moved-school"
        },
        date: {
          description: "The date and time the participant was withdrawn",
          type: :string,
          format: "date-time",
          example: "2021-05-31T02:22:32.000Z"
        }
      },
      nullable: true
    },
    deferral: {
      description: "The details of a participant deferral",
      type: :object,
      required: %I[reason date],
      properties: {
        reason: {
          description: "The reason a participant was deferred",
          type: :string,
          enum: TrainingPeriod.deferral_reasons.keys.map(&:dasherize),
          example: "career-break"
        },
        date: {
          description: "The date and time the participant was deferred",
          type: :string,
          format: "date-time",
          example: "2021-05-31T02:22:32.000Z"
        }
      },
      nullable: true
    },
    created_at: {
      description: "The date and time the participant was created",
      type: :string,
      format: "date-time",
      example: "2023-01-01T00:00:00Z"
    },
    induction_end_date: {
      description: "The date when an ECT has passed or failed their induction.",
      type: :string,
      format: "date",
      example: "2023-01-01",
      nullable: true
    },
    overall_induction_start_date: {
      description: "The date the participant started their induction, reported by their appropriate body.",
      type: :string,
      format: "date",
      example: "2023-01-01",
      nullable: true
    },
    mentor_funding_end_date: {
      description: "The participant mentor training completion date",
      type: :string,
      format: "date",
      example: "2023-01-01",
      nullable: true
    },
    cohort_changed_after_payments_frozen: {
      description: "Identify participants that migrated to a new cohort as payments were frozen on their original cohort",
      type: :boolean,
      example: true
    },
    mentor_ineligible_for_funding_reason: {
      description: "The reason why funding for a mentor's training has ended",
      type: :string,
      enum: Teacher.mentor_became_ineligible_for_funding_reasons.keys,
      example: "completed_declaration_received"
    }
  }
}.freeze
