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
      attr_accessor :lookup_table, :template_version

      # libxml2 error codes for isolated, single-character fixups that don't
      # affect document structure (e.g. an invalid byte gets swapped for the
      # unicode replacement character). Safe to recover from and continue.
      #
      # Any other error code (tag mismatches, premature end of data, undefined
      # entities, etc.) indicates the document was actually truncated or
      # corrupted, so those must still cause a hard failure.
      RECOVERABLE_ERROR_CODES = [
        9,  # XML_ERR_INVALID_CHAR
        81  # XML_ERR_INVALID_ENCODING
      ].freeze

      def self.templates
        { }
      end

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

        unrecoverable_errors = template.errors.reject { |e| RECOVERABLE_ERROR_CODES.include?(e.code) }

        unless unrecoverable_errors.empty?
          logger.error { "Invalid project template format: #{unrecoverable_errors.map(&:message).join('; ')}" }
          return false
        end

        if template.errors.any?
          logger.warn { "Nokogiri reported recoverable parse warnings: #{template.errors.map(&:message).join('; ')}" }
        end

        if template.xpath('/dradis-template').empty?
          error = "The uploaded file doesn't look like a Dradis project template (/dradis-template)."
          logger.fatal{ error }
          content_service.create_note text: error
          return false
        end

        # :options contains all the options we've received from the framework.
        #
        # See:
        #   Dradis::Plugins::Upload::Importer#initialize
        Rails.application.config.dradis.projects.template_uploader.new(options)
          .parse(template)
      end

      def parse(template)
        @template_version = template.root[:version].try(:to_i) || 1
        logger.info { "Parsing Dradis template version #{template_version.inspect}" }

        parse_categories(template)
        parse_nodes(template)
        parse_issues(template)
        parse_methodologies(template)
        parse_report_content(template)
        parse_tags(template)
        finalize(template)
        # FIXME: returning this is gross
        lookup_table
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
      def parse_report_content(template) raise NotImplementedError; end
      def parse_tags(template);          raise NotImplementedError; end
    end
  end
end

require_relative 'v4/template'
