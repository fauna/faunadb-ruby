require 'simplecov'
require 'fauna'
require 'fauna_helper'

# Reference http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Disable monkey patching
  config.disable_monkey_patching!

  # Enable warnings
  config.warnings = true

  # Setup test order
  config.order = :random
  Kernel.srand config.seed

  # Include test helpers
  config.include FaunaTestHelpers
end
