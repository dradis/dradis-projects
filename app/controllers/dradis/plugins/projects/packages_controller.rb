module Dradis::Plugins::Projects
  class PackagesController < Dradis::Plugins::Export::BaseController
    skip_before_action :validate_scope
    skip_before_action :validate_template

    def create
      filename = Rails.root.join('tmp', 'dradis-export.zip')

      options = export_params.merge({
        plugin: Dradis::Plugins::Projects,
        scope: :all
      })
      exporter = Dradis::Plugins::Projects::Export::Package.new(options)
      template = exporter.export(filename: filename)

      track_download(filename: File.basename(filename), size: File.size(filename))

      send_file(filename)
    end

    private

    def track_download(filename:, size:)
      return unless defined?(Dradis::Pro)

      track_usage('report.downloaded', {
        filename: filename,
        size: '%.2f MB' % (size.to_f / 2**20),
      })
    end
  end
end
