module Dradis
  module Plugins
    module Projects
      module Export; end
      module Upload; end
    end
  end
end

require 'dradis/plugins/projects/engine'
require 'dradis/plugins/projects/export/package'
require 'dradis/plugins/projects/export/template'
require 'dradis/plugins/projects/upload/package'
require 'dradis/plugins/projects/upload/template'
require 'dradis/plugins/projects/version'
