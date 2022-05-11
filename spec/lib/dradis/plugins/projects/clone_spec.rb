require 'rails_helper'

describe Dradis::Plugins::Projects::Clone do
  let(:owner) { create(:user, :admin) }
  let(:tester1) { create(:user, :author) }
  let(:tester2) { create(:user, :author) }

  let!(:project) do
    project = create(:project, name: 'My project')
    project.assign_owner(owner)
    project.authors << tester1
    project.authors << tester2

    project
  end

  let(:instance) { described_class.new(project) }
  describe '#clone!' do
    it 'creates a new project' do
      expect {
        instance.clone!
      }.to change { Project.count }.by(1)
    end

    it 'creates a project creation for the new project' do
      expect {
        instance.clone!
      }.to change { ProjectCreation.count }.by(1)

      expect(Project.last.project_creation).to be_present
    end

    it 'copies permissions to the new project' do
      new_project = instance.clone!

      expect(new_project.owners).to eq(project.owners)
      expect(new_project.authors).to eq(project.authors)
    end
  end
end
