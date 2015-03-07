require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      class_name: name.to_s.singularize.camelcase,
      primary_key: :id,
      foreign_key: ((name.to_s.singularize.underscore)+"_id").to_sym
    }
    options = defaults.merge(options)
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      class_name: name.to_s.singularize.camelcase,
      primary_key: :id,
      foreign_key: ((self_class_name.to_s.singularize.underscore)+"_id").to_sym
    }
    options = defaults.merge(options)
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end

end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name.to_sym] = options

    define_method("#{name}") do
      foreign_key = self.send(options.foreign_key)
      return nil if foreign_key.nil?
      table_name = options.table_name
      primary_key = options.primary_key

      results = DBConnection.execute(<<-SQL)
        SELECT
          *
        FROM
          #{table_name}
        WHERE
          #{primary_key} = #{foreign_key}
        LIMIT 1
      SQL
      options.class_name.constantize.new(results[0])
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)

    define_method("#{name}") do
      primary_key = self.send(options.primary_key)
      table_name = options.table_name
      foreign_key = options.foreign_key
      results = DBConnection.execute(<<-SQL)
        SELECT
          *
        FROM
          #{table_name}
        WHERE
          #{primary_key} = #{foreign_key}
      SQL
      output = []
      results.each do |result|
        output << options.class_name.constantize.new(result)
      end
      output
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
