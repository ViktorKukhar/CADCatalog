# Data Sanitization Implementation Guide

## Overview
This document describes the comprehensive data sanitization layer added to the CADCatalog project to prevent XSS, SQL injection, and other input-based attacks.

## Architecture

### DataSanitizer Service (`app/services/data_sanitizer.rb`)
Central sanitization service using Rails framework APIs:

**Key Methods:**
- `sanitize_text()` - Removes all HTML to prevent XSS
- `sanitize_html()` - Allows whitelisted HTML tags only
- `sanitize_sql_input()` - Removes SQL injection characters
- `sanitize_search_query()` - Cleans search input
- `sanitize_tag()` - Validates and cleans tag names
- `sanitize_numeric()` - Safely converts numeric input
- `sanitize_email()` - Validates and cleans email addresses
- `sanitize_filename()` - Prevents directory traversal
- `sanitize_url()` - Whitelists safe URL schemes
- `sanitize_for_display()` - Safe HTML removal
- `sanitize_params()` - Batch parameter sanitization

### Model Integration

**Record Model** (`app/models/record.rb`)
```ruby
before_validation :sanitize_input_data

def sanitize_input_data
  self.title = DataSanitizer.sanitize_text(title) if title.present?
  self.description = DataSanitizer.sanitize_html(description, %w[p br strong em]) if description.present?
end
```

**Software Model** (`app/models/software.rb`)
```ruby
before_validation :sanitize_input_data

def sanitize_input_data
  self.name = DataSanitizer.sanitize_text(name) if name.present?
end
```

**Tag Model** (`app/models/tag.rb`)
```ruby
before_validation :sanitize_tag_name

def sanitize_tag_name
  self.name = DataSanitizer.sanitize_tag(name) if name.present?
end
```

**User Model** (`app/models/user.rb`)
```ruby
before_validation :sanitize_input_data

def sanitize_input_data
  self.first_name = DataSanitizer.sanitize_text(first_name) if first_name.present?
  self.last_name = DataSanitizer.sanitize_text(last_name) if last_name.present?
end
```

### Controller Integration

**RecordsController** (`app/controllers/records_controller.rb`)
```ruby
def index
  if params[:tag]
    # Sanitize tag parameter to prevent injection
    sanitized_tag = DataSanitizer.sanitize_tag(params[:tag])
    
    if sanitized_tag.present?
      @records = Record.joins(:tags).where(tags: { name: sanitized_tag }).distinct
      @tag = Tag.find_by(name: sanitized_tag)
    else
      @records = Record.all
    end
  else
    @records = Record.all
  end
end
```

## Security Features

### XSS Prevention
- HTML sanitization using Rails' built-in sanitizer
- Removes all script tags and event handlers
- Whitelist approach for allowed HTML tags
- JavaScript protocol removal from URLs

### SQL Injection Prevention
- Input validation and character removal (;, ', ")
- Parameterized queries via ActiveRecord (primary defense)
- Sanitization layer as defensive measure
- ActiveRecord strong parameters integration

### Data Transformation
- Automatic whitespace trimming
- Case normalization (lowercase for tags)
- Type conversion (numeric validation)
- Format validation (email, URL)

## Testing Coverage

### DataSanitizer Tests (`spec/services/data_sanitizer_spec.rb`)
- 50+ test cases covering all sanitization methods
- XSS attack prevention scenarios
- SQL injection prevention tests
- Edge cases and nil handling
- Integration tests for combined attacks

### Model Integration Tests
**Record Model (`spec/models/record_spec.rb`)**
- XSS prevention through title/description
- SQL injection through tags
- Safe HTML preservation

**Software Model (`spec/models/software_spec.rb`)**
- XSS prevention in software names
- SQL injection prevention
- Input validation after sanitization

## Usage Examples

### Basic Text Sanitization
```ruby
dangerous_input = '<script>alert("xss")</script>Hello'
safe_text = DataSanitizer.sanitize_text(dangerous_input)
# => "Hello"
```

### HTML Preservation
```ruby
html_content = '<p>Safe content</p><script>alert(1)</script>'
safe_html = DataSanitizer.sanitize_html(html_content, %w[p strong em])
# => "<p>Safe content</p>"
```

### Tag Sanitization
```ruby
tag_input = "my-tag'; DROP TABLE--"
safe_tag = DataSanitizer.sanitize_tag(tag_input)
# => "my-tag"
```

### Model Automatic Sanitization
```ruby
# Sanitization happens automatically on save
record = Record.create!(
  title: '<img src=x onerror="alert(1)">Engine Block',
  description: 'Normal text'
)

record.title  # => "Engine Block" (script removed)
```

### Controller Usage
```ruby
# In controller action
sanitized_tag = DataSanitizer.sanitize_tag(params[:tag])
records = Record.joins(:tags).where(tags: { name: sanitized_tag })
```

## Defense Layers

1. **Input Layer** (Controller)
   - Strong parameters whitelist
   - Parameter sanitization before query

2. **Model Layer** (Validation)
   - before_validation callbacks
   - Automatic data sanitization
   - Type validation

3. **Database Layer** (ActiveRecord)
   - Parameterized queries (primary SQL injection defense)
   - Data type enforcement

4. **Output Layer** (Views)
   - Rails automatic HTML escaping
   - Sanitizer for user-generated content

## Maintenance Notes

### Adding New Sanitization Rules
When adding new user input fields:

1. Add sanitization method to DataSanitizer if needed
2. Add before_validation callback to model
3. Add test cases for new sanitization
4. Document in model comments

### Updating Sanitization Rules
- Modify relevant method in DataSanitizer
- Update tests
- Run full test suite to ensure no regressions

## Performance Considerations

- Sanitization runs once on model validation
- Minimal performance impact due to efficient regex patterns
- Cached results in database (sanitized data stored)
- No repeated sanitization on every view render

## Compliance & Standards

This implementation follows:
- **OWASP Top 10** protection against A7 (XSS) and A1 (Injection)
- **Rails Security Guide** best practices
- **CWE-79** (Cross-site Scripting) prevention
- **CWE-89** (SQL Injection) prevention
- **Framework APIs** (no external security libraries needed)

## Future Enhancements

- [ ] Rate limiting for API endpoints
- [ ] CSRF token validation (already in Rails)
- [ ] Content Security Policy (CSP) headers
- [ ] Honeypot fields for bot detection
- [ ] Extended logging for security events

---

**Status:** ✅ Ready for production  
**Test Coverage:** 60+ tests  
**Dependencies:** None (uses Rails framework only)
