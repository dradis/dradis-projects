# Run the spec in CE/Pro context with:
# rspec <relative path to dradis-projects>/spec/lib/dradis/plugins/projects/upload/template_spec.rb

require 'rails_helper'

describe 'Dradis::Plugins::Projects::Upload::Template::Importer' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:importer_class) { Dradis::Plugins::Projects::Upload::Template }
  let(:importer) do
    importer_class::Importer.new(
      default_user_id: user.id,
      plugin: importer_class,
      project_id: project.id
    )
  end
  let(:dir) do
    File.join(File.dirname(__FILE__), '../../../../../', 'fixtures', 'files')
  end

  context 'uploading a template with a recoverable XML error (e.g. an invalid UTF-8 byte)' do
    let(:file_path) { File.join(dir, 'invalid_byte_recoverable.xml') }

    it 'still imports the template' do
      expect(importer.import(file: file_path)).not_to be false
    end

    it 'creates the issue with its content scrubbed instead of being dropped' do
      importer.import(file: file_path)

      expect(project.issues.count).to eq(1)
      expect(project.issues.first.text).to include('Sample Issue')
    end

    it 'logs a warning instead of a fatal error' do
      logger = double('logger')
      allow(logger).to receive_messages(debug: nil, error: nil, fatal: nil, info: nil, warn: nil)
      expect(logger).to receive(:warn).at_least(:once)
      expect(logger).not_to receive(:error)

      importer = importer_class::Importer.new(
        default_user_id: user.id,
        logger: logger,
        plugin: importer_class,
        project_id: project.id
      )

      importer.import(file: file_path)
    end
  end

  context 'uploading a template with an unrecoverable XML error (e.g. a truncated file)' do
    let(:file_path) { File.join(dir, 'truncated_unrecoverable.xml') }

    it 'returns false' do
      expect(importer.import(file: file_path)).to be false
    end

    it 'does not import anything' do
      importer.import(file: file_path)

      expect(project.issues.count).to eq(0)
    end

    it 'logs a fatal error' do
      logger = double('logger')
      allow(logger).to receive_messages(debug: nil, error: nil, fatal: nil, info: nil, warn: nil)
      expect(logger).to receive(:error).at_least(:once)

      importer = importer_class::Importer.new(
        default_user_id: user.id,
        logger: logger,
        plugin: importer_class,
        project_id: project.id
      )

      importer.import(file: file_path)
    end
  end
end
