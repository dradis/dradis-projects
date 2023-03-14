module Dradis::Plugins::Projects::Upload::V4
  module Template
    class Importer < Dradis::Plugins::Projects::Upload::Template::Importer

      attr_accessor :attachment_notes, :logger, :pending_changes, :users

      ATTACHMENT_URL = %r{^!(/[a-z]+)?/(?:projects/\d+/)?nodes/(\d+)/attachments/(.+)!$}

      def post_initialize(args={})
        @lookup_table = {
          categories: {},
          nodes: {},
          issues: {}
        }

        @pending_changes = {
          # If the note has an attachment screenshot (i.e. !.../nodes/i/attachments/...!)
          # we will fix the URL to point to the new Node ID.
          #
          # WARNING: we need a lookup table because one note may be referencing a
          # different (yet unprocessed) node's attachments.
          attachment_notes: [],

          # evidence is parsed when nodes are parsed, but cannot be saved until
          # issues have been created. Therefore, parse evidence into arrays until
          # time for creation
          evidence: [],

          # likewise we also need to hold on to the XML about evidence activities
          # and comments until after the evidence has been saved
          evidence_activity: [],
          evidence_comments: [],

          # all children nodes, we will need to find the ID of their new parents.
          orphan_nodes: []
        }
      end

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

      def create_activities(trackable, xml_trackable)
        xml_trackable.xpath('activities/activity').each do |xml_activity|
          # if 'validate_and_save(activity)' returns false, it needs
          # to bubble up to the 'import' method so we can stop execution
          return false unless create_activity(trackable, xml_activity)
        end
      end

      def create_activity(trackable, xml_activity)
        activity = trackable.activities.new(
          action:     xml_activity.at_xpath("action").text,
          created_at: Time.at(xml_activity.at_xpath("created_at").text.to_i)
        )

        activity.project_id = project.id if activity.respond_to?(:project)

        set_activity_user(activity, xml_activity.at_xpath("user_email").text)

        validate_and_save(activity)
      end

      def create_issue(issue, xml_issue)
        # TODO: Need to find some way of checking for dups
        # May be combination of text, category_id and created_at
        issue.author   = xml_issue.at_xpath('author').text.strip
        issue.state    = xml_issue.at_xpath('state')&.text || :published
        issue.text     = xml_issue.at_xpath('text').text
        issue.node     = project.issue_library
        issue.category = Category.issue

        return false unless validate_and_save(issue)

        return false unless create_activities(issue, xml_issue)

        return false unless create_comments(issue, xml_issue.xpath('comments/comment'))

        true
      end

      def finalize(template)
        logger.info { 'Wrapping up...' }

        finalize_nodes()
        finalize_evidence()
        finalize_attachments()

        logger.info { 'Done.' }
      end

      def finalize_attachments
        # Adjust attachment URLs for new Node IDs
        pending_changes[:attachment_notes].each do |item|
          text_attr =
            if defined?(ContentBlock) && item.is_a?(ContentBlock)
              :content
            else
              :text
            end

          logger.info { "Adjusting screenshot URLs: #{item.class.name} ##{item.id}" }

          new_text = update_attachment_references(item.send(text_attr))
          item.send(text_attr.to_s + "=", new_text)

          raise "Couldn't save note attachment URL for #{item.class.name} ##{item.id}" unless validate_and_save(item)
        end
      end

      # Save the Evidence instance to the DB now that we have populated the
      # original issues.
      def finalize_evidence
        pending_changes[:evidence].each_with_index do |evidence, i|
          logger.info { "Setting issue_id for evidence" }
          evidence.issue_id = lookup_table[:issues][evidence.issue_id]

          evidence.content = update_attachment_references(evidence.content)

          raise "Couldn't save Evidence :issue_id / attachment URL Evidence ##{evidence.id}" unless validate_and_save(evidence)

          pending_changes[:evidence_activity][i].each do |xml_activity|
            raise "Couldn't create activity for Evidence ##{evidence.id}" unless create_activity(evidence, xml_activity)
          end

          xml_comments = pending_changes[:evidence_comments][i]
          raise "Couldn't create comments for Evidence ##{evidence.id}" unless create_comments(evidence, xml_comments)
        end
      end

      # Fix relationships between nodes to ensure parents and childrens match
      # with the new assigned :ids
      def finalize_nodes
        pending_changes[:orphan_nodes].each do |node|
          logger.info { "Finding parent for orphaned node: #{node.label}. Former parent was #{node.parent_id}" }
          node.parent_id = lookup_table[:nodes][node.parent_id]
          raise "Couldn't save node parent for Node ##{node.id}" unless validate_and_save(node)
        end
      end

      # Go through the categories, keep a translation table between the old
      # category id and the new ones so we know to which category we should
      # assign our notes
      def parse_categories(template)
        logger.info { 'Processing Categories...' }

        template.xpath('dradis-template/categories/category').each do |xml_category|
          old_id   = Integer(xml_category.at_xpath('id').text.strip)
          name     = xml_category.at_xpath('name').text.strip
          category = nil

          # Prevent creating duplicate categories
          logger.info { "Looking for category: #{name}" }
          category = Category.find_or_create_by!(name: name)
          lookup_table[:categories][old_id] = category.id
        end

        logger.info { 'Done.' }
      end

      # Go through the issues, keep a translation table between the old
      # issue id and the new ones. This is important for importing evidence
      # Will need to adjust node ID after generating node structure
      def parse_issues(template)
        issue = nil

        logger.info { 'Processing Issues...' }

        template.xpath('dradis-template/issues/issue').each do |xml_issue|
          issue = Issue.new

          return false unless create_issue(issue, xml_issue)

          if issue.text =~ %r{^!(.*)/nodes/(\d+)/attachments/(.+)!$}
            pending_changes[:attachment_notes] << issue
          end

          old_id = Integer(xml_issue.at_xpath('id').text.strip)
          lookup_table[:issues][old_id] = issue.id
          logger.info{ "New issue detected: #{issue.title}" }
        end

        logger.info { 'Done.' }

      end

      def parse_methodologies(template)
        methodology_category = Category.default
        methodology_library  = project.methodology_library

        logger.info { 'Processing Methodologies...' }

        template.xpath('dradis-template/methodologies/methodology').each do |xml_methodology|
          # FIXME: this is wrong in a few levels, we should be able to save a
          # Methodology instance calling .save() but the current implementation
          # of the model would consider this a 'methodology template' and not an
          # instance.
          #
          # Also, methodology notes don't have a valid author, see
          # MethodologiesController#create action (i.e. 'methodology builder' is
          # used).
          Note.create!(
            author:      'methodology importer',
            node_id:     methodology_library.id,
            category_id: methodology_category.id,
            text:        xml_methodology.at_xpath('text').text
          )
        end

        logger.info { 'Done.' }
      end

      def parse_node(xml_node)
        element   = xml_node.at_xpath('type-id')
        type_id   = element.text.nil? ? nil : element.text.strip
        label     = xml_node.at_xpath('label').text.strip
        element   = xml_node.at_xpath('parent-id')
        parent_id = element.text.blank? ? nil : element.text.strip

        # Node positions
        element  = xml_node.at_xpath('position')
        position = (element && !element.text.nil?) ? element.text.strip : nil

        # Node properties
        element    = xml_node.at_xpath('properties')
        properties = (element && !element.text.blank?) ? element.text.strip : nil

        created_at = xml_node.at_xpath('created-at')
        updated_at = xml_node.at_xpath('updated-at')

        logger.info { "New node detected: #{label}, parent_id: #{parent_id}, type_id: #{type_id}" }

        # There are exceptions to the rule, when it does not make sense to have
        # more than one of this nodes, in any given tree:
        # - the Configuration.uploadsNode node (detected by its label)
        # - any nodes with type different from DEFAULT or HOST
        if label == Configuration.plugin_uploads_node
          node = project.nodes.create_with(type_id: type_id, parent_id: parent_id)
              .find_or_create_by!(label: label)
        elsif Node::Types::USER_TYPES.exclude?(type_id.to_i)
          node = project.nodes.create_with(label: label)
              .find_or_create_by!(type_id: type_id)
        else
          # We don't want to validate child nodes here yet since they always
          # have invalid parent id's. They'll eventually be validated in the
          # finalize_nodes method.
          has_nil_parent = !parent_id
          node =
            project.nodes.new(
              type_id:   type_id,
              label:     label,
              parent_id: parent_id,
              position:  position
            )
          node.save!(validate: has_nil_parent)
          pending_changes[:orphan_nodes]  << node if parent_id
        end

        if properties
          node.raw_properties = properties
          node.save!(validate: has_nil_parent)
        end

        node.update_attribute(:created_at, created_at.text.strip) if created_at
        node.update_attribute(:updated_at, updated_at.text.strip) if updated_at

        raise "Couldn't create activities for Node ##{node.id}" unless create_activities(node, xml_node)

        parse_node_notes(node, xml_node)
        parse_node_evidence(node, xml_node)

        node
      end

      def parse_nodes(template)
        logger.info { 'Processing Nodes...' }

        # Re generate the Node tree structure
        template.xpath('dradis-template/nodes/node').each do |xml_node|

          node = parse_node(xml_node)

          # keep track of reassigned ids
          # Convert the id to an integer as it has no place being a string, or
          # directory path. We later use this ID to build a directory structure
          # to place attachments and without validation opens the potential for
          # path traversal.
          node_original_id = Integer(xml_node.at_xpath('id').text.strip)
          lookup_table[:nodes][node_original_id] = node.id
        end

        logger.info { 'Done.' }
      end

      # Create array of evidence from xml input. Cannot store in DB until we
      # have a new issue id
      def parse_node_evidence(node, xml_node)
        xml_node.xpath('evidence/evidence').each do |xml_evidence|
          if xml_evidence.at_xpath('author') != nil
            created_at  = xml_evidence.at_xpath('created-at')
            updated_at  = xml_evidence.at_xpath('updated-at')

            evidence = Evidence.new(
                         author:   xml_evidence.at_xpath('author').text.strip,
                         node_id:  node.id,
                         content:  xml_evidence.at_xpath('content').text,
                         issue_id: xml_evidence.at_xpath('issue-id').text.strip
                       )

            evidence.update_attribute(:created_at, created_at.text.strip) if created_at
            evidence.update_attribute(:updated_at, updated_at.text.strip) if updated_at

            pending_changes[:evidence]          << evidence
            pending_changes[:evidence_activity] << xml_evidence.xpath('activities/activity')
            pending_changes[:evidence_comments] << xml_evidence.xpath('comments/comment')

            logger.info { "\tNew evidence added." }
          end
        end
      end

      def parse_node_notes(node, xml_node)
        xml_node.xpath('notes/note').each do |xml_note|

          if xml_note.at_xpath('author') != nil
            old_id = Integer(xml_note.at_xpath('category-id').text.strip)
            new_id = lookup_table[:categories][old_id]

            created_at = xml_note.at_xpath('created-at')
            updated_at = xml_note.at_xpath('updated-at')

            logger.info { "Note category rewrite, used to be #{old_id}, now is #{new_id}" }
            note = Note.create!(
                     author:      xml_note.at_xpath('author').text.strip,
                     node_id:     node.id,
                     category_id: new_id,
                     text:        xml_note.at_xpath('text').text
                   )

            note.update_attribute(:created_at, created_at.text.strip) if created_at
            note.update_attribute(:updated_at, updated_at.text.strip) if updated_at

            raise "Couldn't save Note" unless validate_and_save(note)

            if note.text =~ %r{^!(.*)/nodes/(\d+)/attachments/(.+)!$}
              pending_changes[:attachment_notes] << note
            end

            raise "Couldn't create activities for Note ##{note.id}" unless create_activities(note, xml_note)
            raise "Couldn't create comments for Note ##{note.id}" unless create_comments(note, xml_note.xpath('comments/comment'))

            logger.info { "\tNew note added." }
          end
        end
      end

      def parse_report_content(template); end

      def parse_tags(template)
        logger.info { 'Processing Tags...' }

        template.xpath('dradis-template/tags/tag').each do |xml_tag|
          name = xml_tag.at_xpath('name').text()
          tag_params = { name: name }
          tag_params[:project_id] = project.id if Tag.has_attribute?(:project_id)
          tag = Tag.where(tag_params).first_or_create
          logger.info { "New tag detected: #{name}" }

          xml_tag.xpath('./taggings/tagging').each do |xml_tagging|
            old_taggable_id = Integer(xml_tagging.at_xpath('taggable-id').text())
            taggable_type   = xml_tagging.at_xpath('taggable-type').text()

            new_taggable_id = case taggable_type
                              when 'Note'
                                lookup_table[:issues][old_taggable_id]
                              end

            Tagging.create! tag: tag,
              taggable_id: new_taggable_id, taggable_type: taggable_type
          end
        end

        logger.info { 'Done.' }
      end

      def set_activity_user(activity, email)
        if Activity.column_names.include?('user')
          activity.user = email
        else
          activity.user_id = user_id_for_email(email)
        end
      end

      def update_attachment_references(string)
        string.gsub(ATTACHMENT_URL) do |attachment|
          node_id = lookup_table[:nodes][$2.to_i]
          if node_id
            "!%s/projects/%d/nodes/%d/attachments/%s!" % [$1, project.id, node_id, $3]
          else
            logger.error { "The attachment wasn't included in the package: #{attachment}" }
            attachment
          end
        end
      end

      def user_id_for_email(email)
        users[email] || @default_user_id
      end

      # Cache users to cut down on excess SQL requests
      def users
        @users ||= begin
          User.select([:id, :email]).all.each_with_object({}) do |user, hash|
            hash[user.email] = user.id
          end
        end
      end

      def validate_and_save(instance)
        if instance.save
          return true
        else
          @logger.info{ "Malformed #{ instance.class.name } detected: #{ instance.errors.full_messages }" }
          return false
        end
      end

      # Private: Given a XML node contianing assignee information this method
      # tries to recreate the assignment in the new project.
      #
      #   * If the user exists in this instance: assign the card to that user
      #     (no matter if the user is not a project author).
      #   * If the user doesn't exist, don't creat an assiment and add a note
      #     inside the card's description.
      #
      # card         - the Card object we're creating assignments for.
      # xml_assignee - the Nokogiri::XML::Node that contains node assignment
      #                information.
      #
      # Returns nothing, but creates a new Assignee for this card.
      def create_assignee(card, xml_assignee)
        email   = xml_assignee.text()
        user_id = user_id_for_email(email)

        if user_id == -1
          old_assignee_field = card.fields['FormerAssignees'] || ''
          card.set_field 'FormerAssignees', old_assignee_field << "* #{email}\n"
        else
          old_assignee_ids  = card.assignee_ids
          card.assignee_ids = old_assignee_ids + [user_id]
        end
      end

      # Private: Reassign cross-references once all the objects in the project
      # have been recreated.
      #
      # No arguments received, but the methods relies on :lookup_table and
      # :pending_changes provided by dradis-projects.
      #
      # Returns nothing.
      def finalize_cards
        logger.info { 'Reassigning card positions...' }

        # Fix the :previous_id with the new card IDs
        pending_changes[:cards].each do |card|
          card.previous_id = lookup_table[:cards][card.previous_id]
          raise "Couldn't save card's position" unless validate_and_save(card)
        end

        logger.info { 'Done.' }
      end

      # Private: Reassign the List's :previous_id now that we know what are the
      # new IDs that correspond to all List objects in the import.
      #
      # No arguments received, but the method relies on :lookup_table and
      # :pending_changes provided by dradis-projects.
      #
      # Returns nothing.
      def finalize_lists
        logger.info { 'Reassigning list positions...' }

        # Fix the :previous_id with the new card IDs
        pending_changes[:lists].each do |list|
          list.previous_id = lookup_table[:lists][list.previous_id]
          raise "Couldn't save list's position" unless validate_and_save(list)
        end

        logger.info { 'Done.' }
      end

      # Private: Restore Board, List and Card information from the project
      # template.
      def parse_methodologies(template)
        if template_version == 1
          # Restore Board from old xml methodology format
          process_v1_methodologies(template)
        else
          process_v2_methodologies(template)
        end
      end

      # Private:  For each XML card block, we're creating a new Card instance,
      # restoring the card's Activities and Assignments.
      #
      # list     - the List instance that will hold this Card.
      # xml_card - the Nokogiri::XML node containing the card's data.
      #
      # Returns nothing, but makes use of the :lookup_table and :pending_changes
      # variables to store information that will be used during the
      # :finalize_cards method.
      def process_card(list, xml_card)
        due_date = xml_card.at_xpath('due_date').text
        due_date = Date.iso8601(due_date) unless due_date.empty?

        card = list.cards.create name: xml_card.at_xpath('name').text,
          description: xml_card.at_xpath('description').text,
          due_date: due_date,
          previous_id: xml_card.at_xpath('previous_id').text&.to_i

        xml_card.xpath('activities/activity').each do |xml_activity|
          raise "Couldn't create activity for Card ##{card.id}" unless create_activity(card, xml_activity)
        end

        xml_card.xpath('assignees/assignee').each do |xml_assignee|
         raise "Couldn't create assignment for Card ##{card.id}" unless create_assignee(card, xml_assignee)
        end

        raise "Couldn't create comments for Card ##{card.id}" unless create_comments(card, xml_card.xpath('comments/comment'))

        xml_id = Integer(xml_card.at_xpath('id').text)
        lookup_table[:cards][xml_id] = card.id
        pending_changes[:cards] << card
      end

      # Private: Initial pass over ./methodologies/ section of the tempalte
      # document to extract Board, List and Card information. Some of the
      # objects will contain invalid references (e.g. the former :previous_id
      # of a card will need to be reassigned) that we will fix at a later stage.
      #
      # template - A Nokogiri::XML document containing the project template
      #            data.
      #
      # Returns nothing.
      def process_methodologies(template)
        logger.info { 'Processing Methodologies...' }

        lookup_table[:cards]    = {}
        lookup_table[:lists]    = {}
        pending_changes[:cards] = []
        pending_changes[:lists] = []

        template.xpath('dradis-template/methodologies/board').each do |xml_board|
          xml_node_id = xml_board.at_xpath('node_id').try(:text)
          node_id =
            if xml_node_id.present?
              lookup_table[:nodes][xml_node_id.to_i]
            else
              project.methodology_library.id
            end

          board = content_service.create_board(
            name: xml_board.at_xpath('name').text,
            node_id: node_id
          )

          xml_board.xpath('./list').each do |xml_list|
            list = board.lists.create name: xml_list.at_xpath('name').text,
              previous_id: xml_list.at_xpath('previous_id').text&.to_i
            xml_id = Integer(xml_list.at_xpath('id').text)

            lookup_table[:lists][xml_id] = list.id
            pending_changes[:lists] << list

            xml_list.xpath('./card').each do |xml_card|
              process_card(list, xml_card)
            end
          end
        end

        logger.info { 'Done.' }
      end

      # Private: Pass over old ./methodologies/ sections of the template
      # document to extract Board, List and Card information.
      #
      # template - A Nokogiri::XML document containing the project template
      #            data.
      #
      # Returns nothing.
      def process_v1_methodologies(template)
        xml_methodologies = template.xpath('dradis-template/methodologies/methodology')
        return if xml_methodologies.empty?

        logger.info { 'Processing V1 Methodologies...' }

        migration = MethodologyMigrationService.new(project.id)

        xml_methodologies.each do |xml_methodology|
          migration.migrate(
            Methodology.new(content: xml_methodology.at_xpath('text').text)
          )
        end

        logger.info { 'Done.' }
      end

      # Private: Pass over new ./methodologies/ sections of the template
      # document to extract Board, List and Card information.
      #
      # template - A Nokogiri::XML document containing the project template
      #            data.
      #
      # Returns nothing.
      def process_v2_methodologies(template)
        # Restore Board
        process_methodologies(template)

        # Reassign Card's :previous_id and :assginees
        finalize_cards()

        # Reassign List's :previous id
        finalize_lists()
      end
    end
  end
end
