module Dradis::Plugins::Projects::Export::V2
  class Template < Dradis::Plugins::Projects::Export::V1::Template
    VERSION = 2

    protected

    def build_comments_for(builder, commentable)
      builder.comments do |comments_builder|
        commentable.comments.each do |comment|
          comments_builder.comment do |comment_builder|
            comment_builder.content do
              comment_builder.cdata!(comment.content)
            end
            comment_builder.author(comment.user.email)
            comment_builder.created_at(comment.created_at.to_i)
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

  end
end
