module Dradis::Plugins::Projects
  class PackagesController < Dradis::Plugins::Export::BaseController
    def show
      filename = Rails.root.join('tmp', 'dradis-export.zip')

      options  = export_options.merge(plugin: Dradis::Plugins::Projects)
      exporter = Dradis::Plugins::Projects::Export::Package.new(options)
      template = exporter.export(filename: filename)

      send_file(filename)
    end
  end
end
