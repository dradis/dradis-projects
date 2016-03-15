module Dradis::Plugins::Projects::Export
  class Package < Dradis::Plugins::Export::Base

    # Create a new project export bundle. It will include an XML file with the
    # contents of the repository (see db_only) and all the attachments that
    # have been uploaded into the system.
    def export(params={})
      raise ":filename not provided" unless params.key?(:filename)

      filename = params[:filename]
      logger   = params.fetch(:logger, Rails.logger)

      File.delete(filename) if File.exists?(filename)

      logger.debug{ "Creating a new Zip file in #{filename}..." }
      Zip::File.open(filename, Zip::File::CREATE) do |zipfile|
        Node.all.each do |node|
          node_path = Attachment.pwd.join(node.id.to_s)

          Dir["#{node_path}/**/**"].each do |file|
            logger.debug{ "\tAdding attachment for '#{node.label}': #{file}" }
            zipfile.add(file.sub("#{Attachment.pwd.to_s}/", ''), file)
          end
        end

        logger.debug{ "\tAdding XML repository dump" }
        template_exporter = Template.new(content_service: content_service)
        template = template_exporter.export(params)
        zipfile.get_output_stream('dradis-repository.xml') { |out|
          out << template
        }
      end
      logger.debug{ 'Done.' }
    end

  end
end
