# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  # PII fields encrypted at rest — must not appear in Rails log files
  :first_name, :last_name, :position,
  # Sensitive content fields encrypted at rest
  :comment, :change_log,
  # Network identifiers
  :ip_address
]
