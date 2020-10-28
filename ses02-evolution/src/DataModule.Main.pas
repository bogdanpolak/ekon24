unit DataModule.Main;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.ConsoleUI.Wait, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FireDAC.VCLUI.Wait;

type
  TDataModuleMain = class(TDataModule)
    FDConnection1: TFDConnection;
    fdqThresholds: TFDQuery;
    fdqOrderItems: TFDQuery;
  private
  public
    function GetCustomerLevel(const aCustomerId: String): String;
    procedure UpdateOrderDiscount(const aOrderId: Integer;
      aGrantedDiscount: Integer);
  end;

  ERepositoryError = class(Exception);

var
  DataModuleMain: TDataModuleMain;

implementation

uses
  System.Variants;

{%CLASSGROUP 'System.Classes.TPersistent'}
{$R *.dfm}

function TDataModuleMain.GetCustomerLevel(const aCustomerId: String): String;
var
  level: Variant;
begin
  level := FDConnection1.ExecSQLScalar
    ('SELECT Level FROM customers WHERE CustomerId = :customerid',
    [aCustomerId]);
  if level = Null() then
    raise ERepositoryError.Create(Format('Customer with id: %s is not exists',
      [aCustomerId]));
  Result := level;
end;

procedure TDataModuleMain.UpdateOrderDiscount(const aOrderId: Integer;
  aGrantedDiscount: Integer);
begin
  FDConnection1.ExecSQL
    ('UPDATE Orders SET GrantedDiscount = :Discount  WHERE OrderId = :OrderId',
    [aGrantedDiscount, aOrderId]);
end;

end.
