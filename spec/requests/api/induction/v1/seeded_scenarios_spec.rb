RSpec.describe "seeded induction API scenarios", type: :request do
  include_context "seeded induction API request scenarios"

  let(:trs_full_name) { "Kirk Van Houten" }
  let(:date_of_birth) { "2001-05-13" }

  let(:training_programme) { "provider_led" }
  let(:number_of_terms) { 3.0 }

  let(:claimed_from) { Date.new(2026, 9, 1) }
  let(:released_on) { 1.day.ago.to_date }
  let(:reclaimed_from) { Date.current }
  let(:passed_on) { reclaimed_from }

  let(:claim_params) do
    { date_of_birth:, claimed_from: claimed_from.iso8601, training_programme: }
  end

  let(:release_params) do
    { released_on: released_on.iso8601, number_of_terms: }
  end

  let(:reclaim_params) do
    { date_of_birth:, claimed_from: reclaimed_from.iso8601, training_programme: }
  end

  let(:pass_params) do
    { passed_on: passed_on.iso8601, number_of_terms: }
  end

  describe "9001000 new_ect_provider_led_claim: new ECT for provider-led" do
    let(:trn) { "9001000" }

    it "can be claimed" do
      claim(trn, **claim_params)
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq(
        "trn" => trn,
        "full_name" => trs_full_name,
        "claimed_from" => claimed_from.iso8601,
        "training_programme" => training_programme
      )
    end
  end

  describe "9002000 new_ect_school_led_claim: new ECT for school-led" do
    let(:trn) { "9002000" }
    let(:training_programme) { "school_led" }

    it "can be claimed" do
      release(trn, **release_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )

      claim(trn, **claim_params)
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq(
        "trn" => trn,
        "full_name" => trs_full_name,
        "claimed_from" => claimed_from.iso8601,
        "training_programme" => training_programme
      )
    end
  end

  describe "9003000 released_ect_to_claim: previously released ECT" do
    let(:trn) { "9003000" }

    it "can be claimed" do
      release(trn, **release_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )

      claim(trn, **claim_params)
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq(
        "trn" => trn,
        "full_name" => trs_full_name,
        "claimed_from" => claimed_from.iso8601,
        "training_programme" => training_programme
      )
    end
  end

  describe "9004000 ongoing_provider_led_ect_to_pass: provider-led training" do
    let(:trn) { "9004000" }

    it "can be passed" do
      claim(trn, **claim_params)
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Conflict",
            "detail" => "The teacher already has an ongoing induction period with this appropriate body"
          }
        ]
      )

      pass(trn, **pass_params)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "trn" => trn,
        "full_name" => "ECT-Manager Ongoing-provider-led-ect-to-pass-0",
        "passed_on" => passed_on.iso8601,
        "number_of_terms" => number_of_terms
      )
    end
  end

  describe "9005000 ongoing_school_led_ect_to_pass: school-led training" do
    let(:trn) { "9005000" }

    it "can be passed" do
      claim(trn, **claim_params)
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Conflict",
            "detail" => "The teacher already has an ongoing induction period with this appropriate body"
          }
        ]
      )

      pass(trn, **pass_params)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({
        "trn" => trn,
        "full_name" => "ECT-Manager Ongoing-school-led-ect-to-pass-0",
        "number_of_terms" => number_of_terms,
        "passed_on" => passed_on.iso8601,
      })
    end
  end

  describe "9006000 ongoing_provider_led_ect_to_release: ongoing induction" do
    let(:trn) { "9006000" }

    it "can be released" do
      claim(trn, **claim_params)
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Conflict",
            "detail" => "The teacher already has an ongoing induction period with this appropriate body"
          }
        ]
      )

      release(trn, **release_params)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({
        "trn" => trn,
        "full_name" => "ECT-Manager Ongoing-provider-led-ect-to-release-0",
        "number_of_terms" => number_of_terms,
        "released_on" => released_on.iso8601,
      })
    end
  end

  describe "9007000 ongoing_provider_led_ect_with_another_ab: held by another body" do
    let(:trn) { "9007000" }

    it "cannot be claimed, released or passed" do
      claim(trn, **claim_params)
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Conflict",
            "detail" => "The teacher has an ongoing induction period with another appropriate body"
          }
        ]
      )

      release(trn, **release_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )

      pass(trn, **pass_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )
    end
  end

  describe "9008000 ect_who_has_passed_induction: induction already passed" do
    let(:trn) { "9008000" }

    before do
      allow(TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new(induction_status: "Passed"))
    end

    it "cannot be claimed, released or passed" do
      claim(trn, **claim_params)
      expect(response).to have_http_status(:unprocessable_content)

      release(trn, **release_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )

      pass(trn, **pass_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )
    end
  end

  describe "9009000 ect_who_has_failed_induction: induction already failed" do
    let(:trn) { "9009000" }

    before do
      allow(TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new(induction_status: "Failed"))
    end

    it "cannot be claimed, released or passed" do
      claim(trn, **claim_params)
      expect(response).to have_http_status(:unprocessable_content)

      release(trn, **release_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )

      pass(trn, **pass_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )
    end
  end

  describe "9010000 ect_without_qts: no QTS" do
    let(:trn) { "9010000" }

    before do
      allow(TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new(has_qts: false))
    end

    it "cannot be claimed, released or passed" do
      claim(trn, **claim_params)
      expect(response).to have_http_status(:unprocessable_content)

      release(trn, **release_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )

      pass(trn, **pass_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )
    end
  end

  describe "9011000 ect_exempt_from_induction: exempt from induction" do
    let(:trn) { "9011000" }

    before do
      allow(TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new(induction_status: "Exempt"))
    end

    it "cannot be claimed, released or passed" do
      claim(trn, **claim_params)
      expect(response).to have_http_status(:unprocessable_content)

      release(trn, **release_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )

      pass(trn, **pass_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )
    end
  end

  describe "9012000 ect_prohibited_from_teaching: prohibited from teaching" do
    let(:trn) { "9012000" }

    before do
      allow(TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new(is_prohibited_from_teaching: true))
    end

    it "cannot be claimed, released or passed" do
      claim(trn, **claim_params)
      expect(response).to have_http_status(:unprocessable_content)

      release(trn, **release_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )

      pass(trn, **pass_params)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "title" => "Resource not found",
            "detail" => "Nothing could be found for the provided details"
          }
        ]
      )
    end
  end

  describe "9013000 ect_ongoing_to_be_released_and_claimed: ongoing and releasable" do
    let(:trn) { "9013000" }

    it "can be released and then claimed" do
      release(trn, **release_params)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({
        "trn" => trn,
        "full_name" => "ECT-Manager Ect-ongoing-to-be-released-and-claimed-0",
        "number_of_terms" => number_of_terms,
        "released_on" => released_on.iso8601,
      })

      claim(trn, **reclaim_params)
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq({
        "trn" => trn,
        "full_name" => trs_full_name,
        "training_programme" => training_programme,
        "claimed_from" => reclaimed_from.iso8601,
      })
    end
  end
end
