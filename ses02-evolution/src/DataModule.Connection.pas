unit DataModule.Connection;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Variants,
  FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.ConsoleUI.Wait, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FireDAC.VCLUI.Wait;

type
  TDataModuleConnection = class(TComponent)
  private
    fConnection: TFDConnection;
  public
    function GetConnection: TFDConnection;
    function OpenConnection: TFDConnection;
    constructor Create(aOwner: TComponent); override;
  end;

var
  DataModuleConnection: TDataModuleConnection;

implementation

constructor TDataModuleConnection.Create(aOwner: TComponent);
begin
  inherited;
  fConnection := TFDConnection.Create(self);
  fConnection.ConnectionDefName := 'SQLite_Ekon24';
end;

function TDataModuleConnection.GetConnection: TFDConnection;
begin
  Result := fConnection;
end;

function TDataModuleConnection.OpenConnection: TFDConnection;
begin
  fConnection.Open();
  Result := fConnection;
end;

end.
