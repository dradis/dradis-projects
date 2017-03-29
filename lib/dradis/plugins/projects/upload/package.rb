module Dradis::Plugins::Projects::Upload
  module Package
    def self.meta
      package = Dradis::Plugins::Projects
      {
        name:        package::Engine::plugin_name,
        description: 'Upload Project package file (.zip)',
        version:     package.version
      }
    end

    # In this module you will find the implementation details that enable you to
    # upload a project archive (generated using ProjectExport::Processor::full_project)
    class Importer < Dradis::Plugins::Upload::Importer

      def import(params={})
        package = params[:file]
        success = false

        # Unpack the archive in a temporary location
        FileUtils.mkdir Rails.root.join('tmp', 'zip')

        begin
          logger.info { 'Uncompressing the file...' }
          #TODO: this could be improved by only uncompressing the XML, then parsing
          # it to get the node_lookup table and then uncompressing each entry to its
          # final destination
          Zip::File.foreach(package) do |entry|
            path = Rails.root.join('tmp', 'zip', entry.name)
            FileUtils.mkdir_p(File.dirname(path))
            entry.extract(path)
            logger.info { "\t#{entry.name}" }
          end
          logger.info { 'Done.' }


          logger.info { 'Loading XML template file...' }
          template_file = Rails.root.join('tmp', 'zip', 'dradis-repository.xml')
          importer    = Template::Importer.new(
                          options.merge plugin: Dradis::Plugins::Projects::Upload::Template
                        )
          lookup_table = importer.import(file: template_file)
          logger.info { 'Done.' }


          logger.info { 'Moving attachments to their final destinations...' }
          lookup_table[:nodes].each do |oldid,newid|
            if File.directory? Rails.root.join('tmp', 'zip', oldid)
              FileUtils.mkdir_p Attachment.pwd.join(newid.to_s)

              Dir.glob(Rails.root.join('tmp', 'zip', oldid, '*')).each do |attachment|
                FileUtils.mv(attachment, Attachment.pwd.join(newid.to_s))
              end
            end
          end
          logger.info { 'Done.' }

          success = true
        rescue Exception => e
          logger.error { e.message }
          success = false
        ensure
          # clean up the temporary files
          FileUtils.rm_rf(Rails.root.join('tmp', 'zip'))
        end

        return success
      end
    end
  end
end
