module Dradis
  module Plugins
    module Projects
      class Engine < ::Rails::Engine
        isolate_namespace Dradis::Plugins::Projects

        include ::Dradis::Plugins::Base
        description 'Save and restore project information'
        provides :export, :upload

        initializer 'dradis-projects.mount_engine' do
          Rails.application.routes.append do
            mount Dradis::Plugins::Projects::Engine => '/export/projects'
          end
        end

        # Because this plugin provides two export modules, we have to overwrite
        # the default .uploaders() method.
        #
        # See:
        #  Dradis::Plugins::Upload::Base in dradis-plugins
        def self.uploaders
          [
            Dradis::Plugins::Projects::Upload::Package,
            Dradis::Plugins::Projects::Upload::Template
          ]
        end
      end
    end
  end
end