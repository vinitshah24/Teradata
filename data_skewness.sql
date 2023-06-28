-- Declare variables
DECLARE @table_name VARCHAR(128);
DECLARE @primary_key_columns VARCHAR(4000);
DECLARE @sql_query VARCHAR(4000);

-- Set the table name
SET @table_name = 'your_table'; -- Replace with your table name

-- Fetch primary key column names
SELECT
    TRIM(c.ColumnName)
INTO :@primary_key_columns
FROM dbc.IndicesV i
JOIN dbc.IndicesX x ON i.DatabaseId = x.DatabaseId
    AND i.TableId = x.TableId
JOIN dbc.IndexColumns ic ON x.DatabaseId = ic.DatabaseId
    AND x.IndexId = ic.IndexId
JOIN dbc.ColumnsV c ON ic.DatabaseId = c.DatabaseId
    AND ic.TableId = c.TableId
    AND ic.ColumnId = c.ColumnId
WHERE i.TableName = :@table_name
    AND i.IndexType = 'K'
ORDER BY ic.ColumnPosition;

-- Construct the dynamic SQL query
SET @sql_query = 'SELECT
  ' || @primary_key_columns || ',
  COUNT(*) AS total_rows,
  COUNT(DISTINCT ' || @primary_key_columns || ') AS distinct_values,
  (COUNT(*) - COUNT(DISTINCT ' || @primary_key_columns || ')) AS skewness
FROM ' || @table_name || '
GROUP BY ' || @primary_key_columns || '
HAVING skewness > 0
ORDER BY skewness DESC;';

-- Execute the dynamic SQL query
EXECUTE IMMEDIATE :@sql_query;
