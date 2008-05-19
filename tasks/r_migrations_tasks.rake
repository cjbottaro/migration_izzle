namespace :db do
  namespace :migrate do
  
    desc "Force a specific migration script to run."
    task :force => :environment do
      k, v = ENV.to_a.find { |k_v| %w{up down}.include?(k_v[0].downcase) }
      raise Exception.new("invalid argument, use up=<filename> or down=<filename>") if k.nil? or v.nil?
      direction = k.downcase.to_sym
      file_name = v
      
      ActiveRecord::Migrator.force_migrate("db/migrate/", file_name, direction)
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
    
    namespace :history do
    
      Rake::Task["environment"].invoke
    
      connection = ActiveRecord::Base.connection
      table_name = ActiveRecord::Migrator.schema_info_history_table_name
    
      desc "Create the schema info history table.  You never need to call this task manually."
      task :create do
        connection.initialize_schema_information unless connection.tables.include?(table_name)
      end
      
      desc "Initialize the migration history table based on the current database version"
      task :init => :clear do
        trash, stop_at_version = ENV.to_a.find{ |k_v| k_v[0].downcase == 'version' }
        Dir.new(RAILS_ROOT+'/db/migrate').entries.sort.each do |file_name|
          if (match = file_name.match(/(\d\d\d)_([^\.]+)\.rb/))
            version = match[1].to_i
            next if stop_at_version and version > stop_at_version.to_i
            migration_class_name = match[2].split('_').collect{ |w| w.capitalize }.join
            connection.execute "INSERT INTO #{table_name} (version, name, created_at) VALUES (#{version}, '#{migration_class_name}', '#{Time.now}')"
          end
        end
      end
      
      desc "Drop the migration history table"
      task :drop do
        connection.execute "DROP TABLE #{table_name}" if connection.tables.include?(table_name)
      end
      
      desc "List all entries in the history table"
      task :list do
        connection.select_all("SELECT * from #{table_name} ORDER BY version, name").each do |row|
          printf "%03d %s\n", row['version'], row['name']
        end
      end
      
      desc "Clear the history table."
      task :clear => :create do
        connection.execute "TRUNCATE TABLE #{table_name}"
      end
    
    end
  end
end