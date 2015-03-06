require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    param_array = params.to_a #can't count on params.keys and params.values being in same order.
    cols = param_array.map { |element| element[0]}
    args = param_array.map { |element| element[1]}
    col_string = cols.join(' = ? AND ') + " = ?"

    results = DBConnection.execute(<<-SQL, *args)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{col_string}
    SQL
    results.map { |result| self.new(result) }
  end
end

class SQLObject
  extend Searchable
end
