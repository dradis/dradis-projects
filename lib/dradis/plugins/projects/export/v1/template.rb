# DEPRECATED - this class is v1 of the Template Exporter and shouldn't be updated.
# V4 released on Apr 2022
# V1 can be removed on Apr 2024
#
# We're duplicating this file for v4, and even though the code lives in two
# places now, this file isn't expected to evolve and is now frozen to V1
# behavior.

module Dradis::Plugins::Projects::Export::V1
  class Template < Dradis::Plugins::Projects::Export::Template
    VERSION = 1

    protected

    def build_activities_for(builder, trackable)
      builder.activities do |activities_builder|
        trackable.activities.each do |activity|
          activities_builder.activity do |activity_builder|
            activity_builder.action(activity.action)
            activity_builder.user_email(user_email_for_activity(activity))
            activity_builder.created_at(activity.created_at.to_i)
          end
        end
      end
    end

    def build_categories(builder)
      categories = []
      categories << Category.issue if @issues.any?
      categories += @nodes.map do |node|
        node.notes.map { |note| note.category }.uniq
      end.flatten.uniq

      builder.categories do |categories_builder|
        categories.each do |category|
          categories_builder.category do |category_builder|
            category_builder.id(category.id)
            category_builder.name(category.name)
          end
        end
      end
    end

    # No-op here, overwritten in V2
    def build_comments_for(builder, commentable); end

    def build_evidence_for_node(builder, node)
      builder.evidence do |evidences_builder|
        node.evidence.each do |evidence|
          evidences_builder.evidence do |evidence_builder|
            evidence_builder.id(evidence.id)
            evidence_builder.author(evidence.author)
            evidence_builder.tag!('issue-id', evidence.issue_id)
            evidence_builder.content do
              evidence_builder.cdata!(evidence.content)
            end
            build_activities_for(evidence_builder, evidence)
            build_comments_for(evidence_builder, evidence)
          end
        end
      end
    end

    def build_issues(builder)
      @issues = Issue.where(node_id: project.issue_library).includes(:activities)

      builder.issues do |issues_builder|
        @issues.each do |issue|
          issues_builder.issue do |issue_builder|
            issue_builder.id(issue.id)
            issue_builder.author(issue.author)
            issue_builder.text do
              issue_builder.cdata!(issue.text)
            end
            build_activities_for(issue_builder, issue)
            build_comments_for(issue_builder, issue)
          end
        end
      end
    end

    def build_methodologies(builder)
      methodologies = project.methodology_library.notes
      builder.methodologies do |methodologies_builder|
        methodologies.each do |methodology|
          methodologies_builder.methodology(version: VERSION) do |methodology_builder|
            methodology_builder.text do
              methodology_builder.cdata!(methodology.text)
            end
          end
        end
      end
    end

    def build_nodes(builder)
      @nodes = project.nodes.includes(:activities, :evidence, :notes, evidence: [:activities], notes: [:activities, :category]).all.reject do |node|
        [Node::Types::METHODOLOGY,
          Node::Types::ISSUELIB].include?(node.type_id)
      end

      builder.nodes do |nodes_builder|
        @nodes.each do |node|
          nodes_builder.node do |node_builder|
            node_builder.id(node.id)
            node_builder.label(node.label)
            node_builder.tag!('parent-id', node.parent_id)
            node_builder.position(node.position)
            node_builder.properties do
              node_builder.cdata!(node.raw_properties)
            end
            node_builder.tag!('type-id', node.type_id)
            # Notes
            build_notes_for_node(node_builder, node)
            # Evidence
            build_evidence_for_node(node_builder, node)
            build_activities_for(node_builder, node)
          end
        end
      end
    end

    def build_notes_for_node(builder, node)
      builder.notes do |notes_builder|
        node.notes.each do |note|
          notes_builder.note do |note_builder|
            note_builder.id(note.id)
            note_builder.author(note.author)
            note_builder.tag!('category-id', note.category_id)
            note_builder.text do
              note_builder.cdata!(note.text)
            end
            build_activities_for(note_builder, note)
            build_comments_for(note_builder, note)
          end
        end
      end
    end

    # No-op here, overwritten in PRO
    def build_report_content(builder); end

    def build_tags(builder)
      tags = project.tags
      builder.tags do |tags_builder|
        tags.each do |tag|
          tags_builder.tag do |tag_builder|
            tag_builder.id(tag.id)
            tag_builder.name(tag.name)
            tag_builder.taggings do |taggings_builder|
              tag.taggings.each do |tagging|
                taggings_builder.tagging do |tagging_builder|
                  tagging_builder.tag!('taggable-id', tagging.taggable_id)
                  tagging_builder.tag!('taggable-type', tagging.taggable_type)
                end
              end
            end
          end
        end
      end
    end


    # Cache user emails so we don't have to make an extra SQL request
    # for every activity
    def user_email_for_activity(activity)
      return activity.user if activity.user.is_a?(String)

      @user_emails ||= begin
        User.select([:id, :email]).all.each_with_object({}) do |user, hash|
          hash[user.id] = user.email
        end
      end
      @user_emails[activity.user_id]
    end

    # Use the class VERSION constant, but allow for subclasses to overwrite it.
    #
    # See:
    #   http://stackoverflow.com/questions/3174563/how-to-use-an-overridden-constant-in-an-inheritanced-class
    def version
      self.class::VERSION
    end
  end
end
