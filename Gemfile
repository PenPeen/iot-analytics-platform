source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.8"

# Rails framework
gem "rails", "~> 7.1.0"

# Database
gem "pg", "~> 1.1"  # PostgreSQL for metadata
gem "dynamoid", "~> 3.9"  # DynamoDB ORM

# Redis
gem "redis", "~> 5.0"
gem "sidekiq", "~> 7.0"  # Background jobs

# Web server
gem "puma", "~> 6.0"

# Build JSON APIs
gem "jbuilder", "~> 2.7"

# AWS SDK
gem "aws-sdk-dynamodb", "~> 1.0"
gem "aws-sdk-s3", "~> 1.0"

# Boot time optimization
gem "bootsnap", ">= 1.16.0", require: false

# CORS handling
gem "rack-cors"

# Environment variables
gem "dotenv-rails"

# Serialization
gem "active_model_serializers", "~> 0.10.0"

# Time zone data
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :development, :test do
  # Debugging
  # gem "debug", platforms: %i[ mri mingw x64_mingw ]

  # Testing
  gem "rspec-rails", "~> 6.0"
  gem "factory_bot_rails", "~> 6.0"
  gem "faker", "~> 3.0"

  # Code analysis
  gem "rubocop", "~> 1.50", require: false
  gem "rubocop-rails", "~> 2.20", require: false
end

group :development do
  # Development server
  gem "spring"
  gem "spring-watcher-listen"

  # Documentation
  gem "yard", "~> 0.9"
end

group :test do
  # Test helpers
  gem "shoulda-matchers", "~> 5.0"
  gem "webmock", "~> 3.18"
  gem "vcr", "~> 6.0"
end
