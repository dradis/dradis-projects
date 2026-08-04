# Run the spec in CE/Pro context with:
# rspec <relative path to dradis-projects>/spec/lib/dradis/plugins/projects/upload/package_spec.rb

require 'rails_helper'

describe 'Dradis::Plugins::Projects::Upload::Package::Importer' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:importer_class) { Dradis::Plugins::Projects::Upload::Package }
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

  context 'when the packaged template has a recoverable XML error' do
    let(:file_path) { File.join(dir, 'package_with_recoverable_error.zip') }

    it 'imports the package successfully' do
      expect(importer.import(file: file_path)).to be true
    end

    it 'creates the issue from the package' do
      importer.import(file: file_path)

      expect(project.issues.count).to eq(1)
    end
  end

  context 'when the packaged template has an unrecoverable XML error' do
    let(:file_path) { File.join(dir, 'package_with_unrecoverable_error.zip') }

    it 'returns false instead of raising an unhandled error' do
      expect { importer.import(file: file_path) }.not_to raise_error
      expect(importer.import(file: file_path)).to be false
    end

    it 'logs a clear error message' do
      logger = double('logger')
      allow(logger).to receive_messages(debug: nil, error: nil, fatal: nil, info: nil, warn: nil)
      expect(logger).to receive(:error).with('Failed to import the project template file.')

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
