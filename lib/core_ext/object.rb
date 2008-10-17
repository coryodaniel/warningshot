class Object
  class << self
    def is_const_defined?(const)
      Object.const_get const rescue false
    end
  end
end