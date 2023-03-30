# frozen_string_literal: true

require 'json'

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

def sanitize_element(data)
  if data.instance_of?(String)
    data.gsub(/([A-Za-z0-9])/, '*')
  elsif [Integer, Float].include?(data.class)
    data.to_s.gsub(/([A-Za-z0-9])/, '*')
  elsif [TrueClass, FalseClass].include?(data.class)
    '-'
  end
end

# Read from command line arguments
sensitive_fields_file = ARGV[0]
input_file = ARGV[1]

# Load from files
file = File.open(sensitive_fields_file)
sensitive_fields = file.readlines.map(&:chomp)
file.close
file = File.read(input_file)
user_info = JSON.parse(file)

# Sanitize user information
sensitive_fields.each do |field|
  user_info[field] = sanitize(user_info[field]) if user_info.has_key?(field)
end

# Test program output matches expected
file = File.read(input_file.gsub('input', 'output'))
output = JSON.parse(file)
p "Tests passed: #{output == user_info}"
