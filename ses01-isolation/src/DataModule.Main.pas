unit DataModule.Main;

interface

uses
  System.SysUtils,
  System.Classes,
  FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.ConsoleUI.Wait, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FireDAC.VCLUI.Wait;

type
  TMainDataModule = class(TComponent)
    FDConnection1: TFDConnection;
    fdqThresholds: TFDQuery;
    fdqCustomers: TFDQuery;
  private
  public
    constructor Create(aOwner: TComponent); override;
    function GetCustomerLevel(const aCustomerId: String): String;
    function CalculateDiscount(const aCustomerId: String;
      aTotalValue: Currency): Integer;
  end;

implementation

uses
  DiscountCalculator;

function BuildQuery(const connection: TFDConnection; const aSql: string)
  : TFDQuery;
begin
  Result := TFDQuery.Create(connection);
  Result.connection := connection;
  Result.SQL.Text := aSql;
end;

constructor TMainDataModule.Create(aOwner: TComponent);
begin
  inherited;
  FDConnection1 := TFDConnection.Create(self);
  FDConnection1.ConnectionDefName := 'SQLIte_Ekon24';
  FDConnection1.LoginPrompt := False;
  fdqThresholds := BuildQuery(FDConnection1, 'SELECT * FROM Thresholds');
end;

function TMainDataModule.GetCustomerLevel(const aCustomerId: String): String;
begin
  Result := FDConnection1.ExecSQLScalar
    ('SELECT Level FROM Customers WHERE CustomerID = :customerID',
    [aCustomerId])
end;

function InRange(aValue: Currency; aLimit1: Currency;
  aLimit2: Currency): boolean;
begin
  Result := (aLimit1 <= aValue) and (aValue < aLimit2);
end;

function TMainDataModule.CalculateDiscount(const aCustomerId: String;
  aTotalValue: Currency): Integer;
var
  level: String;
  limit1: Currency;
  limit2: Currency;
begin
  level := GetCustomerLevel(aCustomerId);
  fdqThresholds.Open();
  fdqThresholds.Locate('Level', level);
  Result := 0;
  limit1 := 0;
  while not(fdqThresholds.Eof) and
    (fdqThresholds.FieldByName('Level').AsString = level) do
  begin
    limit2 := fdqThresholds.FieldByName('LimitBottom').AsCurrency;
    if InRange(aTotalValue, limit1, limit2) then
      Exit;
    Result := fdqThresholds.FieldByName('Discount').AsInteger;
    limit1 := limit2;
    fdqThresholds.Next;
  end;
end;

end.
