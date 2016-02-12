# Bring in coveralls
require 'coveralls'

# Configure formatters
SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  # Filter out test directories
  add_filter 'spec/'
end
