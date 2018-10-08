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
  end
end
