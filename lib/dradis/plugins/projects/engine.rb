module Dradis
  module Plugins
    module Projects
      class Engine < ::Rails::Engine
        isolate_namespace Dradis::Plugins::Projects

        config.dradis.projects = ActiveSupport::OrderedOptions.new

        include ::Dradis::Plugins::Base
        description 'Save and restore project information'
        provides :export, :upload

        initializer 'dradis-projects.mount_engine' do
          Rails.application.routes.append do
            mount Dradis::Plugins::Projects::Engine => '/export/projects'
          end
        end

        initializer "dradis-projects.set_configs" do |app|
          options = app.config.dradis.projects
          options.template_exporter ||= Dradis::Plugins::Projects::Export::V2::Template
          options.template_uploader ||= Dradis::Plugins::Projects::Upload::V2::Template::Importer
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
