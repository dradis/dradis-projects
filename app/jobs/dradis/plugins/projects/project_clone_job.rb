module Dradis::Plugins::Projects
  class ProjectCloneJob < ApplicationJob
    queue_as :dradis_project

    def perform(project_id:, new_project_id:)
      @new_project = Project.find_by_id(new_project_id)
      @project = Project.find_by_id(project_id)

      @lookup_table = template_importer.parse(template_xml)
      copy_attachment_folders

      new_project.project_creation.completed!
    end

    private

    attr_reader :new_project, :project

    def copy_attachment_folders
      @lookup_table[:nodes].each do |old_id, new_id|
        source_directory = Attachment.pwd.join(old_id.to_s)
        next unless File.directory?(source_directory)

        destination_directory = Attachment.pwd.join(new_id.to_s)
        FileUtils.copy_entry(source_directory, destination_directory)
      end
    end

    def template_exporter
      exporter_class = Rails.application.config.dradis.projects.template_exporter
      exporter_class.new(plugin: Dradis::Plugins::Projects, project_id: project.id)
    end

    def template_importer
      importer_class = Rails.application.config.dradis.projects.template_uploader
      importer_class.new(plugin: Dradis::Plugins::Projects::Upload::Package, project_id: new_project.id)
    end

    def template_xml
      template_string = template_exporter.export

      template_xml = Nokogiri::XML(template_string)
      template_xml.xpath('//activities/activity').remove
      template_xml
    end
  end
end
