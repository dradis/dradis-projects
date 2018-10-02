require 'rails_helper'

describe Dradis::Plugins::Projects::Export::V2::Template do
  let(:exporter_class) { Dradis::Plugins::Projects::Export::V2::Template }
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:export) do
    exporter = exporter_class.new(
      default_user_id: user.id,
      plugin: Dradis::Plugins::Projects,
      project_id: project.id
    )
    exporter.export
  end

  context 'exporting a project' do
    context 'with comments in an issue' do
      before do
        issue = create(:issue, text: 'Issue 1', node: project.issue_library)
        create(:comment, content: 'A comment on an issue', commentable: issue)
      end

      it 'exports comments in the issue' do
        expect(export).to include('A comment on an issue')
      end
    end

    context 'with comments in a note' do
      before do
        node = create(:node, project: project)
        note = create(:note, text: 'Note 1', node: node)
        create(:comment, content: 'A comment on a note', commentable: note)
      end

      it 'exports comments in the note' do
        expect(export).to include('A comment on a note')
      end
    end
  end
end
