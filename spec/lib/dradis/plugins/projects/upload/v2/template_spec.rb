require 'rails_helper'

describe Dradis::Plugins::Projects::Upload::V1::Template::Importer do

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:importer_class) { Dradis::Plugins::Projects::Upload::Template }
  let(:file_path) {
    File.join(File.dirname(__FILE__), '../../../../../../', 'fixtures', 'files', 'issue_with_comments.xml')
  }

  context 'uploading a template with comments in issues' do
    it 'imports the comments' do
      importer = importer_class::Importer.new(
        default_user_id: user.id,
        plugin: importer_class,
        project_id: project.id
      )

      importer.import(file: file_path)

      p_id = project.id
      n_id = project.plugin_uploads_node.id

      expect(project.issues.first.comments.count).to eq 1
      expect(project.issues.first.comments.first.content).to include('This is a comment')
    end
  end
end
