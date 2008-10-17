module WarningShot
  module Utilities
    class << self
      def hostname
        `hostname`.strip
      end
    end
  end
end