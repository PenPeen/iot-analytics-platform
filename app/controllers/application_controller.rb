class ApplicationController < ActionController::API
  include ActionController::Caching

  # レスポンス時間の記録
  before_action :record_request_start_time
  after_action :log_request_duration

  # エラーハンドリング
  rescue_from StandardError, with: :handle_internal_error
  rescue_from Dynamoid::Errors::RecordNotFound, with: :handle_not_found
  rescue_from Dynamoid::Errors::DocumentNotValid, with: :handle_validation_error

  private

  def record_request_start_time
    @request_start_time = Time.current
  end

  def log_request_duration
    return unless @request_start_time

    duration = ((Time.current - @request_start_time) * 1000).round(2)
    logger.info "Request completed in #{duration}ms"
  end

  def handle_not_found(exception)
    render json: {
      error: 'Resource not found',
      message: exception.message
    }, status: :not_found
  end

  def handle_validation_error(exception)
    render json: {
      error: 'Validation failed',
      message: exception.message,
      details: exception.try(:record)&.errors&.full_messages
    }, status: :unprocessable_entity
  end

  def handle_internal_error(exception)
    logger.error "Internal error: #{exception.message}"
    logger.error exception.backtrace.join("\n")

    if Rails.env.development?
      render json: {
        error: 'Internal server error',
        message: exception.message,
        backtrace: exception.backtrace
      }, status: :internal_server_error
    else
      render json: {
        error: 'Internal server error',
        message: 'An unexpected error occurred'
      }, status: :internal_server_error
    end
  end

  def pagination_params
    {
      page: params[:page]&.to_i || 1,
      per_page: [params[:per_page]&.to_i || 20, 100].min
    }
  end

  def success_response(data, message = nil, status = :ok)
    response = { data: data }
    response[:message] = message if message
    render json: response, status: status
  end

  def error_response(message, status = :bad_request, details = nil)
    response = { error: message }
    response[:details] = details if details
    render json: response, status: status
  end
end
