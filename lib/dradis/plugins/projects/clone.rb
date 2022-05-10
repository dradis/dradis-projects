module Dradis::Plugins::Projects
  class Clone
    attr_accessor :project

    def initialize(project)
      @project = project
    end

    def clone!
      setup_new_project
      @lookup_table = template_importer.parse(template_xml)
      copy_attachment_folders

      true
    end

    private

    def copy_attachment_folders
      @lookup_table[:nodes].each do |old_id, new_id|
        source_directory = Attachment.pwd.join(old_id.to_s)
        next unless File.directory?(source_directory)

        destination_directory = Attachment.pwd.join(new_id.to_s)
        FileUtils.copy_entry(source_directory, destination_directory)
      end
    end

    def setup_new_project
      @new_project = project.dup
      @new_project.name = NamingService.name_project(project.name)
      @new_project.save

      project.permissions.each do |permission|
        @new_project.permissions << permission.dup
      end
    end

    def template_importer
      importer_class = Rails.application.config.dradis.projects.template_uploader

      importer_class.new(
        plugin: Dradis::Plugins::Projects::Upload::Package,
        project_id: @new_project.id
      )
    end

    def template_xml
      exporter_class    = Rails.application.config.dradis.projects.template_exporter
      template_exporter = exporter_class.new(
        plugin: Dradis::Plugins::Projects,
        project_id: project.id
      )

      template_string = template_exporter.export

      template_xml = Nokogiri::XML(template_string)
      template_xml.xpath('//activities/activity').remove
      template_xml
    end
  end
end
