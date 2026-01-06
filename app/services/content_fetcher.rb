# frozen_string_literal: true

class ContentFetcher
  class FetchError < StandardError; end

  MAX_SIZE = 5.megabytes
  TIMEOUT = 30.seconds
  ALLOWED_CONTENT_TYPES = %w[
    text/html
    text/plain
    application/pdf
    application/json
  ].freeze

  def initialize(url)
    @url = url
    @uri = URI.parse(url)
  end

  def fetch
    validate_url!
    response = make_request

    unless response.is_a?(Net::HTTPSuccess)
      raise FetchError, "HTTP #{response.code}: #{response.message}"
    end

    extract_content(response)
  rescue URI::InvalidURIError => e
    raise FetchError, "Invalid URL: #{e.message}"
  rescue SocketError, Errno::ECONNREFUSED => e
    raise FetchError, "Connection failed: #{e.message}"
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise FetchError, "Request timeout: #{e.message}"
  end

  private

  def validate_url!
    raise FetchError, "URL is required" if @url.blank?
    raise FetchError, "Only HTTP(S) URLs are supported" unless %w[http https].include?(@uri.scheme)
    raise FetchError, "Invalid host" if @uri.host.blank?

    # Block private/local IPs (SSRF protection)
    resolved_ip = Resolv.getaddress(@uri.host) rescue nil
    if resolved_ip && private_ip?(resolved_ip)
      raise FetchError, "Access to private networks is not allowed"
    end
  end

  def private_ip?(ip)
    addr = IPAddr.new(ip)
    [
      IPAddr.new("10.0.0.0/8"),
      IPAddr.new("172.16.0.0/12"),
      IPAddr.new("192.168.0.0/16"),
      IPAddr.new("127.0.0.0/8"),
      IPAddr.new("169.254.0.0/16"),
      IPAddr.new("::1/128"),
      IPAddr.new("fc00::/7")
    ].any? { |range| range.include?(addr) }
  rescue IPAddr::InvalidAddressError
    false
  end

  def make_request
    http = Net::HTTP.new(@uri.host, @uri.port)
    http.use_ssl = @uri.scheme == "https"
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT
    http.max_retries = 1

    request = Net::HTTP::Get.new(@uri)
    request["User-Agent"] = "Digital Gateway Content Validator/1.0"
    request["Accept"] = ALLOWED_CONTENT_TYPES.join(", ")

    http.request(request)
  end

  def extract_content(response)
    content_type = response["Content-Type"]&.split(";")&.first&.strip
    body = response.body

    raise FetchError, "Response body is empty" if body.blank?
    raise FetchError, "Content too large (max #{MAX_SIZE / 1.megabyte}MB)" if body.bytesize > MAX_SIZE

    case content_type
    when "text/html"
      extract_text_from_html(body)
    when "application/pdf"
      extract_text_from_pdf(body)
    when "application/json"
      extract_text_from_json(body)
    else
      # Plain text or unknown - return as-is (truncated)
      body.truncate(50_000)
    end
  end

  def extract_text_from_html(html)
    # Remove script, style, and other non-content tags
    doc = html.gsub(/<script[^>]*>.*?<\/script>/mi, "")
              .gsub(/<style[^>]*>.*?<\/style>/mi, "")
              .gsub(/<[^>]+>/, " ")
              .gsub(/\s+/, " ")
              .strip

    doc.truncate(50_000)
  end

  def extract_text_from_pdf(pdf_data)
    # For MVP, just note it's a PDF and return metadata
    # In production, use pdf-reader gem or external service
    "[PDF Document - #{pdf_data.bytesize} bytes]"
  end

  def extract_text_from_json(json_string)
    data = JSON.parse(json_string)
    # Extract text content from JSON structure
    extract_text_values(data).join("\n").truncate(50_000)
  rescue JSON::ParserError
    json_string.truncate(50_000)
  end

  def extract_text_values(obj, texts = [])
    case obj
    when Hash
      obj.each_value { |v| extract_text_values(v, texts) }
    when Array
      obj.each { |v| extract_text_values(v, texts) }
    when String
      texts << obj if obj.length > 10 # Skip short strings
    end
    texts
  end
end
