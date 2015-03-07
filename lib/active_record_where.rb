class ActiveRecordLite
  def to_s
    fire_query.to_s
  end

  def to_a
    fire_query.to_a
  end

  def fire_query
    sql = construct_sql
    DBConnection.execute(<<-SQL)
      #{sql}
    SQL
    end
  end

  def where_conditions
    @where_conditions = []
  end

  def construct_sql
    @where_conditions.join(" ")
  end

end
