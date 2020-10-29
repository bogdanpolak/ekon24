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
  TDataModuleOrders = class
  private
    fConnection: TFDConnection;
    fOwner: TComponent;
    function BuildFDQuery(const aSql: string): TFDQuery;
  public
    fdqThresholds: TFDQuery;
    fdqOrderItems: TFDQuery;
    constructor Create(aConnection: TFDConnection);
    destructor Destroy; override;
    function GetCustomerLevel(const aCustomerId: String): String;
    procedure UpdateOrderDiscount(const aOrderId: Integer;
      aGrantedDiscount: Integer);
    function CalculateOrderTotalValue(aOrderId: Integer): Currency;
  end;

  ERepositoryError = class(Exception);

implementation

function TDataModuleOrders.BuildFDQuery(const aSql: string): TFDQuery;
begin
  Result := TFDQuery.Create(fOwner);
  Result.connection := fConnection;
  Result.SQL.Text := aSql;
end;

constructor TDataModuleOrders.Create(aConnection: TFDConnection);
begin
  fConnection := aConnection;
  fOwner := TComponent.Create(nil);
  fdqThresholds := BuildFDQuery
    ('SELECT Level, LimitBottom, Discount FROM Thresholds' +
    ' ORDER BY Level, LimitBottom');
  fdqOrderItems := BuildFDQuery
    ('SELECT' +
    ' Items.ProductId, Items.UnitPrice, Items.DeductedPrice, Items.Units,' +
    ' Orders.CustomerId, Orders.OrderDate,' +
    ' Products.Name, Products.AllowDeduction' + ' FROM Items' +
    ' INNER JOIN Orders ON Orders.OrderId = Items.OrderId' +
    ' INNER JOIN Products ON Items.ProductId = Products.ProductId' +
    ' WHERE Orders.OrderId = :OrderId');
end;

destructor TDataModuleOrders.Destroy;
begin
  fOwner.Free;
  inherited;
end;

function TDataModuleOrders.GetCustomerLevel(const aCustomerId: String): String;
var
  level: Variant;
begin
  level := fConnection.ExecSQLScalar
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
  fConnection.ExecSQL
    ('UPDATE Orders SET GrantedDiscount = :Discount  WHERE OrderId = :OrderId',
    [aGrantedDiscount, aOrderId]);
end;

type
  TCurrencyRecordHelper = record helper for Currency
    function IsInRange(aLimit1: Currency; aLimit2: Currency): boolean;
  end;

function TCurrencyRecordHelper.IsInRange(aLimit1: Currency;
  aLimit2: Currency): boolean;
begin
  Result := (aLimit1 <= self) and (self < aLimit2);
end;

function RoundUnitPrice(price: Currency): Currency;
begin
  Result := Round(Int(price * 100)) / 100;
end;

function TDataModuleOrders.CalculateOrderTotalValue(aOrderId: Integer)
  : Currency;
var
  customerId: string;
  level: string;
  unitprice: Currency;
  units: Integer;
  totalBeforeDeduction: Currency;
  limit1: Currency;
  limit2: Currency;
  discount: Integer;
  totalAfterDeduction: Currency;
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
  fdqThresholds.Open();
  fdqThresholds.First;
  fdqThresholds.Locate('Level', level);
  limit1 := 0;
  discount := 0;
  while not fdqThresholds.Eof do
  begin
    limit2 := fdqThresholds.FieldByName('LimitBottom').AsCurrency;
    if (level <> fdqThresholds.FieldByName('Level').AsString) or
      (totalBeforeDeduction.IsInRange(limit1, limit2)) then
      break;
    discount := fdqThresholds.FieldByName('Discount').AsInteger;
    limit1 := limit2;
    fdqThresholds.Next;
  end;
  totalAfterDeduction := 0;
  fdqOrderItems.First;
  fConnection.StartTransaction;
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
  fConnection.Commit;
  Result := totalAfterDeduction;
end;

end.
