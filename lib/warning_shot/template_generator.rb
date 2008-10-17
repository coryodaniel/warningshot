module WarningShot
  module TemplateGenerator
    class << self
      def create(path)
        generate_configs(path)
        #generate_scripts(path,'bash')
        #generate_scripts(path,'ruby')
      end
    
      def generate_configs(path)
        from  = File.join(WarningShot.dir_for(:templates),WarningShot::ConfigExt)
        copy_templates from, path
      end
      
      #def generate_scripts(path,type)
      #  scripts_path = File.join('scripts',type)
      #  from  = File.join(WarningShot.dir_for(:templates),scripts_path,"*")
      #  to    = File.join(path,scripts_path)

      #  copy_templates from, to
      #end 
      
      private
      def copy_templates(from,to)
        FileUtils.mkdir_p to unless File.exists? to

        Dir[from].each do |file|
          file_dest_path = File.join(to,File.basename(file))
          # Add .sample if config is already present
          file_dest_path += '.sample' if File.exists? file_dest_path
          FileUtils.cp file, file_dest_path
        end
      end
      
    end
  end
  
end