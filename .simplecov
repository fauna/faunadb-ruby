# Bring in json formatter
require 'simplecov-json'

# Configure formatters
SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter,
]

SimpleCov.start do
  # Filter out test directories
  add_filter 'spec/'
end
