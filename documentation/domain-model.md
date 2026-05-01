```mermaid
erDiagram
  Contract_BandedFeeStructure_Band {
    integer id
    integer banded_fee_structure_id
    datetime created_at
    decimal fee_per_declaration
    integer max_declarations
    integer min_declarations
    decimal output_fee_ratio
    decimal service_fee_ratio
    datetime updated_at
  }
  Contract_BandedFeeStructure_Band }o--|| Contract_BandedFeeStructure : belongs_to
  Contract_FlatRateFeeStructure {
    integer id
    datetime created_at
    decimal fee_per_declaration
    integer recruitment_target
    datetime updated_at
  }
  Contract_BandedFeeStructure {
    integer id
    datetime created_at
    decimal monthly_service_fee
    integer recruitment_target
    decimal setup_fee
    datetime updated_at
    decimal uplift_fee_per_declaration
  }
  User {
    integer id
    datetime created_at
    citext email
    string name
    integer otp_school_urn
    string otp_secret
    datetime otp_verified_at
    enum role
    datetime updated_at
  }
  TrainingPeriod {
    integer id
    datetime api_transfer_updated_at
    datetime created_at
    enum deferral_reason
    datetime deferred_at
    uuid ecf_end_induction_record_id
    uuid ecf_start_induction_record_id
    integer ect_at_school_period_id
    integer expression_of_interest_id
    date finished_on
    integer mentor_at_school_period_id
    daterange range
    integer schedule_id
    integer school_partnership_id
    date started_on
    enum training_programme
    datetime updated_at
    enum withdrawal_reason
    datetime withdrawn_at
  }
  TrainingPeriod }o--|| ECTAtSchoolPeriod : belongs_to
  TrainingPeriod }o--|| MentorAtSchoolPeriod : belongs_to
  TrainingPeriod }o--|| SchoolPartnership : belongs_to
  TrainingPeriod }o--|| Schedule : belongs_to
  TrainingPeriod }o--|| ActiveLeadProvider : belongs_to
  TeacherMigrationFailure {
    integer id
    datetime created_at
    string message
    uuid migration_item_id
    string migration_item_type
    string migration_mode
    string model
    integer teacher_id
    datetime updated_at
  }
  TeacherMigrationFailure }o--|| Teacher : belongs_to
  TeacherIdChange {
    integer id
    uuid api_from_teacher_id
    uuid api_to_teacher_id
    datetime created_at
    uuid ecf_id
    integer teacher_id
    datetime updated_at
  }
  TeacherIdChange }o--|| Teacher : belongs_to
  Statement {
    integer id
    uuid api_id
    datetime api_updated_at
    integer contract_id
    datetime created_at
    date deadline_date
    enum fee_type
    datetime marked_as_paid_at
    integer month
    date payment_date
    enum status
    datetime updated_at
    integer year
  }
  Statement }o--|| Contract : belongs_to
  SchoolPartnership {
    integer id
    uuid api_id
    datetime api_updated_at
    datetime created_at
    integer lead_provider_delivery_partnership_id
    integer school_id
    datetime updated_at
  }
  SchoolPartnership }o--|| LeadProviderDeliveryPartnership : belongs_to
  SchoolPartnership }o--|| School : belongs_to
  SchoolFundingEligibility {
    integer id
    integer contract_period_year
    datetime created_at
    boolean pupil_premium_uplift
    integer school_urn
    boolean sparsity_uplift
    datetime updated_at
  }
  SchoolFundingEligibility }o--|| School : belongs_to
  SchoolFundingEligibility }o--|| ContractPeriod : belongs_to
  School {
    integer id
    uuid api_id
    datetime created_at
    citext induction_tutor_email
    integer induction_tutor_last_nominated_in
    string induction_tutor_name
    integer last_chosen_appropriate_body_id
    integer last_chosen_lead_provider_id
    enum last_chosen_training_programme
    boolean marked_as_eligible
    datetime updated_at
    integer urn
  }
  School }o--|| DfESignInOrganisation : belongs_to
  School }o--|| AppropriateBodyPeriod : belongs_to
  School }o--|| LeadProvider : belongs_to
  School }o--|| ContractPeriod : belongs_to
  Schedule {
    integer id
    integer contract_period_year
    datetime created_at
    enum identifier
    datetime updated_at
  }
  Schedule }o--|| ContractPeriod : belongs_to
  Region {
    integer id
    integer appropriate_body_id
    string code
    datetime created_at
    array[string] districts
    datetime updated_at
  }
  Region }o--|| AppropriateBody : belongs_to
  PendingInductionSubmissionBatch {
    integer id
    integer appropriate_body_period_id
    enum batch_status
    enum batch_type
    integer claimed_count
    datetime created_at
    jsonb data
    string error_message
    integer errored_count
    string file_name
    integer file_size
    string file_type
    integer passed_count
    integer processed_count
    integer released_count
    datetime updated_at
    integer uploaded_count
  }
  PendingInductionSubmissionBatch }o--|| AppropriateBodyPeriod : belongs_to
  Teacher {
    integer id
    uuid api_ect_training_record_id
    uuid api_id
    uuid api_mentor_training_record_id
    datetime api_unfunded_mentor_updated_at
    datetime api_updated_at
    string corrected_name
    datetime created_at
    date ect_became_ineligible_for_funding_on
    datetime ect_first_became_eligible_for_training_at
    integer ect_payments_frozen_year
    date mentor_became_ineligible_for_funding_on
    enum mentor_became_ineligible_for_funding_reason
    datetime mentor_first_became_eligible_for_training_at
    integer mentor_payments_frozen_year
    enum migration_mode
    string trn
    boolean trnless
    datetime trs_data_last_refreshed_at
    boolean trs_deactivated
    string trs_first_name
    date trs_induction_completed_date
    date trs_induction_start_date
    string trs_induction_status
    date trs_initial_teacher_training_end_date
    string trs_initial_teacher_training_provider_name
    string trs_last_name
    boolean trs_not_found
    date trs_qts_awarded_on
    string trs_qts_status_description
    datetime updated_at
  }
  PendingInductionSubmission {
    integer id
    integer appropriate_body_period_id
    datetime confirmed_at
    datetime created_at
    date date_of_birth
    datetime delete_at
    array[string] error_messages
    string establishment_id
    date fail_confirmation_sent_on
    date finished_on
    enum induction_programme
    float number_of_terms
    enum outcome
    integer pending_induction_submission_batch_id
    date started_on
    enum training_programme
    string trn
    jsonb trs_alerts
    date trs_date_of_birth
    citext trs_email_address
    string trs_first_name
    date trs_induction_completed_date
    date trs_induction_start_date
    string trs_induction_status
    date trs_initial_teacher_training_end_date
    string trs_initial_teacher_training_provider_name
    string trs_last_name
    boolean trs_prohibited_from_teaching
    date trs_qts_awarded_on
    string trs_qts_status_description
    datetime updated_at
  }
  PendingInductionSubmission }o--|| AppropriateBodyPeriod : belongs_to
  PendingInductionSubmission }o--|| PendingInductionSubmissionBatch : belongs_to
  Milestone {
    integer id
    datetime created_at
    enum declaration_type
    date milestone_date
    integer schedule_id
    date start_date
    datetime updated_at
  }
  Milestone }o--|| Schedule : belongs_to
  MentorshipPeriod {
    integer id
    datetime created_at
    uuid ecf_end_induction_record_id
    uuid ecf_start_induction_record_id
    integer ect_at_school_period_id
    date finished_on
    integer mentor_at_school_period_id
    daterange range
    date started_on
    datetime updated_at
  }
  MentorshipPeriod }o--|| ECTAtSchoolPeriod : belongs_to
  MentorshipPeriod }o--|| MentorAtSchoolPeriod : belongs_to
  MentorAtSchoolPeriod {
    integer id
    datetime created_at
    uuid ecf_end_induction_record_id
    uuid ecf_start_induction_record_id
    citext email
    date finished_on
    daterange range
    integer reported_leaving_by_school_id
    integer school_id
    date started_on
    integer teacher_id
    datetime updated_at
  }
  MentorAtSchoolPeriod }o--|| School : belongs_to
  MentorAtSchoolPeriod }o--|| Teacher : belongs_to
  LegacyAppropriateBody {
    integer id
    integer appropriate_body_period_id
    enum body_type
    datetime created_at
    uuid dqt_id
    string name
    datetime updated_at
  }
  LegacyAppropriateBody }o--|| AppropriateBodyPeriod : belongs_to
  LeadProviderDeliveryPartnership {
    integer id
    integer active_lead_provider_id
    datetime created_at
    integer delivery_partner_id
    uuid ecf_id
    datetime updated_at
  }
  LeadProviderDeliveryPartnership }o--|| ActiveLeadProvider : belongs_to
  LeadProviderDeliveryPartnership }o--|| DeliveryPartner : belongs_to
  LeadProvider {
    integer id
    datetime created_at
    uuid ecf_cpd_lead_provider_id
    uuid ecf_id
    string name
    datetime updated_at
    boolean vat_registered
  }
  InductionPeriod {
    integer id
    integer appropriate_body_period_id
    datetime created_at
    date fail_confirmation_sent_on
    date finished_on
    enum induction_programme
    float number_of_terms
    enum outcome
    daterange range
    date started_on
    integer teacher_id
    enum training_programme
    datetime updated_at
  }
  InductionPeriod }o--|| AppropriateBodyPeriod : belongs_to
  InductionPeriod }o--|| Teacher : belongs_to
  InductionExtension {
    integer id
    datetime created_at
    float number_of_terms
    integer teacher_id
    datetime updated_at
  }
  InductionExtension }o--|| Teacher : belongs_to
  ECTAtSchoolPeriod {
    integer id
    datetime created_at
    uuid ecf_end_induction_record_id
    uuid ecf_start_induction_record_id
    citext email
    date finished_on
    daterange range
    integer reported_leaving_by_school_id
    integer school_id
    integer school_reported_appropriate_body_id
    date started_on
    integer teacher_id
    datetime updated_at
    enum working_pattern
  }
  ECTAtSchoolPeriod }o--|| School : belongs_to
  ECTAtSchoolPeriod }o--|| Teacher : belongs_to
  ECTAtSchoolPeriod }o--|| AppropriateBodyPeriod : belongs_to
  DfESignInOrganisation {
    integer id
    string address
    string category
    string company_registration_number
    datetime created_at
    datetime first_authenticated_at
    datetime last_authenticated_at
    string name
    string organisation_type
    string status
    datetime updated_at
    string urn
    uuid uuid
  }
  DeliveryPartner {
    integer id
    uuid api_id
    datetime api_updated_at
    datetime created_at
    string name
    datetime updated_at
  }
  DataMigrationTeacherCombination {
    integer id
    uuid api_id
    datetime created_at
    jsonb ecf1_ect_combinations
    integer ecf1_ect_combinations_count
    uuid ecf1_ect_profile_id
    jsonb ecf1_mentor_combinations
    integer ecf1_mentor_combinations_count
    uuid ecf1_mentor_profile_id
    jsonb ecf1_mentorships
    integer ecf1_mentorships_count
    jsonb ecf2_ect_combinations
    integer ecf2_ect_combinations_count
    jsonb ecf2_mentor_combinations
    integer ecf2_mentor_combinations_count
    jsonb ecf2_mentorships
    integer ecf2_mentorships_count
    string migration_mode
    datetime updated_at
  }
  DataMigrationFailedMentorship {
    integer id
    datetime created_at
    uuid ecf_end_induction_record_id
    uuid ecf_start_induction_record_id
    uuid ect_participant_profile_id
    text failure_message
    date finished_on
    uuid mentor_participant_profile_id
    string migration_mode
    date started_on
    datetime updated_at
  }
  DataMigrationFailedCombination {
    integer id
    integer cohort_year
    datetime created_at
    string delivery_partner_name
    datetime end_date
    text failure_message
    uuid induction_record_id
    string induction_status
    string lead_provider_name
    uuid mentor_profile_id
    string migration_mode
    string preferred_identity_email
    uuid profile_id
    string profile_type
    integer schedule_cohort_year
    uuid schedule_id
    string schedule_identifier
    string schedule_name
    string school_urn
    datetime start_date
    string training_programme
    string training_status
    string trn
    datetime updated_at
  }
  ContractPeriod {
    integer year
    datetime created_at
    boolean detailed_evidence_types_enabled
    boolean enabled
    date finished_on
    boolean mentor_funding_enabled
    datetime payments_frozen_at
    daterange range
    date started_on
    datetime updated_at
    boolean uplift_fees_enabled
  }
  Contract {
    integer id
    integer active_lead_provider_id
    integer banded_fee_structure_id
    enum contract_type
    datetime created_at
    string ecf_contract_version
    string ecf_mentor_contract_version
    integer flat_rate_fee_structure_id
    datetime updated_at
    decimal vat_rate
  }
  Contract }o--|| ActiveLeadProvider : belongs_to
  Contract }o--|| Contract_FlatRateFeeStructure : belongs_to
  Contract }o--|| Contract_BandedFeeStructure : belongs_to
  AppropriateBodyPeriod {
    integer id
    integer appropriate_body_id
    enum body_type
    datetime created_at
    uuid dfe_sign_in_organisation_id
    uuid dqt_id
    string name
    datetime updated_at
  }
  AppropriateBodyPeriod }o--|| DfESignInOrganisation : belongs_to
  AppropriateBodyPeriod }o--|| AppropriateBody : belongs_to
  AppropriateBody {
    integer id
    datetime created_at
    integer dfe_sign_in_organisation_id
    string name
    datetime updated_at
  }
  AppropriateBody }o--|| DfESignInOrganisation : belongs_to
  ActiveLeadProvider {
    integer id
    integer contract_period_year
    datetime created_at
    integer lead_provider_id
    datetime updated_at
  }
  ActiveLeadProvider }o--|| ContractPeriod : belongs_to
  ActiveLeadProvider }o--|| LeadProvider : belongs_to
  SupportQuery {
    integer id
    datetime created_at
    string email
    text message
    string name
    string school_name
    integer school_urn
    string state
    datetime updated_at
    integer zendesk_id
  }
  Declaration {
    integer id
    uuid api_id
    datetime api_updated_at
    integer clawback_statement_id
    enum clawback_status
    datetime created_at
    datetime declaration_date
    enum declaration_type
    integer delivery_partner_when_created_id
    enum evidence_type
    integer mentorship_period_id
    integer payment_statement_id
    enum payment_status
    boolean pupil_premium_uplift
    boolean sparsity_uplift
    integer training_period_id
    datetime updated_at
    datetime voided_by_user_at
    integer voided_by_user_id
  }
  Declaration }o--|| TrainingPeriod : belongs_to
  Declaration }o--|| User : belongs_to
  Declaration }o--|| MentorshipPeriod : belongs_to
  Declaration }o--|| DeliveryPartner : belongs_to
  Declaration }o--|| Statement : belongs_to
  Declaration }o--|| Statement : belongs_to
  Metadata_TeacherLeadProvider {
    integer id
    uuid api_mentor_id
    datetime created_at
    boolean involved_in_school_transfer
    integer latest_ect_contract_period_year
    integer latest_ect_training_period_id
    integer latest_mentor_contract_period_year
    integer latest_mentor_training_period_id
    integer lead_provider_id
    integer teacher_id
    datetime updated_at
  }
  Metadata_TeacherLeadProvider }o--|| Teacher : belongs_to
  Metadata_TeacherLeadProvider }o--|| LeadProvider : belongs_to
  Metadata_TeacherLeadProvider }o--|| TrainingPeriod : belongs_to
  Metadata_TeacherLeadProvider }o--|| TrainingPeriod : belongs_to
  Metadata_TeacherLeadProvider }o--|| ContractPeriod : belongs_to
  Metadata_TeacherLeadProvider }o--|| ContractPeriod : belongs_to
  Metadata_SchoolLeadProviderContractPeriod {
    integer id
    integer contract_period_year
    datetime created_at
    boolean expression_of_interest_or_school_partnership
    integer lead_provider_id
    integer school_id
    datetime updated_at
  }
  Metadata_SchoolLeadProviderContractPeriod }o--|| School : belongs_to
  Metadata_SchoolLeadProviderContractPeriod }o--|| LeadProvider : belongs_to
  Metadata_SchoolLeadProviderContractPeriod }o--|| ContractPeriod : belongs_to
  Metadata_SchoolContractPeriod {
    integer id
    datetime api_updated_at
    integer contract_period_year
    datetime created_at
    boolean in_partnership
    enum induction_programme_choice
    integer school_id
    datetime updated_at
  }
  Metadata_SchoolContractPeriod }o--|| School : belongs_to
  Metadata_SchoolContractPeriod }o--|| ContractPeriod : belongs_to
  Metadata_DeliveryPartnerLeadProvider {
    integer id
    array[integer] contract_period_years
    datetime created_at
    integer delivery_partner_id
    integer lead_provider_id
    datetime updated_at
  }
  Metadata_DeliveryPartnerLeadProvider }o--|| DeliveryPartner : belongs_to
  Metadata_DeliveryPartnerLeadProvider }o--|| LeadProvider : belongs_to
```