require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method("#{name}") do
      through_options = self.class.assoc_options[through_name]
      initial_foreign_key = self.send(through_options.foreign_key)
      source_options = through_options.model_class.assoc_options[source_name]
      results = DBConnection.execute(<<-SQL)
        SELECT
          source_table.*
        FROM
          #{source_options.table_name} AS source_table
        JOIN
          #{through_options.table_name} AS through_table
          ON through_table.#{source_options.foreign_key} = source_table.#{source_options.primary_key}
        WHERE
          through_table.#{through_options.primary_key} = #{initial_foreign_key}
      SQL

      source_options.class_name.constantize.new(results[0])
    end

  end
end
