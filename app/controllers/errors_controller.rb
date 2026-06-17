class ErrorsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def not_found
    respond_to do |format|
      format.json { render json: { error: "Resource not found" }, status: :not_found }
      format.any { render "not_found", formats: :html, status: :not_found }
    end
  end

  def unprocessable_content
    respond_to do |format|
      format.json { render json: { error: "Unprocessable content" }, status: :unprocessable_content }
      format.any { render "unprocessable_content", formats: :html, status: :unprocessable_content }
    end
  end

  def too_many_requests
    respond_to do |format|
      format.json { render json: { error: "Too many requests" }, status: :too_many_requests }
      format.any { render "too_many_requests", formats: :html, status: :too_many_requests }
    end
  end

  def internal_server_error
    respond_to do |format|
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
      format.any { render "internal_server_error", formats: :html, status: :internal_server_error }
    end
  end
end
