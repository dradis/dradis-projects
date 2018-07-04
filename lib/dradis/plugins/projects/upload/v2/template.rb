module Dradis::Plugins::Projects::Upload::V2
  module Template
    class Importer < Dradis::Plugins::Projects::Upload::V1::Template::Importer
      private

      def create_comments(commentable, xml_comments)
        return true if xml_comments.empty?

        xml_comments.each do |xml_comment|
          comment = commentable.comments.new(
            content: xml_comment.at_xpath('content').text,
            created_at: Time.at(xml_comment.at_xpath('created_at').text.to_i),
            user_id: user_id_for_email(xml_comment.at_xpath('author').text)
          )

          return false unless validate_and_save(comment)
        end
      end

      def create_issue(issue, xml_issue)
        # TODO: Need to find some way of checking for dups
        # May be combination of text, category_id and created_at
        issue.author   = xml_issue.at_xpath('author').text.strip
        issue.text     = xml_issue.at_xpath('text').text
        issue.node     = Node.issue_library
        issue.category = Category.issue

        return false unless validate_and_save(issue)

        return false unless create_activities(issue, xml_issue)
        return false unless create_comments(issue, xml_issue.xpath('comments/comment'))
      end

    end
  end
end
