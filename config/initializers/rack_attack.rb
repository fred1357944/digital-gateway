# Rack::Attack configuration for rate limiting and IP blocking
# https://github.com/rack/rack-attack

class Rack::Attack
  # Use Rails cache for throttle data
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # --------------------------------------------
  # Throttle: Limit requests per IP
  # --------------------------------------------

  # General API rate limit: 60 requests per minute per IP
  throttle("req/ip", limit: 60, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/assets", "/up")
  end

  # Stricter limit for authentication endpoints: 5 requests per 20 seconds
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Limit password reset requests: 5 per hour
  throttle("password_reset/ip", limit: 5, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  # Limit registration: 3 per hour per IP
  throttle("signup/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/users" && req.post?
      req.ip
    end
  end

  # --------------------------------------------
  # Throttle: API endpoints
  # --------------------------------------------

  # API rate limit: 100 requests per minute
  throttle("api/ip", limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Gemini API calls are expensive - limit to 10 per minute per user
  throttle("mvt_validation/user", limit: 10, period: 1.minute) do |req|
    if req.path.include?("/mvt") || req.path.include?("/validate")
      # Use session user_id or IP
      req.env["warden"]&.user&.id || req.ip
    end
  end

  # --------------------------------------------
  # Blocklist: Known bad actors
  # --------------------------------------------

  # Block requests from known bad IPs (add IPs as needed)
  # blocklist("block bad ips") do |req|
  #   ["1.2.3.4", "5.6.7.8"].include?(req.ip)
  # end

  # Block requests with suspicious user agents
  blocklist("block bad user agents") do |req|
    req.user_agent.present? && req.user_agent.match?(/curl|wget|python-requests/i) &&
      req.path.start_with?("/api/") &&
      !Rails.env.development?
  end

  # --------------------------------------------
  # Safelist: Always allow
  # --------------------------------------------

  # Allow health check endpoint
  safelist("allow health check") do |req|
    req.path == "/up"
  end

  # Allow localhost in development
  safelist("allow localhost") do |req|
    req.ip == "127.0.0.1" && Rails.env.development?
  end

  # --------------------------------------------
  # Custom Response
  # --------------------------------------------

  # Return 429 Too Many Requests with retry info
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    now = Time.current

    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => (match_data[:period] - (now.to_i % match_data[:period])).to_s
    }

    body = {
      error: "Rate limit exceeded",
      retry_after: headers["Retry-After"].to_i
    }.to_json

    [ 429, headers, [ body ] ]
  end
end

# Log blocked/throttled requests in production
ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
  Rails.logger.warn "[Rack::Attack] Throttled #{payload[:request].ip} - #{payload[:request].path}"
end
