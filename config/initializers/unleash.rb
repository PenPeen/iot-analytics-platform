# Unleash Feature Flags Configuration
require 'unleash'

# Initialize Unleash client
UNLEASH_CLIENT = Unleash::Client.new(
  url: ENV.fetch('UNLEASH_URL', 'http://localhost:4242/api/'),
  app_name: ENV.fetch('UNLEASH_APP_NAME', 'unleash-onboarding-ruby'),
  instance_id: ENV.fetch('UNLEASH_INSTANCE_ID', 'unleash-onboarding-ruby'),
  environment: Rails.env,
  custom_http_headers: {
    'Authorization' => ENV.fetch('UNLEASH_API_TOKEN', 'default:development.unleash-insecure-api-token')
  },
  refresh_interval: 15,
  metrics_interval: 60,
  retry_limit: 3,
  log_level: Rails.env.development? ? Logger::DEBUG : Logger::INFO,
  disable_client: Rails.env.test?,
  logger: Rails.logger
)

# Global helper method
def unleash
  UNLEASH_CLIENT
end

# Add to Rails application config
Rails.application.configure do
  config.unleash = UNLEASH_CLIENT
end
