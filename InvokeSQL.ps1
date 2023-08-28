function InvokeSQL {
    param(
        [string] $dataSource = "Data Source Name",
        [string] $database = "DataBase Name",
        [string] $sqlCommand = $(throw "Please specify a query."),
        [string] $id = "username",
        [string] $pw = "password"
      )

    $connectionString = "Data Source=$dataSource; " +
            #"Integrated Security=SSPI; " +
            "Initial Catalog=$database; " +
            "User ID=$id; Password=$pw"

    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()
    
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    
    $connection.Close()
    $dataSet.Tables
}
