require 'fauna'

# Various and sundry rails integration points

# ActionDispatch's Auto reloader blows away some of Fauna's schema
# configuration that does not live within the Model classes
# themselves. Add a callback to Reloader to reload the schema config
# before each request.

loader = ActionDispatch::Reloader rescue nil
loader.to_prepare { Fauna.configure_schema! } if loader
