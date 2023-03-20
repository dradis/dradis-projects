# DEPRECATED - this class is v1 of the Template Importer and shouldn't be updated.
# V4 released on Apr 2022
# V1 can be removed on Apr 2024
#
# We're duplicating this file for v4, and even though the code lives in two
# places now, this file isn't expected to evolve and is now frozen to V1
# behavior.

# frozen_string_literal: true

require 'rails_helper'

describe Dradis::Plugins::Projects::Upload::V1::Template::Importer do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:importer_class) { Dradis::Plugins::Projects::Upload::Template }

  context 'uploading a template with attachments url' do
    let(:file_path) do
      File.join(File.dirname(__FILE__), '../../../../../../', 'fixtures', 'files', 'attachments_url.xml')
    end

    it 'converts the urls' do
      importer = importer_class::Importer.new(
        default_user_id: user.id,
        plugin: importer_class,
        project_id: project.id
      )

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

  context 'uploading a template malformed paths as ids' do
    let(:file_path) do
      File.join(File.dirname(__FILE__), '../../../../../../', 'fixtures', 'files', 'malformed_ids.xml')
    end

    it 'returns false' do
      importer = importer_class::Importer.new(
        default_user_id: user.id,
        plugin: importer_class,
        project_id: project.id
      )

      expect(importer.import(file: file_path)).to be false
    end
  end

  context 'uploading a template with attachment but missing node' do
    let(:file_path) do
      File.join(File.dirname(__FILE__), '../../../../../../', 'fixtures', 'files', 'missing_node.xml')
    end

    it 'does not modify the attachment' do
      logger = double('logger')
      allow(logger).to receive_messages(debug: nil, error: nil, fatal: nil, info: nil)
      expect(logger).to receive(:error).once

      importer = importer_class::Importer.new(
        default_user_id: user.id,
        logger: logger,
        plugin: importer_class,
        project_id: project.id
      )

      importer.import(file: file_path)

      expect(project.issues.first.text).to include(
        "!/pro/projects/222/nodes/12345/attachments/hello.jpg!"
      )
    end
  end
end
