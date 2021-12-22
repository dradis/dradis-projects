module Dradis
  module Plugins
    module Projects
      # Returns the version of the currently loaded Projects as a <tt>Gem::Version</tt>
      def self.gem_version
        Gem::Version.new VERSION::STRING
      end

      module VERSION
        MAJOR = 4
        MINOR = 1
        TINY = 2
        PRE = 1

        STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".")
      end
    end
  end
end
