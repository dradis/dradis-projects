module Dradis::Plugins::Projects
  class TemplatesController < Dradis::Plugins::Export::BaseController
    def show
      # this allows us to have different exporters in different editions
      exporter_class = Rails.application.config.dradis.projects.template_exporter

      options  = export_options.merge(plugin: Dradis::Plugins::Projects)
      exporter = exporter_class.new(options)
      template = exporter.export

      send_data(template, filename: 'dradis-template.xml', type: :xml)
    end
  end
end
