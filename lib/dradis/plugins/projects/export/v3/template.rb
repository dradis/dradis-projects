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

          board.to_xml(methodologies_builder, includes: [:activities, :assignees, :comments], version: VERSION)
        end
      end
    end
  end
end
