# frozen_string_literal: true

require 'json'

# Sanitizes the value of a key that is sensitive field
def sanitize(data)
  if data.instance_of?(Array)
    data.map { |el| sanitize_element(el) }
  elsif data.instance_of?(Hash)
    data.each do |k, v|
      data[k] = sanitize_element(v)
    end
  else
    sanitize_element(data)
  end
end

# Sanitizes a single value based on its type
def sanitize_element(data)
  if data.instance_of?(String)
    data.gsub(/([A-Za-z0-9])/, '*')
  elsif [Integer, Float].include?(data.class)
    data.to_s.gsub(/([A-Za-z0-9])/, '*')
  elsif [TrueClass, FalseClass].include?(data.class)
    '-'
  end
end

# Sanitizes array of objects that may have sensitive data
def sanitize_array(sensitive_fields, data)
  data.each do |el|
    next unless el.instance_of?(Hash)

    el.each do |key, value|
      el[key] = sanitize(value) if sensitive_fields.include?(key)
    end
  end
end

# Sanitizes the user info hash
def scrub(user_info, sensitive_fields)
  user_info.each do |key, value|
    if sensitive_fields.include?(key)
      user_info[key] = sanitize(value)

    elsif value.instance_of?(Hash)
      value.each do |k, v|
        value[k] = sanitize(v) if sensitive_fields.include?(k)
      end

    elsif value.instance_of?(Array)
      sanitize_array(sensitive_fields, value)
    end
  end
end

# Read from command line arguments
sensitive_fields_file_name = ARGV[0]
input_file_name = ARGV[1]

# Load from files
file = File.open(sensitive_fields_file_name)
sensitive_fields = file.readlines.map(&:chomp)
file.close
file = File.read(input_file_name)
user_info = JSON.parse(file)

# Sanitize user information
user_info = scrub(user_info, sensitive_fields)

# Test program output matches expected
file = File.read(input_file_name.gsub('input', 'output'))
output = JSON.parse(file)
p "Tests passed: #{output == user_info}"
p user_info
