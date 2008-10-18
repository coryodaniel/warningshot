module WarningShot
  module TemplateGenerator
    class << self
      def create(path)
        generate_configs(path)
      end
    
      def generate_configs(path)
        from  = WarningShot.dir_for(:templates) / WarningShot::ConfigExt
        copy_templates from, path
      end
      
      private
      def copy_templates(from,to)
        FileUtils.mkdir_p to unless File.exists? to

        Dir[from].each do |file|
          file_dest_path = to / File.basename(file)
          # Add .sample if config is already present
          file_dest_path += '.sample' if File.exists? file_dest_path
          FileUtils.cp file, file_dest_path
        end
      end
      
    end
  end
  
end