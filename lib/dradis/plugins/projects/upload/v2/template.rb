module Dradis::Plugins::Projects::Upload::V2
  module Template
    class Importer < Dradis::Plugins::Projects::Upload::V1::Template::Importer
      private

      def create_comments(commentable, xml_comments)
        return true if xml_comments.empty?

        xml_comments.each do |xml_comment|
          author_email = xml_comment.at_xpath('author').text
          comment = Comment.new(
            commentable_id: commentable.id,
            commentable_type: commentable.class.to_s,
            content: xml_comment.at_xpath('content').text,
            created_at: Time.at(xml_comment.at_xpath('created_at').text.to_i),
            user_id: user_id_for_email(author_email)
          )

          if comment.user.email != author_email
            comment.content = comment.content +
              "\n\nOriginal author not available in this Dradis instance: "\
              "#{author_email}."
          end

          return false unless validate_and_save(comment)
        end
      end
    end
  end
end
