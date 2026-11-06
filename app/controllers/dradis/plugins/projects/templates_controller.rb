module Dradis::Plugins::Projects
  class TemplatesController < Dradis::Plugins::Export::BaseController
    skip_before_action :validate_scope
    skip_before_action :validate_template

    def create
      # this allows us to have different exporters in different editions
      exporter_class = Rails.application.config.dradis.projects.template_exporter

      options  = export_params.merge(
        plugin: Dradis::Plugins::Projects,
        scope: :all
      )
      exporter = exporter_class.new(options)
      template = exporter.export
      filename = 'dradis-template.xml'

      track_download(filename: filename, size: template.bytesize) if defined?(Dradis::Pro)

      send_data(template, filename: filename, type: :xml)
    end
  end
end
