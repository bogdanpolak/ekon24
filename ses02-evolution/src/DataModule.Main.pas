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
    function FindDiscount(const aLevel: string; aTotalValue: Currency): Integer;
  public
    function GetCustomerLevel(const aCustomerId: String): String;
    procedure UpdateOrderDiscount(const aOrderId: Integer;
      aGrantedDiscount: Integer);
    function OrderTotalValue(aOrderId: Integer): Currency;
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

function TDataModuleMain.FindDiscount(const aLevel: string;
  aTotalValue: Currency): Integer;
  function InRange(aValue: Currency; aLimit1: Currency;
    aLimit2: Currency): boolean;
  begin
    Result := (aLimit1 <= aValue) and (aValue < aLimit2);
  end;

var
  DataSet: TFDQuery;
  level: string;
  limit1: Currency;
  limit2: Currency;
begin
  DataSet := DataModuleMain.fdqThresholds;
  DataSet.Open();
  DataSet.First;
  DataSet.Locate('Level', aLevel);
  limit1 := 0;
  Result := 0;
  while not DataSet.Eof do
  begin
    level := DataSet.FieldByName('Level').AsString;
    limit2 := DataSet.FieldByName('LimitBottom').AsCurrency;
    if (level <> aLevel) or InRange(aTotalValue, limit1, limit2) then
      Exit;
    Result := DataSet.FieldByName('Discount').AsInteger;
    limit1 := limit2;
    DataSet.Next;
  end;
end;

function RoundUnitPrice(price: Currency): Currency;
begin
  Result := Round(Int(price * 100))/100;
end;

function TDataModuleMain.OrderTotalValue(aOrderId: Integer): Currency;
var
  DataSet: TFDQuery;
  customerId: string;
  level: string;
  unitprice: Currency;
  units: Integer;
  totalBeforeDeduction: Currency;
  totalAfterDeduction: Currency;
  discount: Integer;
  isDeductable: boolean;
  deductedPrice: Currency;
begin
  DataModuleMain.FDConnection1.Open();
  DataModuleMain.fdqOrderItems.ParamByName('OrderId').AsInteger := aOrderId;
  DataSet := DataModuleMain.fdqOrderItems;
  DataSet.Open();
  if DataSet.Eof then
    Exit(0);
  customerId := DataSet.FieldByName('CustomerId').AsString;
  level := DataModuleMain.GetCustomerLevel(customerId);
  totalBeforeDeduction := 0;
  while not DataSet.Eof do
  begin
    unitprice := DataSet.FieldByName('UnitPrice').AsCurrency;
    units := DataSet.FieldByName('Units').AsInteger;
    totalBeforeDeduction := totalBeforeDeduction + unitprice * units;
    DataSet.Next;
  end;
  discount := FindDiscount(level, totalBeforeDeduction);
  totalAfterDeduction := 0;
  DataSet.First;
  DataModuleMain.FDConnection1.StartTransaction;
  DataModuleMain.UpdateOrderDiscount(aOrderId, discount);
  while not DataSet.Eof do
  begin
    unitprice := DataSet.FieldByName('UnitPrice').AsCurrency;
    units := DataSet.FieldByName('Units').AsInteger;
    isDeductable := (DataSet.FieldByName('AllowDeduction').AsInteger > 0);
    if isDeductable then
      deductedPrice := RoundUnitPrice(unitprice * ((100 - discount) / 100))
    else
      deductedPrice := unitprice;
    totalAfterDeduction := totalAfterDeduction + deductedPrice * units;
    DataSet.Edit;
    DataSet.FieldByName('DeductedPrice').AsCurrency := deductedPrice;
    DataSet.Post;
    DataSet.Next;
  end;
  DataModuleMain.FDConnection1.Commit;
  Result := totalAfterDeduction;
end;

end.
