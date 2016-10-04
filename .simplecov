# Bring in codecov
require 'codecov'

# Configure formatters
SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Codecov
]

SimpleCov.start do
  # Filter out test directories
  add_filter 'spec/'
end
