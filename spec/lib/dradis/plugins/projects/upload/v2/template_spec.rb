require 'rails_helper'

describe Dradis::Plugins::Projects::Upload::V2::Template::Importer do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:importer_class) { Dradis::Plugins::Projects::Upload::Template }
  let(:file_path) do
    File.join(
      File.dirname(__FILE__),
      '../../../../../../',
      'fixtures',
      'files',
      'with_comments.xml'
    )
  end

  context 'uploading a template with comments' do
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
end
