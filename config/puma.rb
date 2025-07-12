# Puma configuration file for IoT Platform

# The directory to operate out of.
directory '/app'

# Use "path" as the file to store the server info state. This is
# used by "pumactl" to query and control the server.
state_path '/app/tmp/pids/puma.state'

# Redirect STDOUT and STDERR to files.
stdout_redirect '/app/log/puma.stdout.log', '/app/log/puma.stderr.log', true

# The default is "0.0.0.0:9292".
bind 'tcp://0.0.0.0:3000'

# === Worker process configuration ===

# Workers, minimum and maximum threads per worker
workers ENV.fetch("WEB_CONCURRENCY") { 2 }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# === Other Configuration ===
environment ENV.fetch("RAILS_ENV") { "development" }

# Store the pid of the server in the file at "path".
pidfile ENV.fetch("PIDFILE") { "/app/tmp/pids/server.pid" }

# === Cluster mode ===

# Code to run before doing a restart. This code should
# close log files, database connections, etc.
#
# This can be called multiple times to add code each time.
on_restart do
  puts 'Refreshing Gemfile'
  ENV["BUNDLE_GEMFILE"] = "/app/Gemfile"
end

# Code to run immediately before the master starts workers.
before_fork do
  # Worker setup can be done here if needed
end

# Code to run in a worker before it boots the app.
on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
