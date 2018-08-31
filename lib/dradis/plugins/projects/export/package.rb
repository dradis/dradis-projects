module Dradis::Plugins::Projects::Export
  class Package < Dradis::Plugins::Export::Base

    # Create a new project export bundle. It will include an XML file with the
    # contents of the repository (see db_only) and all the attachments that
    # have been uploaded into the system.
    def export(args={})
      raise ":filename not provided" unless args.key?(:filename)

      filename = args[:filename]
      logger   = options.fetch(:logger, Rails.logger)

      File.delete(filename) if File.exists?(filename)

      logger.debug{ "Creating a new Zip file in #{filename}..." }

      Zip::File.open(filename, Zip::File::CREATE) do |zipfile|
        @project.nodes.each do |node|
          node_path = Attachment.pwd.join(node.id.to_s)

          Dir["#{node_path}/**/**"].each do |file|
            logger.debug{ "\tAdding attachment for '#{node.label}': #{file}" }
            zipfile.add(file.sub("#{Attachment.pwd.to_s}/", ''), file)
          end
        end

        logger.debug{ "\tAdding XML repository dump" }

        exporter_class    = Rails.application.config.dradis.projects.template_exporter
        template_exporter = exporter_class.new(options)
        template          = template_exporter.export

        zipfile.get_output_stream('dradis-repository.xml') { |out|
          out << template
        }
      end

      logger.debug{ 'Done.' }
    end

  end
end
