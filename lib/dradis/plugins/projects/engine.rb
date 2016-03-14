module Dradis
  module Plugins
    module Projects
      class Engine < ::Rails::Engine
        isolate_namespace Dradis::Plugins::Projects

        include ::Dradis::Plugins::Base
        description 'Save and restore project information'
        provides :export, :upload

        # Because this plugin provides two export modules, we have to overwrite
        # the default .uploaders() method.
        # def self.uploaders
        #   [
        #     Dradis::Plugins::Projects::Upload::Package,
        #     Dradis::Plugins::Projects::Upload::Template
        #   ]
        # end
      end
    end
  end
end