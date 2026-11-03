module API::Induction::ErrorHandleable
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::ParameterMissing, with: :bad_request_response
    rescue_from API::AppropriateBodies::Induction::TeacherNotFound, with: :not_found_response
    rescue_from API::AppropriateBodies::Induction::AlreadyClaimed, with: :conflict_response
    rescue_from API::AppropriateBodies::Induction::NotEligible, with: :unprocessable_content_response
    rescue_from API::AppropriateBodies::Induction::Invalid, with: :invalid_response
    rescue_from API::AppropriateBodies::Induction::TRSUnavailable, with: :service_unavailable_response
  end

private

  def bad_request_response
    render_errors([error("Bad request", detail: "Correct json data structure required. See API docs for reference.")], status: :bad_request)
  end

  def not_found_response(exception) = render_error("Resource not found", exception:, status: :not_found)

  def conflict_response(exception) = render_error("Conflict", exception:, status: :conflict)

  def unprocessable_content_response(exception) = render_error("Unprocessable content", exception:, status: :unprocessable_content)

  def service_unavailable_response(exception) = render_error("Service unavailable", exception:, status: :service_unavailable)

  def invalid_response(exception)
    render_errors(exception.errors.map { error(it.attribute, detail: it.message) }, status: :unprocessable_content)
  end

  def render_error(title, exception:, status:) = render_errors([error(title, detail: exception.message)], status:)

  def render_errors(errors, status:) = render(json: API::Induction::V1::ErrorSerializer.render({ errors: }), status:)

  def error(title, detail:) = { title:, detail: }
end
