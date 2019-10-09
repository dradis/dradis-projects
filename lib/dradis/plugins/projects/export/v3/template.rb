module Dradis::Plugins::Projects::Export::V3
  class Template < Dradis::Plugins::Projects::Export::V2::Template
    VERSION = 3

    protected

    def build_methodologies(builder)
      boards = content_service.all_boards

      builder.methodologies do |methodologies_builder|

        boards.each do |board|
          node_id =
            board.node == project.methodology_library ? nil : board.node_id

          methodologies_builder.board(version: VERSION) do |board_builder|
            board_builder.id(board.id)
            board_builder.name(board.name)
            board_builder.node_id(node_id)

            board.ordered_items.each do |list|

              board_builder.list do |list_builder|
                list_builder.id(list.id)
                list_builder.name(list.name)
                list_builder.previous_id(list.previous_id)

                list.ordered_items.each do |card|

                  list_builder.card do |card_builder|
                    card_builder.id(card.id)
                    card_builder.name(card.name)
                    card_builder.description do
                      card_builder.cdata!(card.description)
                    end
                    card_builder.due_date(card.due_date)
                    card_builder.previous_id(card.previous_id)

                    card_builder.assignees do |assignee_builder|
                      card.assignees.each do |assignee|
                        assignee_builder.assignee(assignee.email)
                      end
                    end

                    build_activities_for(card_builder, card)
                    build_comments_for(card_builder, card)
                  end

                end
              end
            end
          end
        end
      end
    end
  end
end
