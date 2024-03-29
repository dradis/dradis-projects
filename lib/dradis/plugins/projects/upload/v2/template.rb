# DEPRECATED - this class is v2 of the Template Importer and shouldn't be updated.
# V4 released on Apr 2022
# V2 can be removed on Apr 2024
#
# We're duplicating this file for v4, and even though the code lives in two
# places now, this file isn't expected to evolve and is now frozen to V2
# behavior.

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
            user_id: users[author_email]
          )

          if comment.user.nil?
            comment.content = comment.content +
              "\n\nOriginal author not available in this Dradis instance: "\
              "#{author_email}."
          end

          unless validate_and_save(comment)
            logger.info { "comment errors: #{comment.inspect}" }
            return false
          end
        end
      end
    end
  end
end
