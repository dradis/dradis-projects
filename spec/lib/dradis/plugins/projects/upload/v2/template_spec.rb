require 'rails_helper'

describe Dradis::Plugins::Projects::Upload::V1::Template::Importer do

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:importer_class) { Dradis::Plugins::Projects::Upload::Template }
  let(:file_path) {
    File.join(File.dirname(__FILE__), '../../../../../../', 'fixtures', 'files', 'with_comments.xml')
  }

  context 'uploading a template with comments' do
    before do
      importer = importer_class::Importer.new(
        default_user_id: user.id,
        plugin: importer_class,
        project_id: project.id
      )

      importer.import(file: file_path)
    end

    it 'imports comments in issues' do
      issue = project.issues.first
      expect(issue.comments.first.content).to include('A comment on an issue')
    end

    it 'imports comments in notes' do
      note = project.nodes.find_by(label: "Node 1").notes.first
      expect(note.comments.first.content).to include('A comment on a note')
    end
  end
end
