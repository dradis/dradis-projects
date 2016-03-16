require 'logger'

class ExportTasks < Thor
  include Dradis::Plugins::thor_helper_module.to_s.constantize

  namespace   "dradis:plugins:projects:export"

  desc "template", "export the current repository structure as a dradis template"
  method_option   :file, type: :string, desc: "the template file to create, or directory to create it in"
  def template
    require 'config/environment'

    logger        = Logger.new(STDOUT)
    logger.level  = Logger::DEBUG
    template_path = options.file || Rails.root.join('backup').to_s

    unless template_path =~ /\.xml\z/
      date          = DateTime.now.strftime("%Y-%m-%d")
      sequence      = Dir.glob(File.join(template_path, "dradis-template_#{date}_*.xml")).collect do |a|
                        a.match(/_([0-9]+)\.xml\z/)[1].to_i
                      end.max || 0

      template_path = File.join(template_path, "dradis-template_#{date}_#{sequence + 1}.xml")
    end

    detect_and_set_project_scope

    exporter = Dradis::Plugins::Projects::Export::Template.new(
      content_service: content_service_for(Dradis::Plugins::Projects::Export::Template),
      logger: logger
    )

    File.open(template_path, 'w') { |f| f.write exporter.export() }

    logger.info { "Template file created at:\n\t#{ File.expand_path( template_path ) }" }
    logger.close
  end


  desc      "package", "creates a copy of your current repository"
  long_desc "Creates a copy of the current repository, including all nodes, notes and " +
            "attachments as a zipped archive. The backup can be imported into another " +
            "dradis instance using the 'Project Package Upload' option."
  method_option   :file, type: :string, desc: "the package file to create, or directory to create it in"
  def package
    require 'config/environment'

    logger        = Logger.new(STDOUT)
    logger.level  = Logger::DEBUG
    package_path  = options.file || Rails.root.join('backup')

    unless package_path =~ /\.zip\z/
      date      = DateTime.now.strftime("%Y-%m-%d")
      sequence  = Dir.glob(File.join(package_path, "dradis-export_#{date}_*.zip")).collect { |a| a.match(/_([0-9]+)\.zip\z/)[1].to_i }.max || 0
      package_path = File.join(package_path, "dradis-export_#{date}_#{sequence + 1}.zip")
    end

    detect_and_set_project_scope

    Dradis::Plugins::Projects::Export::Package.new(
      content_service: content_service_for(Dradis::Plugins::Projects::Export::Package),
      logger: logger
    ).export(filename: package_path)

    logger.info{ "Project package created at:\n\t#{ File.expand_path( package_path ) }" }
    logger.close
  end

end

class UploadTasks < Thor
  include Dradis::Plugins::thor_helper_module.to_s.constantize

  namespace   "dradis:plugins:projects:upload"

  # This task will load into the current database the contents of the template
  # file passed as the first argument
  desc "template FILE", "create a new repository structure from an XML file"
  def template(file_path)
    require 'config/environment'

    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG

    unless File.exists?(file_path)
      $stderr.puts "** the file [#{file_path}] does not exist"
      exit -1
    end

    detect_and_set_project_scope

    content_service  = content_service_for(Dradis::Plugins::Projects::Upload::Template)
    template_service = Dradis::Plugins::TemplateService.new(plugin: Dradis::Plugins::Projects::Upload::Template)

    importer = Dradis::Plugins::Projects::Upload::Template::Importer.new(
      logger:           logger,
      content_service:  content_service,
      template_service: template_service
    )

    importer.import(file: file_path)

    logger.close
  end


  # The reverse operation to the dradis:export:project:package task. From a
  # zipped project package extract the contents of the archive and populate
  # the dradis DB and attachments with them.
  desc "package FILE", "import an entire repository package"
  def package(file_path)
    require 'config/environment'

    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG

    unless File.exists?(file_path)
      $stderr.puts "** the file [#{file_path}] does not exist"
      exit -1
    end


    detect_and_set_project_scope

    content_service  = content_service_for(Dradis::Plugins::Projects::Upload::Package)
    template_service = Dradis::Plugins::TemplateService.new(plugin: Dradis::Plugins::Projects::Upload::Package)

    importer = Dradis::Plugins::Projects::Upload::Package::Importer.new(
                logger: logger,
       content_service: content_service,
      template_service: template_service
    )

    importer.import(file: file_path)

    logger.close
  end

end
