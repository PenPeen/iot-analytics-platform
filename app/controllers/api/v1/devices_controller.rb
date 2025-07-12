class Api::V1::DevicesController < ApplicationController
  before_action :set_device, only: [:show, :update, :destroy]

  # GET /api/v1/devices
  def index
    devices = Device.all.to_a

    # フィルタリング（Dynamoidでは手動でフィルタリング）
    if params[:status].present?
      devices = devices.select { |device| device.status == params[:status] }
    end

    if params[:device_type].present?
      devices = devices.select { |device| device.device_type == params[:device_type] }
    end

    # 位置検索
    if params[:latitude].present? && params[:longitude].present?
      radius = params[:radius]&.to_f || 1.0
      devices = Device.find_by_location(
        params[:latitude].to_f,
        params[:longitude].to_f,
        radius
      )
    end

    # キャッシュ対応
    cache_key = "devices_index_#{params.permit(:status, :device_type, :latitude, :longitude, :radius).to_h.to_query}"
    devices_data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      devices.map(&:as_json)
    end

    success_response(devices_data)
  end

  # GET /api/v1/devices/:id
  def show
    # キャッシュ対応
    device_data = Rails.cache.fetch("device_#{params[:id]}", expires_in: 10.minutes) do
      @device.as_json
    end

    success_response(device_data)
  end

  # POST /api/v1/devices
  def create
    device = Device.new(device_params)

    if device.save
      # キャッシュクリア
      Rails.cache.delete_matched("devices_*")

      success_response(device.as_json, 'Device created successfully', :created)
    else
      error_response('Failed to create device', :unprocessable_entity, device.errors.full_messages)
    end
  end

  # PATCH/PUT /api/v1/devices/:id
  def update
    if @device.update(device_params)
      # キャッシュクリア
      Rails.cache.delete("device_#{params[:id]}")
      Rails.cache.delete_matched("devices_*")

      success_response(@device.as_json, 'Device updated successfully')
    else
      error_response('Failed to update device', :unprocessable_entity, @device.errors.full_messages)
    end
  end

  # DELETE /api/v1/devices/:id
  def destroy
    @device.destroy

    # キャッシュクリア
    Rails.cache.delete("device_#{params[:id]}")
    Rails.cache.delete_matched("devices_*")

    success_response(nil, 'Device deleted successfully')
  end

  # GET /api/v1/devices/:id/sensor_data
  def sensor_data
    set_device

    # 日付範囲の設定
    start_date = parse_date_param(:start_date) || 1.day.ago
    end_date = parse_date_param(:end_date) || Time.current
    limit = [params[:limit]&.to_i || 100, 1000].min

    # キャッシュキー
    cache_key = "sensor_data_#{@device.device_id}_#{start_date.to_i}_#{end_date.to_i}_#{limit}"

    sensor_data = Rails.cache.fetch(cache_key, expires_in: 1.minute) do
      if params[:latest] == 'true'
        SensorData.latest_by_device(@device.device_id, limit)
      else
        SensorData.find_by_device_and_date_range(@device.device_id, start_date, end_date)
      end.map(&:as_json)
    end

    success_response(sensor_data)
  end

  # POST /api/v1/devices/:id/sensor_data
  def create_sensor_data
    set_device

    sensor_data = SensorData.create_from_device_reading(
      @device.device_id,
      sensor_data_params.merge(timestamp: Time.current)
    )

    if sensor_data.save
      # 非同期でデータ処理ジョブを実行
      ProcessSensorDataJob.perform_async(@device.device_id, sensor_data.id)

      # キャッシュクリア
      Rails.cache.delete_matched("sensor_data_#{@device.device_id}_*")

      success_response(sensor_data.as_json, 'Sensor data recorded successfully', :created)
    else
      error_response('Failed to record sensor data', :unprocessable_entity, sensor_data.errors.full_messages)
    end
  end

  # GET /api/v1/devices/:id/analytics
  def analytics
    set_device

    date = parse_date_param(:date) || Date.current

    # キャッシュキー
    cache_key = "analytics_#{@device.device_id}_#{date.to_s}"

    analytics_data = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      {
        device: @device.as_json,
        date: date,
        hourly_aggregation: SensorData.aggregate_hourly(@device.device_id, date),
        data_count: SensorData.find_by_device_and_date_range(
          @device.device_id,
          date.beginning_of_day,
          date.end_of_day
        ).size,
        latest_reading: SensorData.latest_by_device(@device.device_id, 1).first&.as_json
      }
    end

    success_response(analytics_data)
  end

  # GET /api/v1/devices/status_summary
  def status_summary
    cache_key = "device_status_summary"

    summary = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      devices = Device.all.to_a
      {
        total: devices.size,
        active: devices.select(&:active?).size,
        inactive: devices.select(&:inactive?).size,
        maintenance: devices.select(&:in_maintenance?).size,
        error: devices.select(&:error?).size,
        by_type: devices.group_by(&:device_type).transform_values(&:size)
      }
    end

    success_response(summary)
  end

  private

  def set_device
    @device = Device.find(params[:id] || params[:device_id])
  end

  def device_params
    params.require(:device).permit(
      :device_id, :name, :device_type, :manufacturer, :model,
      :firmware_version, :status, :description, :installation_date,
      tags: [],
      location: [:latitude, :longitude]
    )
  end

  def sensor_data_params
    params.require(:sensor_data).permit(
      :temperature, :humidity, :pressure, :co2_level,
      :light_intensity, :soil_moisture, :ph_level,
      :battery_level, :signal_strength, :data_quality,
      location: [:latitude, :longitude],
      raw_data: {}
    )
  end

  def parse_date_param(param_name)
    return nil unless params[param_name].present?

    Time.parse(params[param_name])
  rescue ArgumentError
    nil
  end
end
