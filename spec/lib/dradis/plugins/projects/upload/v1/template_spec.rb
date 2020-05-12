require 'rails_helper'

# To run, execute from Dradis main app folder:
#   bin/rspec [dradis-projects path]/<file_path>

describe Dradis::Plugins::Projects::Upload::V1::Template::Importer do

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:importer_class) { Dradis::Plugins::Projects::Upload::Template }
  let(:importer) do
    importer_class::Importer.new(
      state: :published,
      default_user_id: user.id,
      plugin: importer_class,
      project_id: project.id
    )
  end

  context 'uploading a template with attachments url' do
    let(:file_path) {
      File.join(File.dirname(__FILE__), '../../../../../../', 'fixtures', 'files', 'attachments_url.xml')
    }

    it 'converts the urls' do
      importer.import(file: file_path)

      p_id = project.id
      n_id = project.plugin_uploads_node.id

      expect(project.issues.first.text).to include(
        "!/pro/projects/#{p_id}/nodes/#{n_id}/attachments/hello.jpg!\n\n" +
        "!/projects/#{p_id}/nodes/#{n_id}/attachments/hello.jpg!\n\n" +
        "!/pro/projects/#{p_id}/nodes/#{n_id}/attachments/hello.jpg!\n\n" +
        "!/projects/#{p_id}/nodes/#{n_id}/attachments/hello.jpg!"
      )
    end
  end

  describe 'issue states' do

    context 'template without states' do
      let(:file_path) {
        File.join(File.dirname(__FILE__), '../../../../../../', 'fixtures', 'files', 'without_states.xml')
      }

      it 'uploads the issues with the published state' do
        importer.import(file: file_path)

        expect(project.issues.pluck(:state)).to match_array(['published', 'published', 'published'])
      end
    end

    context 'template with states' do
      let(:file_path) {
        File.join(File.dirname(__FILE__), '../../../../../../', 'fixtures', 'files', 'with_states.xml')
      }

      it 'uploads the issues with the states' do
        importer.import(file: file_path)

        expect(project.issues.pluck(:state)).to match_array(['draft', 'review', 'published'])
      end
    end

    context 'template with invalid states' do
      let(:file_path) {
        File.join(File.dirname(__FILE__), '../../../../../../', 'fixtures', 'files', 'with_invalid_states.xml')
      }

      it 'uploads the issues with the states' do
        importer.import(file: file_path)

        expect(project.issues.pluck(:state)).to match_array(['published', 'published', 'published'])
      end
    end
  end
end
