unit DataModule.Orders;

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
  TDataModuleOrders = class(TComponent)
  private
    function FindDiscount(const aLevel: string; aTotalValue: Currency): Integer;
  public
    FDConnection1: TFDConnection;
    fdqThresholds: TFDQuery;
    fdqOrderItems: TFDQuery;
    constructor Create(aOwner: TComponent); override;
    function GetCustomerLevel(const aCustomerId: String): String;
    procedure UpdateOrderDiscount(const aOrderId: Integer;
      aGrantedDiscount: Integer);
    function OrderTotalValue(aOrderId: Integer): Currency;
  end;

  ERepositoryError = class(Exception);

implementation

function BuildFDQuery(const connection: TFDConnection; const aSql: string)
  : TFDQuery;
begin
  Result := TFDQuery.Create(connection);
  Result.connection := connection;
  Result.SQL.Text := aSql;
end;

constructor TDataModuleOrders.Create(aOwner: TComponent);
begin
  inherited;
  FDConnection1 := TFDConnection.Create(self);
  FDConnection1.ConnectionDefName := 'SQLite_Ekon24';
  fdqThresholds := BuildFDQuery(FDConnection1,
    'SELECT Level, LimitBottom, Discount FROM Thresholds' +
    ' ORDER BY Level, LimitBottom');
  fdqOrderItems := BuildFDQuery(FDConnection1,
    'SELECT' +
    ' Items.ProductId, Items.UnitPrice, Items.DeductedPrice, Items.Units,' +
    ' Orders.CustomerId, Orders.OrderDate,' +
    ' Products.Name, Products.AllowDeduction' + ' FROM Items' +
    ' INNER JOIN Orders ON Orders.OrderId = Items.OrderId' +
    ' INNER JOIN Products ON Items.ProductId = Products.ProductId' +
    ' WHERE Orders.OrderId = :OrderId');
end;

function TDataModuleOrders.GetCustomerLevel(const aCustomerId: String): String;
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

procedure TDataModuleOrders.UpdateOrderDiscount(const aOrderId: Integer;
  aGrantedDiscount: Integer);
begin
  FDConnection1.ExecSQL
    ('UPDATE Orders SET GrantedDiscount = :Discount  WHERE OrderId = :OrderId',
    [aGrantedDiscount, aOrderId]);
end;

function TDataModuleOrders.FindDiscount(const aLevel: string;
  aTotalValue: Currency): Integer;
  function InRange(aValue: Currency; aLimit1: Currency;
    aLimit2: Currency): boolean;
  begin
    Result := (aLimit1 <= aValue) and (aValue < aLimit2);
  end;

var
  level: string;
  limit1: Currency;
  limit2: Currency;
begin
  fdqThresholds.Open();
  fdqThresholds.First;
  fdqThresholds.Locate('Level', aLevel);
  limit1 := 0;
  Result := 0;
  while not fdqThresholds.Eof do
  begin
    level := fdqThresholds.FieldByName('Level').AsString;
    limit2 := fdqThresholds.FieldByName('LimitBottom').AsCurrency;
    if (level <> aLevel) or InRange(aTotalValue, limit1, limit2) then
      Exit;
    Result := fdqThresholds.FieldByName('Discount').AsInteger;
    limit1 := limit2;
    fdqThresholds.Next;
  end;
end;

function RoundUnitPrice(price: Currency): Currency;
begin
  Result := Round(Int(price * 100))/100;
end;

function TDataModuleOrders.OrderTotalValue(aOrderId: Integer): Currency;
var
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
  fdqOrderItems.ParamByName('OrderId').AsInteger := aOrderId;
  fdqOrderItems.Open();
  if fdqOrderItems.Eof then
    Exit(0);
  customerId := fdqOrderItems.FieldByName('CustomerId').AsString;
  level := GetCustomerLevel(customerId);
  totalBeforeDeduction := 0;
  while not fdqOrderItems.Eof do
  begin
    unitprice := fdqOrderItems.FieldByName('UnitPrice').AsCurrency;
    units := fdqOrderItems.FieldByName('Units').AsInteger;
    totalBeforeDeduction := totalBeforeDeduction + unitprice * units;
    fdqOrderItems.Next;
  end;
  discount := FindDiscount(level, totalBeforeDeduction);
  totalAfterDeduction := 0;
  fdqOrderItems.First;
  FDConnection1.StartTransaction;
  UpdateOrderDiscount(aOrderId, discount);
  while not fdqOrderItems.Eof do
  begin
    unitprice := fdqOrderItems.FieldByName('UnitPrice').AsCurrency;
    units := fdqOrderItems.FieldByName('Units').AsInteger;
    isDeductable := (fdqOrderItems.FieldByName('AllowDeduction').AsInteger > 0);
    if isDeductable then
      deductedPrice := RoundUnitPrice(unitprice * ((100 - discount) / 100))
    else
      deductedPrice := unitprice;
    totalAfterDeduction := totalAfterDeduction + deductedPrice * units;
    fdqOrderItems.Edit;
    fdqOrderItems.FieldByName('DeductedPrice').AsCurrency := deductedPrice;
    fdqOrderItems.Post;
    fdqOrderItems.Next;
  end;
  FDConnection1.Commit;
  Result := totalAfterDeduction;
end;

end.
