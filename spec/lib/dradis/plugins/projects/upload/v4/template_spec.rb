# Run the spec in CE/Pro context with:
# rspec <relative path to dradis-projects>/spec/lib/dradis/plugins/projects/upload/v4/template_spec.rb

require 'rails_helper'

describe 'Dradis::Plugins::Projects::Upload::V4::Template::Importer' do
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

  context 'uploading a template with comments' do
    let(:file_path) do
      File.join(
        File.dirname(__FILE__),
        '../../../../../../',
        'fixtures',
        'files',
        'with_comments.xml'
      )
    end

    before do
      importer = importer_class::Importer.new(
        default_user_id: user.id,
        plugin: importer_class,
        project_id: project.id
      )

      importer.import(file: file_path)
    end

    let(:node) { project.nodes.find_by(label: 'Node 1') }

    it 'imports comments in issues' do
      issue = project.issues.first
      expect(issue.comments.first.content).to include('A comment on an issue')
    end

    it 'imports comments in notes' do
      note = node.notes.first
      expect(note.comments.first.content).to include('A comment on a note')
    end

    it 'imports comments in evidence' do
      evidence = node.evidence.first
      expect(evidence.comments.first.content).to include('A comment on an evidence')
    end

    it 'imports comments without user' do
      issue = project.issues.first
      note = node.notes.first
      evidence = node.evidence.first

      aggregate_failures do
        expect(issue.comments.first.user).to be_nil
        expect(note.comments.first.user).to be_nil
        expect(evidence.comments.first.user).to be_nil
      end
    end
  end


  describe 'states' do
    let(:dir) do
      File.join(File.dirname(__FILE__), '../../../../../../', 'fixtures', 'files')
    end

    before do
      @importer = importer_class::Importer.new(
        default_user_id: user.id,
        plugin: importer_class,
        project_id: project.id
      )
    end

    context 'uploading a template without states' do
      it 'imports issues with the published state' do
        @importer.import(file: File.join(dir, 'with_comments.xml'))
        issue = project.issues.first
        expect(issue.state).to eq('published')
      end
    end

    context 'uploading a template with states' do
      context 'valid states' do
        it 'imports issues with states from the template' do
          @importer.import(file: File.join(dir, 'with_states.xml'))
          issue = project.issues.first
          expect(issue.state).to eq('ready_for_review')
        end
      end

      context 'invalid states' do
        it 'does not import the issue' do
          @importer.import(file: File.join(dir, 'with_invalid_states.xml'))
          expect(project.issues.count).to eq(0)
        end
      end
    end
  end
end
