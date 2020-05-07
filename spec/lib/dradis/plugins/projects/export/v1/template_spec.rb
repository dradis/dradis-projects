require 'rails_helper'

describe Dradis::Plugins::Projects::Export::V2::Template do
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
      node = create(:node, project: project)
      @issue = create(:issue, text: 'Issue 1', node: project.issue_library, state: 'review')
    end

    it 'exports the states of the issues' do
      expect(export).to include("<state>#{@issue.state}</state>")
    end
  end
end
