require 'warningshot'

# Loads all resolvers
Dir.glob(File.dirname(__FILE__) / ".." / "resolvers" / "**" / "*.rb").each {|f| require f}