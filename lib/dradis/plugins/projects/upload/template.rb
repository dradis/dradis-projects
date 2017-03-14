module Dradis::Plugins::Projects::Upload
  module Template
    def self.meta
      package = Dradis::Plugins::Projects
      {
        name:        package::Engine::plugin_name,
        description: 'Upload Project template file (.xml)',
        version:     package.version
      }
    end

    class Importer < Dradis::Plugins::Upload::Importer

      # The import method is invoked by the framework to process a template file
      # that has just been uploaded using the 'Import from file...' dialog.
      #
      # This module will take the XMl export file created with the ProjectExport
      # module and dump the contents into the current database.
      #
      # Since we cannot ensure that the original node and category IDs as specified
      # in the XML are free in this database, we need to keep a few lookup tables
      # to maintain the original structure of Nodes and the Notes pointing to the
      # right nodes and categories.
      #
      # This method also returns the Node lookup table so callers can understand
      # what changes to the original IDs have been applied. This is mainly for the
      # benefit of the ProjectPackageUpload module that would use the translation
      # table to re-associate the attachments in the project archive with the new
      # node IDs in the current project.
      def import(params={})

        # load the template
        logger.info { "Loading template file from: #{params[:file]}" }
        template = Nokogiri::XML(File.read(params[:file]))
        logger.info { "Done." }

        unless template.errors.empty?
          logger.error { "Invalid project template format." }
          return false
        end

        parser = Rails.application.config.dradis.projects.template_uploader.new(
          logger: logger
        ).parse(template)
      end

      def parse(template)
        parse_categories(template)
        parse_nodes(template)
        parse_issues(template)
        parse_methodologies(template)
        parse_tags(template)
        finalize(template)
      rescue Exception => e
        logger.fatal { e.message }
        logger.fatal { e.backtrace } if Rails.env.development?
        return false
      end

      private

      def finalize(template);            raise NotImplementedError; end
      def parse_categories(template);    raise NotImplementedError; end
      def parse_issues(template);        raise NotImplementedError; end
      def parse_methodologies(template); raise NotImplementedError; end
      def parse_nodes(template);         raise NotImplementedError; end
      def parse_tags(template);          raise NotImplementedError; end
    end
  end
end

require_relative 'v1/template'
