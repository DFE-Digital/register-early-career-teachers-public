require "swagger_helper"

describe "Participants endpoint", :with_metadata, openapi_spec: "v3/swagger.yaml" do
  include_context "with authorization for api doc request"

  let(:lead_provider_delivery_partnership) do
    FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider:
    )
  end
  let(:school_partnership) do
    FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
  end
  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      school: school_partnership.school,
      started_on: 6.months.ago
    )
  end
  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :ongoing,
      :with_school_partnership,
      school_partnership:,
      ect_at_school_period:,
      started_on: ect_at_school_period.started_on + 1.week
    )
  end
  let(:teacher) { ect_at_school_period.teacher }

  let(:resource) { teacher }

  it_behaves_like "an API index endpoint documentation",
                  {
                    url: "/api/v3/participants",
                    tag: "Participants",
                    resource_description: "participants",
                    response_schema_ref: "#/components/schemas/ParticipantsResponse",
                    filter_schema_ref: "#/components/schemas/ParticipantsFilter",
                    sorting_schema_ref: "#/components/schemas/SortingTimestamps",
                  } do
                    let(:response_example) do
                      extract_swagger_example(schema: "#/components/schemas/ParticipantsResponse", version: :v3).tap do |example|
                        example[:data][0][:attributes][:ecf_enrolments][0][:training_status] = "active"
                        example[:data][0][:attributes][:ecf_enrolments][0][:deferral] = nil
                        example[:data][0][:attributes][:ecf_enrolments][0][:withdrawal] = nil
                      end
                    end
                  end

  it_behaves_like "an API show endpoint documentation",
                  {
                    url: "/api/v3/participants/{id}",
                    tag: "Participants",
                    resource_description: "participant",
                    response_schema_ref: "#/components/schemas/ParticipantResponse",
                  } do
                    let(:response_example) do
                      extract_swagger_example(schema: "#/components/schemas/ParticipantResponse", version: :v3).tap do |example|
                        example[:data][:attributes][:ecf_enrolments][0][:training_status] = "active"
                        example[:data][:attributes][:ecf_enrolments][0][:deferral] = nil
                        example[:data][:attributes][:ecf_enrolments][0][:withdrawal] = nil
                      end
                    end
                  end

  it_behaves_like "an API update endpoint documentation",
                  {
                    url: "/api/v3/participants/{id}/withdraw",
                    tag: "Participants",
                    resource_description: "participant",
                    request_schema_ref: "#/components/schemas/ParticipantWithdrawRequest",
                    response_schema_ref: "#/components/schemas/ParticipantResponse",
                  } do
                    let(:response_example) do
                      extract_swagger_example(schema: "#/components/schemas/ParticipantResponse", version: :v3).tap do |example|
                        example[:data][:attributes][:ecf_enrolments][0][:training_status] = "withdrawn"
                        example[:data][:attributes][:ecf_enrolments][0][:deferral] = nil
                      end
                    end

                    let(:params) do
                      {
                        data: {
                          type: "participant-withdraw",
                          attributes: {
                            course_identifier: "ecf-induction",
                            reason: "moved-school"
                          }
                        }
                      }
                    end

                    let(:invalid_params) do
                      {
                        data: {
                          type: "participant-withdraw",
                          attributes: {
                            course_identifier: "something-invalid",
                            reason: "invalid-reason"
                          }
                        }
                      }
                    end
                  end

  it_behaves_like "an API update endpoint documentation",
                  {
                    url: "/api/v3/participants/{id}/defer",
                    tag: "Participants",
                    resource_description: "participant",
                    request_schema_ref: "#/components/schemas/ParticipantDeferRequest",
                    response_schema_ref: "#/components/schemas/ParticipantResponse",
                  } do
                    let(:response_example) do
                      extract_swagger_example(schema: "#/components/schemas/ParticipantResponse", version: :v3).tap do |example|
                        example[:data][:attributes][:ecf_enrolments][0][:training_status] = "deferred"
                        example[:data][:attributes][:ecf_enrolments][0][:withdrawal] = nil
                      end
                    end

                    let(:params) do
                      {
                        data: {
                          type: "participant-defer",
                          attributes: {
                            course_identifier: "ecf-induction",
                            reason: "career-break"
                          }
                        }
                      }
                    end

                    let(:invalid_params) do
                      {
                        data: {
                          type: "participant-defer",
                          attributes: {
                            course_identifier: "something-invalid",
                            reason: "invalid-reason"
                          }
                        }
                      }
                    end
                  end

  it_behaves_like "an API update endpoint documentation",
                  {
                    url: "/api/v3/participants/{id}/resume",
                    tag: "Participants",
                    resource_description: "participant",
                    request_schema_ref: "#/components/schemas/ParticipantResumeRequest",
                    response_schema_ref: "#/components/schemas/ParticipantResponse",
                  } do
                    before do
                      training_period.update!(
                        withdrawn_at: 1.day.ago,
                        finished_on: 1.day.ago,
                        withdrawal_reason: :other
                      )
                    end

                    let(:response_example) do
                      extract_swagger_example(schema: "#/components/schemas/ParticipantResponse", version: :v3).tap do |example|
                        example[:data][:attributes][:ecf_enrolments][0][:training_status] = "active"
                        example[:data][:attributes][:ecf_enrolments][0][:deferral] = nil
                        example[:data][:attributes][:ecf_enrolments][0][:withdrawal] = nil
                      end
                    end

                    let(:params) do
                      {
                        data: {
                          type: "participant-resume",
                          attributes: {
                            course_identifier: "ecf-induction",
                            reason: "moved-school"
                          }
                        }
                      }
                    end

                    let(:invalid_params) do
                      {
                        data: {
                          type: "participant-resume",
                          attributes: {
                            course_identifier: "something-invalid",
                            reason: "invalid-reason"
                          }
                        }
                      }
                    end
                  end
end
