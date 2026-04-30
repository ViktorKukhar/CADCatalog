# DataSanitizer - Comprehensive data sanitization service
# Protects against SQL injection, XSS, and malicious input
# Uses Rails framework APIs for secure data processing

class DataSanitizer
  # Sanitizes text input to prevent XSS attacks
  # Removes dangerous HTML tags while preserving safe formatting
  # Uses ActionController::Base.helpers for Rails' built-in sanitization
  def self.sanitize_text(input)
    return nil if input.nil?
    
    input = input.to_s.strip
    return '' if input.empty?
    
    # Use Rails' sanitize helper to remove dangerous HTML/JavaScript
    # This prevents XSS attacks by stripping malicious tags
    ActionController::Base.helpers.sanitize(input, tags: [], attributes: [])
  end

  # Sanitizes HTML content while allowing safe tags
  # Used for descriptions that may contain formatting
  # Whitelists only safe HTML tags to prevent XSS
  def self.sanitize_html(input, allowed_tags = %w[p br strong em ul ol li])
    return nil if input.nil?
    
    input = input.to_s.strip
    return '' if input.empty?
    
    # Use Rails' ActionView sanitizer with whitelist of allowed tags
    # Prevents XSS by only allowing specified HTML tags
    ActionController::Base.helpers.sanitize(
      input,
      tags: allowed_tags,
      attributes: %w[class id]
    )
  end

  # Sanitizes input for use in SQL queries (though parameterized queries are preferred)
  # This is a defensive layer - parameterized queries (ActiveRecord) should be primary defense
  def self.sanitize_sql_input(input)
    return nil if input.nil?
    
    input = input.to_s.strip
    return '' if input.empty?
    
    # Remove potentially dangerous SQL characters
    # While ActiveRecord parameterized queries are the primary defense,
    # this provides additional protection against SQL injection
    input.gsub(/[;'"]/, '')
  end

  # Sanitizes search queries to prevent injection attacks
  # Allows alphanumeric, spaces, and safe symbols only
  def self.sanitize_search_query(input)
    return nil if input.nil?
    
    input = input.to_s.strip
    return '' if input.empty?
    
    # Allow alphanumeric, spaces, and common search symbols
    # Removes potentially dangerous characters from search input
    input.gsub(/[^a-zA-Z0-9\s\-_.]/, '')
  end

  # Sanitizes tag/category input
  # Prevents SQL injection and XSS through tag manipulation
  def self.sanitize_tag(input)
    return nil if input.nil?
    
    input = input.to_s.strip.downcase
    return '' if input.empty?
    
    # Allow only alphanumeric, hyphens, and underscores
    # Prevents injection through tag names
    sanitized = input.gsub(/[^a-z0-9\-_]/, '')
    
    # Additional length validation for safety
    sanitized[0..49]  # Max 50 characters
  end

  # Sanitizes numeric input to prevent injection through numeric fields
  def self.sanitize_numeric(input, allow_negative = false)
    return nil if input.nil?
    
    input = input.to_s.strip
    return nil if input.empty?
    
    # Remove all non-numeric characters except decimal point and minus
    if allow_negative
      sanitized = input.gsub(/[^\d\-.]/, '')
    else
      sanitized = input.gsub(/[^\d.]/, '')
    end
    
    # Convert to float and validate
    begin
      float_value = Float(sanitized)
      float_value
    rescue ArgumentError
      nil
    end
  end

  # Sanitizes email input to prevent injection and ensure valid format
  def self.sanitize_email(input)
    return nil if input.nil?
    
    input = input.to_s.strip.downcase
    return nil if input.empty?
    
    # Basic email sanitization: remove dangerous characters
    # but preserve valid email format
    sanitized = input.gsub(/[^a-z0-9@.\-_+]/, '')
    
    # Validate email format
    if sanitized =~ /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
      sanitized
    else
      nil
    end
  end

  # Sanitizes file names to prevent directory traversal and injection attacks
  def self.sanitize_filename(input)
    return nil if input.nil?
    
    input = input.to_s.strip
    return nil if input.empty?
    
    # Remove directory traversal attempts and dangerous characters
    sanitized = input.gsub(/[^\w\s\-.]/, '')
    
    # Remove path traversal attempts
    sanitized = sanitized.gsub(/\.\.[\/\\]/, '')
    
    # Prevent empty result
    sanitized.empty? ? 'file' : sanitized[0..255]  # Max 255 characters
  end

  # Sanitizes URL to prevent injection and malicious links
  def self.sanitize_url(input)
    return nil if input.nil?
    
    input = input.to_s.strip
    return nil if input.empty?
    
    # Whitelist only safe URL schemes
    allowed_schemes = %w[http https ftp ftps]
    
    begin
      uri = URI.parse(input)
      
      # Check if scheme is allowed (prevents javascript: and data: URIs)
      unless allowed_schemes.include?(uri.scheme&.downcase)
        return nil
      end
      
      input
    rescue URI::InvalidURIError
      nil
    end
  end

  # Sanitizes string for safe display in HTML without escaping
  # Removes any potentially dangerous content
  def self.sanitize_for_display(input)
    return nil if input.nil?
    
    input = input.to_s.strip
    return '' if input.empty?
    
    # Remove all HTML/script content for safe display
    sanitized = input.gsub(/<[^>]*>/, '')
    sanitized = sanitized.gsub(/javascript:/i, '')
    sanitized = sanitized.gsub(/on\w+\s*=/i, '')
    
    sanitized
  end

  # Sanitizes version number strings for RecordVersion tracking
  # Accepts semantic versioning formats: v1.0, 1.2.3, v2.0.1
  # Returns nil if the input does not conform to a valid version format
  def self.sanitize_version_number(input)
    return nil if input.nil?

    input = input.to_s.strip.downcase
    return nil if input.empty?

    # Strip everything except version-safe characters (digits, dots, leading 'v')
    sanitized = input.gsub(/[^v0-9.]/, '')

    # Validate: optional 'v' followed by one to three dot-separated numeric segments
    sanitized =~ /\Av?\d+(\.\d+){0,2}\z/ ? sanitized : nil
  end

  # Batch sanitizes a hash of parameters
  # Useful for processing entire request parameter sets
  def self.sanitize_params(params_hash, sanitization_rules = {})
    return {} if params_hash.nil?
    
    sanitized = {}
    
    params_hash.each do |key, value|
      if sanitization_rules[key.to_sym]
        rule = sanitization_rules[key.to_sym]
        sanitized[key] = send("sanitize_#{rule}", value)
      else
        # Default: sanitize as text
        sanitized[key] = sanitize_text(value) if value.is_a?(String)
      end
    end
    
    sanitized
  end
end
