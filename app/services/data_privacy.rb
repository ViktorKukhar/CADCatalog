# DataPrivacy - Implements the data privacy strategy for CADCatalog.
# Handles two concerns:
#   1. Access control  — who may read or modify a given resource and under what conditions
#   2. Data masking    — returning safe, partially-obscured values for unauthorized viewers
#
# This service is the single authority for visibility rules; controllers and views
# delegate to it rather than reimplementing policy logic.

class DataPrivacy
  # Attributes considered personally identifiable or operationally sensitive.
  # High: must never be exposed in full to non-owners.
  # Medium: may be truncated or partially shown to non-owners.
  SENSITIVITY_LEVELS = {
    high:   %i[first_name last_name position comment change_log],
    medium: %i[description email],
    low:    %i[username title rating version_number complexity_score name]
  }.freeze

  # --- Access control ---

  # Returns true if requesting_user may view the resource in full.
  def self.can_read?(requesting_user, resource)
    return false if requesting_user.nil?

    case resource
    when Collection   then resource.accessible_by?(requesting_user)
    when RecordVersion then requesting_user.id == resource.record.user_id
    else true
    end
  end

  # Returns true if requesting_user may create, update, or destroy the resource.
  def self.can_modify?(requesting_user, resource)
    return false if requesting_user.nil?

    case resource
    when User          then requesting_user.id == resource.id
    when Record        then requesting_user.id == resource.user_id
    when Collection    then requesting_user.id == resource.user_id
    when RecordVersion then requesting_user.id == resource.user_id
    when UserReview    then requesting_user.id == resource.user_id
    else false
    end
  end

  # Returns the sensitivity classification for a given attribute name.
  def self.sensitivity_level(attribute_name)
    SENSITIVITY_LEVELS.each { |level, attrs| return level if attrs.include?(attribute_name.to_sym) }
    :low
  end

  # Returns which column names the requesting user may read without masking.
  def self.accessible_fields_for(requesting_user, resource)
    return [] unless resource && requesting_user

    all_fields = resource.class.column_names.map(&:to_sym)
    return all_fields if can_modify?(requesting_user, resource)

    all_fields - SENSITIVITY_LEVELS[:high]
  end

  # --- Data masking ---

  # Returns a hash of the resource's attributes with high-sensitivity values
  # masked for any user who is not the owner/modifier of that resource.
  def self.redact_for(requesting_user, resource)
    return {} unless resource

    attrs = resource.attributes.symbolize_keys
    return attrs if can_modify?(requesting_user, resource)

    attrs.each_with_object({}) do |(key, value), hash|
      hash[key] = case sensitivity_level(key)
                  when :high   then mask_by_type(key, value)
                  when :medium then mask_text(value, visible_chars: 30)
                  else value
                  end
    end
  end

  # Masks a name to its first character: "Viktor" → "V***"
  def self.mask_name(name)
    return nil if name.nil?
    return '' if name.strip.empty?
    "#{name[0]}#{'*' * [name.length - 1, 3].min}"
  end

  # Masks an email local part: "viktor@example.com" → "v****@example.com"
  def self.mask_email(email)
    return nil if email.nil?

    local, domain = email.split('@')
    return email unless domain

    masked_local = local.length > 1 ? "#{local[0]}#{'*' * [local.length - 1, 4].min}" : local
    "#{masked_local}@#{domain}"
  end

  # Truncates arbitrary text and appends ellipsis to signal redaction.
  def self.mask_text(text, visible_chars: 20)
    return nil if text.nil?
    return '' if text.strip.empty?
    text.length > visible_chars ? "#{text[0...visible_chars]}…" : text
  end

  private

  def self.mask_by_type(attribute_name, value)
    case attribute_name
    when :first_name, :last_name then mask_name(value)
    when :email                  then mask_email(value)
    else                              mask_text(value)
    end
  end
end
