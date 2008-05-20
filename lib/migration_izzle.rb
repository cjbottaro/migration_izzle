module ActiveRecord
  module ConnectionAdapters
    module SchemaStatements
    
      # This method overwritten by migration_izzle plugin.
      alias_method :initialize_schema_information__rails, :initialize_schema_information
      def initialize_schema_information
        
        # Call Rail's original version of this method.
        initialize_schema_information__rails
        
        # Now add our "histories" table.
        table_name = ActiveRecord::Migrator.schema_info_history_table_name
        unless self.tables.include?(table_name)
          create_table table_name do |t|
            t.column :version, :integer, :null => false
            t.column :name, :string, :null => false
            t.column :created_at, :timestamp
          end
        end
        
      end # def initialize_schema_information

    end # module SchemaStatements
  end # module ConnectionAdapters
  
  class Migrator
    class << self
    
      # This method added by migration_izzle plugin.
      def schema_info_history_table_name
        ActiveRecord::Migrator.schema_info_table_name + '_histories'
      end
    
      # This method overwritten by migration_izzle plugin.
      alias_method :migrate__rails, :migrate
      def migrate(migrations_path, target_version = nil)
      
        # Call Rail's original migrate method which does nothing except for call Base.connection.initialize_schema_information
        # if current_version == target_version which is the condition we want to do our stuff for.
        migrate__rails(migrations_path, target_version)
        
        # Do our stuff.
        up(migrations_path, target_version) if current_version == target_version
        
      end # def migrate
      
      # This method added by migration_izzle plugin.
      def force_migrate(migrations_path, file_name, direction)
        migrator = self.new(direction, migrations_path)
        migrator.force_migrate(file_name)
      end
      
    end # class << self
    
    # This method overwritten by migration_izzle plugin.
    # It's almost the same, but with one line removed and one line added.
    def migrate
      migration_classes.each do |(version, migration_class)|
        Base.logger.info("Reached target version: #{@target_version}") and break if reached_target_version?(version)
        #next if irrelevant_migration?(version) # this line removed

        Base.logger.info "Migrating to #{migration_class} (#{version})"
        migration_class.migrate(@direction)
        update_schema_history(version, migration_class.name) # this line added
        set_schema_version(version)
      end
    end
    
    # This method added by migration_izzle plugin.
    def force_migrate(file_name)
      migration_file = @migrations_path + file_name
      load(migration_file)
      version, name = migration_version_and_name(migration_file)
      migration_class(name).migrate(@direction)
      migration_class_name = migration_class(name).name
      if @direction == :up and !schema_history_exists(version, migration_class_name)
        update_schema_history(version, migration_class_name)
      elsif @direction == :down and schema_history_exists(version, migration_class_name)
        update_schema_history(version, migration_class_name)
      end
    end
    
    private
    
    # This method overwritten by migration_izzle plugin.
    def migration_classes
      sql = "SELECT * FROM #{ActiveRecord::Migrator.schema_info_history_table_name}"
      already_ran = Base.connection.select_all(sql).index_by{|row| row['version'] + row['name']}
      migrations = migration_files.inject([]) do |migrations, migration_file|
        load(migration_file)
        version, name = migration_version_and_name(migration_file)
        already_ran_key = version.to_i.to_s + migration_class(name).name
        migrations << [ version.to_i, migration_class(name) ] if (up? and !already_ran.has_key?(already_ran_key)) or \
                                                                 (down? and already_ran.has_key?(already_ran_key))
        migrations
      end
      down? ? migrations.sort_by{|e| [e[0], e[1].name]}.reverse : migrations.sort_by{|e| [e[0], e[1].name]}
    end # def migration_classes
    
    # This method added by migration_izzle plugin.
    def schema_history_exists(version, name)
      !Base.connection.select_one("SELECT * FROM #{ActiveRecord::Migrator.schema_info_history_table_name} WHERE version=#{version} AND name='#{name}'").blank?
    end # def schema_history_exists
    
    # This method added by migration_izzle plugin.
    def update_schema_history(version, name)
      if up?
        Base.connection.execute("INSERT INTO #{ActiveRecord::Migrator.schema_info_history_table_name} (version, name, created_at) values (#{version}, '#{name}', '#{Time.now}')")
      else
        Base.connection.execute("DELETE FROM #{ActiveRecord::Migrator.schema_info_history_table_name} WHERE version=#{version} AND name='#{name}'")
      end
    end # def set_schema_history
    
  end # class Migrator
  
end
