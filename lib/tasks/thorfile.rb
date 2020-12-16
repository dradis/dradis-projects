require 'logger'

class ExportTasks < Thor
  include Rails.application.config.dradis.thor_helper_module

  namespace   "dradis:plugins:projects:export"

  desc "template", "export the current repository structure as a dradis template"
  method_option   :file, type: :string, desc: "the template file to create, or directory to create it in"
  def template
    require 'config/environment'

    template_path = options.file || Rails.root.join('backup').to_s
    FileUtils.mkdir_p(template_path) unless File.exist?(template_path)

    unless template_path =~ /\.xml\z/
      date = DateTime.now.strftime("%Y-%m-%d")
      base_template_filename = "dradis-template_#{date}.xml"

      template_filename = NamingService.name_file(
        original_filename: base_template_filename,
        pathname: Pathname.new(template_path)
      )

      template_path = File.join(template_path, template_filename)
    end

    detect_and_set_project_scope

    exporter_class = Rails.application.config.dradis.projects.template_exporter
    export_options = task_options.merge(plugin: Dradis::Plugins::Projects)
    exporter       = exporter_class.new(export_options)

    File.open(template_path, 'w') { |f| f.write exporter.export() }

    logger.info { "Template file created at:\n\t#{ File.expand_path( template_path ) }" }
  end


  desc      "package", "creates a copy of your current repository"
  long_desc "Creates a copy of the current repository, including all nodes, notes and " +
            "attachments as a zipped archive. The backup can be imported into another " +
            "dradis instance using the 'Project Package Upload' option."
  method_option   :file, type: :string, desc: "the package file to create, or directory to create it in"
  def package
    require 'config/environment'

    package_path  = options.file || Rails.root.join('backup')
    FileUtils.mkdir_p(package_path) unless File.exist?(package_path)

    unless package_path.to_s =~ /\.zip\z/
      date = DateTime.now.strftime("%Y-%m-%d")
      base_package_filename = "dradis-export_#{date}.zip"

      package_filename = NamingService.name_file(
        original_filename: base_package_filename,
        pathname: Pathname.new(package_path)
      )

      package_path = File.join(package_path, package_filename)
    end

    detect_and_set_project_scope

    export_options = task_options.merge(plugin: Dradis::Plugins::Projects)
    Dradis::Plugins::Projects::Export::Package.new(export_options).
      export(filename: package_path)

    logger.info{ "Project package created at:\n\t#{ File.expand_path( package_path ) }" }
  end
end

class UploadTasks < Thor
  include Rails.application.config.dradis.thor_helper_module

  namespace   "dradis:plugins:projects:upload"

  # This task will load into the current database the contents of the template
  # file passed as the first argument
  desc "template FILE", "create a new repository structure from an XML file"
  def template(file_path)
    require 'config/environment'

    unless File.exists?(file_path)
      $stderr.puts "** the file [#{file_path}] does not exist"
      exit -1
    end

    detect_and_set_project_scope

    default_user_id = @project ? @project.owners.first.id : User.first.id

    task_options.merge!({
      plugin: Dradis::Plugins::Projects::Upload::Template,
      default_user_id: default_user_id
    })

    importer = Dradis::Plugins::Projects::Upload::Template::Importer.new(task_options)
    importer.import(file: file_path)
  end


  # The reverse operation to the dradis:export:project:package task. From a
  # zipped project package extract the contents of the archive and populate
  # the dradis DB and attachments with them.
  desc "package FILE", "import an entire repository package"
  def package(file_path)
    require 'config/environment'

    unless File.exists?(file_path)
      $stderr.puts "** the file [#{file_path}] does not exist"
      exit -1
    end

    detect_and_set_project_scope

    default_user_id = @project ? @project.owners.first.id : User.first.id

    task_options.merge!({
      plugin: Dradis::Plugins::Projects::Upload::Package,
      default_user_id: default_user_id
    })

    importer = Dradis::Plugins::Projects::Upload::Package::Importer.new(task_options)
    importer.import(file: file_path)
  end

end
