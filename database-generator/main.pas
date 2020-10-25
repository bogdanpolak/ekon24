unit main;

interface

uses
  System.Classes,
  System.SysUtils,

  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Stan.Intf,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef;

type
  TDatabaseGenerator = class
  public const
    ConnectionName =  'SQLite_Ekon24';
  public
    class procedure Run(); static;
  end;

implementation

class procedure TDatabaseGenerator.Run();
var
  def: IFDStanConnectionDef;
  oDef: IFDStanConnectionDef;
  oParams: TFDPhysSQLiteConnectionDefParams;
begin
  def := FDManager.ConnectionDefs.ConnectionDefByName(ConnectionName);
  if def = nil then
  begin
    // FDManager.ConnectionDefs.AddConnectionDef;
    oDef := FDManager.ConnectionDefs.AddConnectionDef;
    oDef.Name := ConnectionName;
    oParams := TFDPhysSQLiteConnectionDefParams(oDef.Params);
    oParams.DriverID := 'SQLite';
    oParams.Database := '..\database\ekon24.sdb';
    oParams.OpenMode := omCreateUTF8;
    oDef.MarkPersistent;
    oDef.Apply;
  end;
end;

end.
