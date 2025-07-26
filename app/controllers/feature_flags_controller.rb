class FeatureFlagsController < ApplicationController
  # Feature Flagsの状態を確認するエンドポイント
  def index
    feature_flags = {
      new_dashboard_ui: unleash.is_enabled?('new_dashboard_ui'),
      advanced_analytics: unleash.is_enabled?('advanced_analytics'),
      real_time_alerts: unleash.is_enabled?('real_time_alerts'),
      device_management_v2: unleash.is_enabled?('device_management_v2'),
      experimental_features: unleash.is_enabled?('experimental_features')
    }

    render json: {
      status: 'success',
      feature_flags: feature_flags,
      unleash_client_info: {
        app_name: ENV['UNLEASH_APP_NAME'],
        instance_id: ENV['UNLEASH_INSTANCE_ID'],
        url: ENV['UNLEASH_URL']
      }
    }
  end

  # 特定のFeature Flagの状態を確認
  def show
    flag_name = params[:name]
    user_id = params[:user_id]
    context = build_context(params[:context])

    is_enabled = if user_id.present?
      unleash.is_enabled?(flag_name, user_id: user_id, context: context)
    else
      unleash.is_enabled?(flag_name, context: context)
    end

    render json: {
      flag_name: flag_name,
      enabled: is_enabled,
      context: context
    }
  end

  private

  def build_context(context_params)
    return {} unless context_params.present?

    context = {}
    context[:device_type] = context_params[:device_type] if context_params[:device_type]
    context[:environment] = Rails.env
    context[:session_id] = session.id if session.present?
    context
  end
end
