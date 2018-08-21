require 'rails_helper'

describe Dradis::Plugins::Projects::Upload::V1::Template::Importer do

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:importer_class) { Dradis::Plugins::Projects::Upload::Template }
  let(:file_path) {
    File.join(File.dirname(__FILE__), '../../../../../../', 'fixtures', 'files', 'attachments_url.xml')
  }

  context 'uploading a template with attachments url' do
    it 'converts the urls' do
      importer = importer_class::Importer.new(
        default_user_id: user.id,
        plugin: importer_class,
        project_id: project.id
      )

      importer.import(file: file_path)

      p_id = project.id
      n_id = project.issues.first.node_id

      expect(project.issues.first.text).to include(
        "!/pro/projects/1/nodes/1/attachments/hello.jpg!\n\n" +
        "!/projects/1/nodes/1/attachments/hello.jpg!\n\n" +
        "!/pro/projects/1/nodes/1/attachments/hello.jpg!\n\n" +
        "!/projects/1/nodes/1/attachments/hello.jpg!"
      )
    end
  end
end
