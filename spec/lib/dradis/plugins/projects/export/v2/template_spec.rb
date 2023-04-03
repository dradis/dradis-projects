# DEPRECATED - this class is v2 of the Template Importer and shouldn't be updated.
# V4 released on Apr 2022
# V2 can be removed on Apr 2024
#
# We're duplicating this file for v4, and even though the code lives in two
# places now, this file isn't expected to evolve and is now frozen to V2
# behavior.

require 'rails_helper'

describe 'Dradis::Plugins::Projects::Export::V2::Template' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:export) do
    described_class.new(
      default_user_id: user.id,
      plugin: Dradis::Plugins::Projects,
      project_id: project.id
    ).export
  end

  context 'exporting a project' do
    before do
      @node = create(:node, project: project)
      @issue = create(:issue, text: 'Issue 1', node: project.issue_library)
    end

    context 'with comments in an issue' do
      before do
        create(:comment, content: 'A comment on an issue', commentable: @issue)
      end

      it 'exports comments in the issue' do
        expect(export).to include('A comment on an issue')
      end
    end

    context 'with comments in a note' do
      before do
        note = create(:note, text: 'Note 1', node: @node)
        create(:comment, content: 'A comment on a note', commentable: note)
      end

      it 'exports comments in the note' do
        expect(export).to include('A comment on a note')
      end
    end

    context 'with comments in an evidence' do
      before do
        evidence = create(:evidence, content: 'Test evidence', node: @node, issue: @issue)
        create(:comment, content: 'A comment on an evidence', commentable: evidence)
      end

      it 'exports comments in the evidence' do
        expect(export).to include('A comment on an evidence')
      end
    end

    context 'with comments with a deleted author' do
      before do
        note = create(:note, text: 'Note 1', node: @node)
        comment = create(:comment, content: 'Deleted user', commentable: note)
        comment.update_attribute :user, nil
      end

      it 'exports the comment without errors' do
        expect(export).to include('Deleted user')
      end
    end
  end
end
