unit main;

interface

uses
  System.Classes,
  System.SysUtils,

  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef;

type
  TDatabaseGenerator = class
  public const
    ConnectionName = 'SQLite_Ekon24';
    DatabaseFileName = 'ekon24.sdb';
    DatabaseFolder = '..\database';
  private
    fDatabaseFullPath: string;
    procedure AppendRows(aConnection: TFDConnection; const aTableName: string;
      const aRecordArray: TArray < TArray < Variant >> );
    procedure CreateConnectionDefinitionIfNotExist();
    procedure DeleteExistingDatabase;
    function OpenConnection(aOwner: TComponent): TFDConnection;
    procedure CreateTables(conn: TFDConnection);
    procedure InsertData(aConnection: TFDConnection);
  public
    constructor Create;
    class procedure Run(); static;
  end;

implementation

uses
  Data.DB,
  System.Variants,
  System.IOUtils,
  WinAPI.Windows;

function PathCanonicalize(lpszDst: PChar; lpszSrc: PChar): LongBool; stdcall;
  external 'shlwapi.dll' name 'PathCanonicalizeW';

function CanonicalizePath(const aPath: string): string;
var
  Dst: array [0 .. MAX_PATH - 1] of char;
begin
  PathCanonicalize(@Dst[0], PChar(aPath));
  Result := Dst;
end;

constructor TDatabaseGenerator.Create;
var
  exePath: string;
  folderPath: string;
  databasePath: string;
begin
  exePath := ExtractFilePath(ParamStr(0));
  folderPath := TPath.Combine(exePath,DatabaseFolder);
  databasePath := TPath.Combine(folderPath, DatabaseFileName);
  fDatabaseFullPath := CanonicalizePath(databasePath);
end;

procedure TDatabaseGenerator.AppendRows(aConnection: TFDConnection;
  const aTableName: string; const aRecordArray: TArray < TArray < Variant >> );
var
  idxRow: integer;
  idxField: integer;
  fdtable: TFDTable;
begin
  fdtable := TFDTable.Create(aConnection.Owner);
  fdtable.Connection := aConnection;
  fdtable.TableName := aTableName;
  fdtable.Open();
  for idxRow := 0 to High(aRecordArray) do
  begin
    fdtable.Append;
    for idxField := 0 to High(aRecordArray[idxRow]) do
    begin
      try
        fdtable.Fields[idxField].Value := aRecordArray[idxRow][idxField];
      except
        on E: EDatabaseError do
        begin
          E.Message := E.Message + Format(' (Row nr:%d, Index of field:%d)',
            [idxRow + 1, idxField]);
          raise;
        end
      end;
    end;
    try
      fdtable.Post;
    except
      on E: EDatabaseError do
      begin
        E.Message := E.Message + Format(' (Row nr:%d)', [idxRow + 1]);
        raise;
      end
    end;
  end;
  fdtable.Close;
end;

procedure TDatabaseGenerator.CreateConnectionDefinitionIfNotExist();
var
  Def: IFDStanConnectionDef;
  oDef: IFDStanConnectionDef;
  oParams: TFDPhysSQLiteConnectionDefParams;
begin
  Def := FDManager.ConnectionDefs.FindConnectionDef(ConnectionName);
  if Def = nil then
  begin
    oDef := FDManager.ConnectionDefs.AddConnectionDef;
    oDef.Name := ConnectionName;
    oParams := TFDPhysSQLiteConnectionDefParams(oDef.Params);
    oParams.DriverID := 'SQLite';
    oParams.Database := fDatabaseFullPath;
    oParams.OpenMode := omCreateUTF8;
    oParams.LockingMode := lmNormal;
    oDef.MarkPersistent;
    oDef.Apply;
  end;
end;

procedure TDatabaseGenerator.DeleteExistingDatabase();
begin
  if FileExists(fDatabaseFullPath) then
    System.SysUtils.DeleteFile(fDatabaseFullPath);
end;

function TDatabaseGenerator.OpenConnection(aOwner: TComponent): TFDConnection;
begin
  if not DirectoryExists(DatabaseFolder) then
    CreateDir(DatabaseFolder);
  Result := TFDConnection.Create(nil);
  Result.ConnectionDefName := ConnectionName;
  Result.Open();
end;

const
  CreateOrders = 'CREATE TABLE IF NOT EXISTS Orders (' +
  { } ' OrderId INTEGER PRIMARY KEY NOT NULL,' +
  { } ' CustomerId TEXT(20) NOT NULL,' +
  { } ' GrantedDiscount INTEGER NOT NULL,' +
  { } ' OrderDate TEXT(40) NOT NULL)';

  CreateItems = 'CREATE TABLE IF NOT EXISTS Items (' +
  { } ' OrderId INTEGER NOT NULL,' +
  { } ' ProductId INTEGER NOT NULL,' +
  { } ' UnitPrice DECIMAL(19, 4) NOT NULL,' +
  { } ' DeductedPrice DECIMAL(19, 4),' +
  { } ' Units INTEGER NOT NULL)';

  CreateThresholds = 'CREATE TABLE IF NOT EXISTS Thresholds (' +
  { } ' Level TEXT(10) NOT NULL,' +
  { } ' LimitBottom DECIMAL(19, 4) NOT NULL,' +
  { } ' Discount INTEGER NOT NULL)';

  CreateCustomers = 'CREATE TABLE IF NOT EXISTS Customers (' +
  { } ' CustomerId TEXT(20) PRIMARY KEY NOT NULL,' +
  { } ' Name TEXT(50) NOT NULL,' +
  { } ' Level TEXT(10) NOT NULL)';

  CreateProducts = 'CREATE TABLE IF NOT EXISTS Products (' +
  { } ' ProductId INTEGER PRIMARY KEY NOT NULL,' +
  { } ' Name TEXT(50) NOT NULL,' +
  { } ' AllowDeduction INTEGER NOT NULL)';

procedure TDatabaseGenerator.CreateTables(conn: TFDConnection);
begin
  conn.StartTransaction;
  conn.ExecSQL(CreateOrders);
  conn.ExecSQL(CreateItems);
  conn.ExecSQL(CreateThresholds);
  conn.ExecSQL(CreateCustomers);
  conn.ExecSQL(CreateProducts);
  conn.Commit;
end;

procedure TDatabaseGenerator.InsertData(aConnection: TFDConnection);
begin
  aConnection.StartTransaction;
  // ----------------------------------------------------
  AppendRows(aConnection, 'Orders', [
    { } [1, 'PL3815422868', 0, EncodeDate(2020, 08, 02)],
    { } [2, 'DE136695976', 0, EncodeDate(2020, 08, 05)],
    { } [5, 'PL1124267312', 0, EncodeDate(2020, 08, 08)],
    { } [6, 'DE301204526', 0, EncodeDate(2020, 08, 09)],
    { } [7, 'PL5352679105', 0, EncodeDate(2020, 08, 15)]]);
  // ----------------------------------------------------
  AppendRows(aConnection, 'Items', [
    { } [1, 25, 100.00, Null(), 20],
    { } [1, 2, 90.00, Null(), 1],
    { } [1, 99, 120.00, Null(), 4],
    { } [2, 21, 100.00, Null(), 12],
    { } [2, 31, 150.00, Null(), 3],
    { } [5, 22, 20.00, Null(), 50],
    { } [5, 19, 170.00, Null(), 5],
    { } [5, 9, 25.00, Null(), 32],
    { } [5, 5, 140.00, Null(), 10],
    { } [6, 23, 15.00, Null(), 10],
    { } [6, 18, 145.00, Null(), 2],
    { } [6, 8, 190.00, Null(), 1],
    { } [6, 11, 200.00, Null(), 2],
    { } [7, 12, 35.00, Null(), 10],
    { } [7, 13, 90.00, Null(), 2],
    { } [7, 7, 19.00, Null(), 5],
    { } [7, 6, 110.00, Null(), 4]]);
  // ----------------------------------------------------
  AppendRows(aConnection, 'Thresholds', [
    { } ['standard', 1200.00, 2],
    { } ['standard', 2000.00, 3],
    { } ['standard', 3000.00, 4],
    { } ['silver',  800.00, 2],
    { } ['silver', 1500.00, 3],
    { } ['silver', 2000.00, 5],
    { } ['gold',  700.00, 2],
    { } ['gold', 1000.00, 3],
    { } ['gold', 1400.00, 5],
    { } ['gold', 1900.00, 8]]);
  // ----------------------------------------------------
  AppendRows(aConnection, 'Customers', [
    { } ['PL1124267312', 'Modivo Sp. z o.o.', 'standard'],
    { } ['PL5352679105', 'Fundacja Michalak', 'silver'],
    { } ['PL3815422868', 'Wieczorek sp. z o.o.', 'gold'],
    { } ['DE136695976', 'Haag GmbH', 'standard'],
    { } ['DE301204526', 'Stoll Feldmann AG', 'gold']]);
  // ----------------------------------------------------
  AppendRows(aConnection, 'Products', [
    { } [2, 'transport service', 0],
    { } [5, 'orange sweater', 1],
    { } [6, 'navy wallet', 1],
    { } [7, 'blue shawl', 1],
    { } [8, 'boy outdoor-vest', 1],
    { } [9, 'red T-shirt with thunder ', 0],
    { } [11, 'brown boots', 1],
    { } [12, 'green cap', 0],
    { } [13, 'bussines watch', 0],
    { } [18, 'originals tracksuit', 1],
    { } [19, 'winter boy coat', 1],
    { } [21, 'violet jeans trousers', 1],
    { } [22, 'green socks pack', 0],
    { } [23, 'sport shorts', 0],
    { } [25, 'blue jeans', 1],
    { } [31, 'men''s jacket', 1],
    { } [99, 'sport shoes', 1]]);
  // ----------------------------------------------------
  aConnection.Commit;
end;

class procedure TDatabaseGenerator.Run();
var
  dbgen: TDatabaseGenerator;
  Owner: TComponent;
  aConnection: TFDConnection;
begin
  dbgen := TDatabaseGenerator.Create();
  Owner := TComponent.Create(nil);
  try
    dbgen.CreateConnectionDefinitionIfNotExist();
    dbgen.DeleteExistingDatabase();
    aConnection := dbgen.OpenConnection(Owner);
    dbgen.CreateTables(aConnection);
    dbgen.InsertData(aConnection);
  finally
    Owner.Free;
    dbgen.Free;
  end;
end;

end.
