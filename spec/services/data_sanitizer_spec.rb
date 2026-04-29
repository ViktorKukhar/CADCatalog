# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/services/data_sanitizer'

describe DataSanitizer do
  describe '.sanitize_text' do
    it 'removes HTML tags to prevent XSS attacks' do
      input = '<script>alert("XSS")</script>Hello'
      result = DataSanitizer.sanitize_text(input)
      
      expect(result).not_to include('<script>')
      expect(result).not_to include('alert')
    end

    it 'removes dangerous attributes' do
      input = '<img src=x onerror="alert(1)">'
      result = DataSanitizer.sanitize_text(input)
      
      expect(result).not_to include('onerror')
      expect(result).not_to include('<img')
    end

    it 'handles nil input gracefully' do
      expect(DataSanitizer.sanitize_text(nil)).to be_nil
    end

    it 'strips whitespace' do
      input = '  Hello World  '
      result = DataSanitizer.sanitize_text(input)
      
      expect(result).to eq('Hello World')
    end

    it 'returns empty string for empty input' do
      expect(DataSanitizer.sanitize_text('')).to eq('')
      expect(DataSanitizer.sanitize_text('   ')).to eq('')
    end

    it 'converts non-string input to string' do
      result = DataSanitizer.sanitize_text(12345)
      
      expect(result).to eq('12345')
    end
  end

  describe '.sanitize_html' do
    it 'allows whitelisted HTML tags' do
      input = '<p>Hello <strong>World</strong></p>'
      result = DataSanitizer.sanitize_html(input)
      
      expect(result).to include('<p>')
      expect(result).to include('<strong>')
    end

    it 'removes non-whitelisted tags' do
      input = '<p>Hello</p><script>alert("XSS")</script>'
      result = DataSanitizer.sanitize_html(input)
      
      expect(result).not_to include('<script>')
    end

    it 'removes dangerous event handlers' do
      input = '<p onclick="alert(1)">Click me</p>'
      result = DataSanitizer.sanitize_html(input)
      
      expect(result).not_to include('onclick')
    end

    it 'prevents XSS through event handlers' do
      input = '<strong onmouseover="alert(1)">Test</strong>'
      result = DataSanitizer.sanitize_html(input)
      
      expect(result).not_to include('onmouseover')
    end

    it 'allows safe attributes in whitelist' do
      input = '<p class="highlight">Content</p>'
      result = DataSanitizer.sanitize_html(input, %w[p], %w[class])
      
      expect(result).to include('class')
    end
  end

  describe '.sanitize_sql_input' do
    it 'removes single quotes to prevent SQL injection' do
      input = "'; DROP TABLE users; --"
      result = DataSanitizer.sanitize_sql_input(input)
      
      expect(result).not_to include("'")
    end

    it 'removes semicolons used in SQL injection' do
      input = 'user; DELETE FROM records;'
      result = DataSanitizer.sanitize_sql_input(input)
      
      expect(result).not_to include(';')
    end

    it 'removes double quotes' do
      input = 'value" OR "1"="1'
      result = DataSanitizer.sanitize_sql_input(input)
      
      expect(result).not_to include('"')
    end

    it 'handles nil input' do
      expect(DataSanitizer.sanitize_sql_input(nil)).to be_nil
    end
  end

  describe '.sanitize_search_query' do
    it 'removes dangerous special characters' do
      input = 'search<script>alert(1)</script>'
      result = DataSanitizer.sanitize_search_query(input)
      
      expect(result).not_to include('<')
      expect(result).not_to include('>')
    end

    it 'allows safe search characters' do
      input = 'CAD model-design_v2'
      result = DataSanitizer.sanitize_search_query(input)
      
      expect(result).to include('CAD')
      expect(result).to include('-')
      expect(result).to include('_')
    end

    it 'prevents SQL injection in search' do
      input = "search'; DROP TABLE--"
      result = DataSanitizer.sanitize_search_query(input)
      
      expect(result).not_to include("'")
      expect(result).not_to include(';')
    end
  end

  describe '.sanitize_tag' do
    it 'converts to lowercase' do
      input = 'MyTag'
      result = DataSanitizer.sanitize_tag(input)
      
      expect(result).to eq('mytag')
    end

    it 'removes special characters' do
      input = 'tag!@#$%^'
      result = DataSanitizer.sanitize_tag(input)
      
      expect(result).to eq('tag')
    end

    it 'allows alphanumeric, hyphens, and underscores' do
      input = 'my-tag_123'
      result = DataSanitizer.sanitize_tag(input)
      
      expect(result).to eq('my-tag_123')
    end

    it 'enforces maximum length of 50 characters' do
      input = 'a' * 100
      result = DataSanitizer.sanitize_tag(input)
      
      expect(result.length).to eq(50)
    end

    it 'prevents injection through tag names' do
      input = "tag'; DROP TABLE tags;--"
      result = DataSanitizer.sanitize_tag(input)
      
      expect(result).not_to include("'")
      expect(result).not_to include(';')
    end
  end

  describe '.sanitize_numeric' do
    it 'extracts numeric values from string' do
      input = 'value: 123.45'
      result = DataSanitizer.sanitize_numeric(input)
      
      expect(result).to eq(123.45)
    end

    it 'handles negative numbers when allowed' do
      input = '-42.5'
      result = DataSanitizer.sanitize_numeric(input, allow_negative: true)
      
      expect(result).to eq(-42.5)
    end

    it 'prevents negative when not allowed' do
      input = '-100'
      result = DataSanitizer.sanitize_numeric(input, allow_negative: false)
      
      expect(result).to eq(100.0)
    end

    it 'removes injection attempts in numeric input' do
      input = '100; DROP TABLE;'
      result = DataSanitizer.sanitize_numeric(input)
      
      expect(result).to eq(100.0)
    end

    it 'returns nil for non-numeric input' do
      expect(DataSanitizer.sanitize_numeric('abc')).to be_nil
    end

    it 'handles nil input' do
      expect(DataSanitizer.sanitize_numeric(nil)).to be_nil
    end
  end

  describe '.sanitize_email' do
    it 'accepts valid email format' do
      input = 'user@example.com'
      result = DataSanitizer.sanitize_email(input)
      
      expect(result).to eq('user@example.com')
    end

    it 'converts to lowercase' do
      input = 'User@Example.COM'
      result = DataSanitizer.sanitize_email(input)
      
      expect(result).to eq('user@example.com')
    end

    it 'removes dangerous characters' do
      input = 'user<script>@example.com'
      result = DataSanitizer.sanitize_email(input)
      
      expect(result).not_to include('<script>')
    end

    it 'rejects invalid email format' do
      result = DataSanitizer.sanitize_email('not-an-email')
      
      expect(result).to be_nil
    end

    it 'prevents injection in email field' do
      input = "user@example.com'; DROP TABLE--"
      result = DataSanitizer.sanitize_email(input)
      
      expect(result).to be_nil  # Invalid format
    end
  end

  describe '.sanitize_filename' do
    it 'removes directory traversal attempts' do
      input = '../../../etc/passwd'
      result = DataSanitizer.sanitize_filename(input)
      
      expect(result).not_to include('..')
      expect(result).not_to include('/')
    end

    it 'removes dangerous characters' do
      input = 'file<script>.txt'
      result = DataSanitizer.sanitize_filename(input)
      
      expect(result).not_to include('<')
      expect(result).not_to include('>')
    end

    it 'allows alphanumeric and common filename characters' do
      input = 'my-model_v2.dxf'
      result = DataSanitizer.sanitize_filename(input)
      
      expect(result).to eq('my-model_v2.dxf')
    end

    it 'enforces maximum length of 255 characters' do
      input = 'a' * 500 + '.txt'
      result = DataSanitizer.sanitize_filename(input)
      
      expect(result.length).to eq(255)
    end

    it 'returns "file" for completely invalid input' do
      result = DataSanitizer.sanitize_filename('!!!<>')
      
      expect(result).to eq('file')
    end
  end

  describe '.sanitize_url' do
    it 'allows http URLs' do
      input = 'http://example.com'
      result = DataSanitizer.sanitize_url(input)
      
      expect(result).to eq('http://example.com')
    end

    it 'allows https URLs' do
      input = 'https://example.com/path?param=value'
      result = DataSanitizer.sanitize_url(input)
      
      expect(result).to eq('https://example.com/path?param=value')
    end

    it 'rejects javascript: URLs to prevent XSS' do
      input = 'javascript:alert(1)'
      result = DataSanitizer.sanitize_url(input)
      
      expect(result).to be_nil
    end

    it 'rejects data: URLs' do
      input = 'data:text/html,<script>alert(1)</script>'
      result = DataSanitizer.sanitize_url(input)
      
      expect(result).to be_nil
    end

    it 'handles invalid URI format' do
      result = DataSanitizer.sanitize_url('not a valid url at all')
      
      expect(result).to be_nil
    end
  end

  describe '.sanitize_for_display' do
    it 'removes all HTML tags for safe display' do
      input = '<p>Hello <strong>World</strong></p>'
      result = DataSanitizer.sanitize_for_display(input)
      
      expect(result).not_to include('<p>')
      expect(result).not_to include('<strong>')
      expect(result).to include('Hello')
    end

    it 'removes javascript: protocol' do
      input = 'Click here javascript:alert(1)'
      result = DataSanitizer.sanitize_for_display(input)
      
      expect(result).not_to include('javascript:')
    end

    it 'removes event handlers' do
      input = 'onload="alert(1)" text'
      result = DataSanitizer.sanitize_for_display(input)
      
      expect(result).not_to include('onload')
    end
  end

  describe '.sanitize_params' do
    it 'sanitizes multiple parameters at once' do
      params = {
        title: '<script>alert(1)</script>Hello',
        email: 'User@Example.com',
        age: '25'
      }
      
      result = DataSanitizer.sanitize_params(params, { title: :text, email: :email })
      
      expect(result[:title]).not_to include('<script>')
      expect(result[:email]).to eq('user@example.com')
    end

    it 'handles nil parameters hash' do
      result = DataSanitizer.sanitize_params(nil)
      
      expect(result).to eq({})
    end

    it 'defaults to text sanitization for unlisted fields' do
      params = { description: '<p>Test</p>' }
      result = DataSanitizer.sanitize_params(params)
      
      expect(result[:description]).not_to include('<p>')
    end
  end

  describe 'Integration: XSS Prevention' do
    it 'prevents stored XSS through title field' do
      malicious_title = '"><script>alert("xss")</script>'
      sanitized = DataSanitizer.sanitize_text(malicious_title)
      
      expect(sanitized).not_to include('script')
      expect(sanitized).not_to include('alert')
    end

    it 'prevents reflected XSS through search' do
      user_search = '" onload="alert(1)" "'
      sanitized = DataSanitizer.sanitize_search_query(user_search)
      
      expect(sanitized).not_to include('onload')
      expect(sanitized).not_to include('"')
    end

    it 'prevents SQL injection through tags' do
      injection_attempt = "admin'; DELETE FROM users; --"
      sanitized = DataSanitizer.sanitize_tag(injection_attempt)
      
      expect(sanitized).not_to include("'")
      expect(sanitized).not_to include(';')
      expect(sanitized).not_to include('--')
    end
  end
end
