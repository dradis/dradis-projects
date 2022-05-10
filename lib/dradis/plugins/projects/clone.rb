module Dradis::Plugins::Projects
  class Clone
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def clone!
      setup_new_project

      ProjectCloneJob.perform_later(new_project_id: new_project.id, project_id: project.id)

      new_project
    end

    private

    attr_reader :new_project

    def create_new_project
      @new_project = project.dup
      new_project.name = NamingService.name_project(project.name)
      new_project.save
    end

    def setup_new_project
      create_new_project
      create_permissions
      ProjectCreation.create!(project: new_project)
    end

    def create_permissions
      project.permissions.each do |permission|
        new_project.permissions << permission.dup
      end
    end
  end
end
