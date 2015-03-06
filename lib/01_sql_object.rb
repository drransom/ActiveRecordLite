require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    columns[0].map! { |name| name.to_sym }

  end

  def self.finalize!
    self.columns.each do |column|
      define_method("#{column}=") do |value|
        attributes[column] = value
      end

      define_method("#{column}") do
        attributes[column]
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    all_results = []
    results.each do |result|
      all_results << self.new(result)
    end
    all_results
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id: id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = :id
    SQL
    results.empty? ? nil : self.new(results[0])
  end

  def initialize(params = {})
    columns = self.class.columns
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless columns.include?(attr_name)
      self.send("#{attr_name}=", value)
    end
  end


  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    col_names = self.class.columns[1..-1].join(", ")
    question_marks = (["?"] * attribute_values.length).join(', ')
    #debugger
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_values = self.class.columns.map { |col| "#{col} = ?" }.join(', ')
    DBConnection.execute(<<-SQL, *(attribute_values + [self.id]))
      UPDATE
        #{self.class.table_name}
      SET
        #{set_values}
      WHERE
        id = ?
    SQL
  end

  def save
    self.id ? update : insert
  end
end
