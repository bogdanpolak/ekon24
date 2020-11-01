unit DataModule.Orders;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Variants,
  System.Math,
  FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.ConsoleUI.Wait, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FireDAC.VCLUI.Wait,
  {}
  ItemRecord;

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
    function AddProduct(const aName: string; aAllowDeduction: boolean): integer;
    procedure AddCustomer(const aCustomerId: string; const aName: string;
      const aLevel: string);
    function AddOrder(const aCustomerId: string; aOrderDate: TDate;
      Items: TArray<TItemRecord>): integer;
    procedure RemoveProduct(aProductId: integer);
    procedure RemoveOrder(const aOrderId: integer);
    procedure RemoveCustomer(const aCustomerId: string);
    function GetCustomerLevel(const aCustomerId: String): String;
    procedure UpdateOrderDiscount(const aOrderId: integer;
      aGrantedDiscount: integer);
    function CalculateOrderTotalValue(aOrderId: integer): Currency;
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

function TDataModuleOrders.AddProduct(const aName: string;
  aAllowDeduction: boolean): integer;
begin
  fConnection.ExecSQL
    ('INSERT INTO Products (Name,AllowDeduction) VAlUES (:name, :allow)',
    [aName, IfThen(aAllowDeduction, 1, 0)]);
  Result := fConnection.GetLastAutoGenValue('');
end;

procedure TDataModuleOrders.AddCustomer(const aCustomerId: string;
  const aName: string; const aLevel: string);
begin
  fConnection.ExecSQL('INSERT INTO Customers (CustomerId,Name,Level)' +
    ' VALUES (:customerid, :name, :level)', [aCustomerId, aName, aLevel]);
end;

function TDataModuleOrders.AddOrder(const aCustomerId: string;
  aOrderDate: TDate; Items: TArray<TItemRecord>): integer;
var
  i: integer;
begin
  fConnection.StartTransaction;
  fConnection.ExecSQL
    ('INSERT INTO Orders (CustomerId, GrantedDiscount, OrderDate)' +
    ' VALUES (:customerid, 0, :orderdate)', [aCustomerId, aOrderDate]);
  Result := fConnection.GetLastAutoGenValue('');
  for i := 0 to High(Items) do
    fConnection.ExecSQL
      ('INSERT INTO Items (OrderId, ProductId, UnitPrice, Units)' +
      ' VALUES (:orderid, :productid, :unitprice, :units)',
      [Result, Items[i].ProductId, Items[i].UnitPrice, Items[i].Units]);
  fConnection.Commit;
end;

procedure TDataModuleOrders.RemoveProduct(aProductId: integer);
begin
  fConnection.ExecSQL('DELETE FROM Products WHERE ProductId = :productid',
    [aProductId]);
end;

procedure TDataModuleOrders.RemoveCustomer(const aCustomerId: string);
begin
  fConnection.ExecSQL('DELETE FROM Customers WHERE CustomerId = :customerid',
    [aCustomerId]);
end;

procedure TDataModuleOrders.RemoveOrder(const aOrderId: integer);
begin
  fConnection.StartTransaction;
  fConnection.ExecSQL('DELETE FROM Items WHERE OrderId = :orderid', [aOrderId]);
  fConnection.ExecSQL('DELETE FROM Orders WHERE OrderId = :orderid',
    [aOrderId]);
  fConnection.Commit;
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

procedure TDataModuleOrders.UpdateOrderDiscount(const aOrderId: integer;
  aGrantedDiscount: integer);
begin
  fConnection.ExecSQL
    ('UPDATE Orders SET GrantedDiscount = :Discount  WHERE OrderId = :OrderId',
    [aGrantedDiscount, aOrderId]);
end;

function RoundUnitPrice(price: Currency): Currency;
begin
  Result := Round(Int(price * 100)) / 100;
end;

function TDataModuleOrders.CalculateOrderTotalValue(aOrderId: integer)
  : Currency;
var
  customerId: string;
  level: string;
  UnitPrice: Currency;
  Units: integer;
  totalBeforeDeduction: Currency;
  limit1: Currency;
  limit2: Currency;
  discount: integer;
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
    UnitPrice := fdqOrderItems.FieldByName('UnitPrice').AsCurrency;
    Units := fdqOrderItems.FieldByName('Units').AsInteger;
    totalBeforeDeduction := totalBeforeDeduction + UnitPrice * Units;
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
      ((limit1 <= totalBeforeDeduction) and (totalBeforeDeduction < limit2)) then
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
    UnitPrice := fdqOrderItems.FieldByName('UnitPrice').AsCurrency;
    Units := fdqOrderItems.FieldByName('Units').AsInteger;
    isDeductable := (fdqOrderItems.FieldByName('AllowDeduction').AsInteger > 0);
    if isDeductable then
      deductedPrice := RoundUnitPrice(UnitPrice * ((100 - discount) / 100))
    else
      deductedPrice := UnitPrice;
    totalAfterDeduction := totalAfterDeduction + deductedPrice * Units;
    fdqOrderItems.Edit;
    fdqOrderItems.FieldByName('DeductedPrice').AsCurrency := deductedPrice;
    fdqOrderItems.Post;
    fdqOrderItems.Next;
  end;
  fConnection.Commit;
  Result := totalAfterDeduction;
end;

end.
