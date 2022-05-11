require 'rails_helper'

describe Dradis::Plugins::Projects::ProjectCloneJob do
  it 'uses correct queue' do
    expect(described_class.new.queue_name).to eq('dradis_project')
  end

  describe '#perform' do
    let(:user) { create(:user, :admin) }

    let(:project) do
      project = create(:project)

      board = create(:board, node: project.methodology_library, project: project)
      list = create(:list, board: board)
      card = create(:card, list: list)
      create_comment_and_activity(card)

      create(:content_block, project: project)

      issue = create(:issue, node: project.issue_library)
      create_comment_and_activity(issue)

      node = create(:node, project: project)

      evidence = create(:evidence, issue: issue, node: node)
      create_comment_and_activity(evidence)

      note = create(:note, node: node)
      create_comment_and_activity(note)

      project
    end

    let(:new_project) do
      new_project = create(:project)
      create(:project_creation, project: new_project)

      new_project
    end

    it 'clones the project' do
      described_class.new.perform(project_id: project.id, new_project_id: new_project.id)

      # Copies boards
      expect(new_project.boards.count).to eq(project.boards.count)

      # Copies lists
      new_project_lists_count = new_project.boards.sum { |board| board.lists.count }
      project_lists_count = project.boards.sum { |board| board.lists.count }
      expect(new_project_lists_count).to eq(project_lists_count)

      # Copies cards
      new_project_cards_count = new_project.boards.sum { |board| board.cards.count }
      project_cards_count = project.boards.sum { |board| board.cards.count }
      expect(new_project_cards_count).to eq(project_cards_count)

      # Copies content blocks
      expect(new_project.content_blocks.count).to eq(project.content_blocks.count)

      # Copies evidence and evidence comments
      expect(new_project.evidence.count).to eq(project.evidence.count)
      expect(comments_count(new_project.evidence)).to eq(comments_count(project.evidence))

      # Copies issues and issue comments
      expect(new_project.issues.count).to eq(project.issues.count)
      expect(comments_count(new_project.issues)).to eq(comments_count(project.issues))

      # Copies nodes
      expect(new_project.nodes.count).to eq(project.nodes.count)
    end

    it 'does not copy activities' do
      described_class.new.perform(project_id: project.id, new_project_id: new_project.id)

      expect(new_project.activities.count).to eq(0)
    end
  end
end

def create_comment_and_activity(item)
  create(:comment, commentable: item)
  create(:activity, trackable: item, user: user)
end

def comments_count(items)
  Comment.where(commentable_id: items.ids, commentable_type: items.first.class).count
end
