module Dradis::Plugins::Projects
  class PackagesController < Dradis::Plugins::Export::BaseController
    skip_before_action :validate_scope

    def create
      filename = Rails.root.join('tmp', 'dradis-export.zip')

      exporter = Dradis::Plugins::Projects::Export::Package.new({
        project_id: params[:project_id],
        plugin: Dradis::Plugins::Projects,
        scope: :all
      })
      template = exporter.export(filename: filename)

      send_file(filename)
    end
  end
end
