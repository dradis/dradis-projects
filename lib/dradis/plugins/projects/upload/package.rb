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
        temporary_dir = Rails.root.join('tmp', 'zip')
        FileUtils.mkdir temporary_dir

        begin
          logger.info { 'Uncompressing the file...' }
          #TODO: this could be improved by only uncompressing the XML, then parsing
          # it to get the node_lookup table and then uncompressing each entry to its
          # final destination
          Dir.chdir(temporary_dir) do
            Zip::File.foreach(package) do |entry|
              path = temporary_dir.join(entry.name)
              FileUtils.mkdir_p(File.dirname(path))
              entry.extract
              logger.info { "\t#{entry.name}" }
            end
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
          lookup_table[:nodes].each do |oldid, newid|
            tmp_dir = Rails.root.join('tmp', 'zip')
            old_attachments_dir = File.expand_path(tmp_dir.join(oldid))

            # Ensure once the path is expanded it's still within the expected
            # tmp directory to prevent unauthorized access to other dirs
            next unless old_attachments_dir.starts_with?(tmp_dir) && File.directory?(old_attachments_dir)

            FileUtils.mkdir_p Attachment.pwd.join(newid.to_s)

            Dir.glob(old_attachments_dir.join('*')).each do |attachment|
              FileUtils.mv(attachment, Attachment.pwd.join(newid.to_s))
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
