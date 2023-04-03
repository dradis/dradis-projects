# Run the spec in CE/Pro context with:
# rspec <relative path to dradis-projects>/spec/lib/dradis/plugins/projects/export/v4/template_spec.rb

require 'rails_helper'

describe 'Dradis::Plugins::Projects::Export::V4::Template' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:exporter) { 'Dradis::Plugins::Projects::Export::V4::Template' }
  let(:export) do
    exporter.constantize.new(
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

    describe 'comments' do
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

    describe 'states' do
      before do
        Issue.states.each do |state|
          create(:issue, text: 'Issue 1', node: project.issue_library, state: state[0])
        end
      end

      it 'export issues with states' do
        Issue.states.each do |state|
          expect(export).to include("<state>#{state[0]}</state>")
        end
      end
    end
  end
end
