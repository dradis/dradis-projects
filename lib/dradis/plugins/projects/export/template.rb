module Dradis::Plugins::Projects::Export
  class Template < Dradis::Plugins::Export::Base
    # This method returns an XML representation of current repository which
    # includes Categories, Nodes and Notes
    def export(args={})
      builder = Builder::XmlMarkup.new
      builder.instruct!
      result = builder.tag!('dradis-template', version: version) do |template_builder|
        build_nodes(template_builder)
        build_issues(template_builder)
        build_methodologies(template_builder)
        build_categories(template_builder)
        build_tags(template_builder)
        build_report_content(template_builder)
      end
      return result
    end

    private
    def build_categories(builder);     raise NotImplementedError; end
    def build_issues(builder);         raise NotImplementedError; end
    def build_methodologies(builder);  raise NotImplementedError; end
    def build_nodes(builder);          raise NotImplementedError; end
    def build_tags(builder);           raise NotImplementedError; end
    def build_report_content(builder); raise NotImplementedError; end
    def version;                       raise NotImplementedError; end
  end
end

require_relative 'v1/template'
require_relative 'v2/template'
