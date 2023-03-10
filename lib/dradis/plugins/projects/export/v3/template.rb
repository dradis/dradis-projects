# DEPRECATED - this class is v3 of the Template Exporter and shouldn't be updated.
# V4 released on Apr 2022
# V3 can be removed on Apr 2024
#
# We're duplicating this file for v4, and even though the code lives in two
# places now, this file isn't expected to evolved and is now frozen to V3
# behavior.

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
