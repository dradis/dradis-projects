module Dradis::Plugins::Projects::Upload::V3
  module Template
    class Importer < Dradis::Plugins::Projects::Upload::V2::Template::Importer
      private

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
          card.previous_id = lookup_table[:cards][card.previous_id.to_i]
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
          list.previous_id = lookup_table[:lists][list.previous_id].to_i
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
          previous_id: xml_card.at_xpath('previous_id').text.to_i

        xml_card.xpath('activities/activity').each do |xml_activity|
          raise "Couldn't create activity for Card ##{card.id}" unless create_activity(card, xml_activity)
        end

        xml_card.xpath('assignees/assignee').each do |xml_assignee|
         raise "Couldn't create assignment for Card ##{card.id}" unless create_assignee(card, xml_assignee)
        end

        raise "Couldn't create comments for Card ##{card.id}" unless create_comments(card, xml_card.xpath('comments/comment'))

        lookup_table[:cards][xml_card.at_xpath('id').text.to_i] = card.id
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
              previous_id: xml_list.at_xpath('previous_id').text.to_i

            lookup_table[:lists][xml_list.at_xpath('id').text.to_i] = list.id
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
