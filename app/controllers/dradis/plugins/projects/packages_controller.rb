module Dradis::Plugins::Projects
  class PackagesController < Dradis::Plugins::Export::BaseController
    skip_before_action :validate_scope

    def create
      filename = Rails.root.join('tmp', 'dradis-export.zip')

      options = export_params.merge({
        plugin: Dradis::Plugins::Projects,
        scope: :all
      })
      exporter = Dradis::Plugins::Projects::Export::Package.new(options)
      template = exporter.export(filename: filename)

      send_file(filename)
    end
  end
end
