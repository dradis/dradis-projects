module Dradis::Plugins::Projects
  class TemplatesController < Dradis::Plugins::Export::BaseController
    def show
      # these come from Export#create
      export_manager_hash   = session[:export_manager].with_indifferent_access
      content_service_class = export_manager_hash[:content_service].constantize

      exporter = Rails.application.config.dradis.projects.template_exporter.new(
        content_service: content_service_class.new(plugin: Dradis::Plugins::Projects)
      )

      template = exporter.export(export_manager_hash)
      send_data(template, filename: 'dradis-template.xml', type: :xml)
    end
  end
end
