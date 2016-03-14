require_relative 'gem_version'

module Dradis
  module Plugins
    module Projects
      # Returns the version of the currently loaded Projects as a
      # <tt>Gem::Version</tt>.
      def self.version
        gem_version
      end
    end
  end
end
