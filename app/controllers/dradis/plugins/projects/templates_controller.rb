module Dradis::Plugins::Projects
  class TemplatesController < Dradis::Plugins::Export::BaseController
    skip_before_action :validate_scope

    def show
      # this allows us to have different exporters in different editions
      exporter_class = Rails.application.config.dradis.projects.template_exporter

      options  = export_params.merge(
        plugin: Dradis::Plugins::Projects,
        scope: :all
      )
      exporter = exporter_class.new(options)
      template = exporter.export

      send_data(template, filename: 'dradis-template.xml', type: :xml)
    end
  end
end
