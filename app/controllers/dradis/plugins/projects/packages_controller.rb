module Dradis::Plugins::Projects
  class PackagesController < Dradis::Plugins::Export::BaseController
    def show
      # these come from Export#create
      export_manager_hash   = session[:export_manager].with_indifferent_access
      content_service_class = export_manager_hash[:content_service].constantize

      exporter = Dradis::Plugins::Projects::Export::Package.new(
        content_service: content_service_class.new(plugin: Dradis::Plugins::Projects)
      )

      package_file = Rails.root.join('tmp', 'dradis-export.zip')
      template     = exporter.export(export_manager_hash.merge(filename: package_file))
      send_file(package_file)
    end
  end
end
