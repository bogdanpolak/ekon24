unit Test.DataModuleOrders;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  {}
  DataModule.Connection,
  DataModule.Orders,
  ItemRecord;

{$M+}

type
  TFakeOrder = record
    OrderId: Integer;
    CustomerId: string;
    Products: TArray<Integer>;
  end;

  TVariantArray = TArray<Variant>;

  [TestFixture]
  TestCalculateOrderTotalValue = class
  private
    dmOrders: TDataModuleOrders;
    procedure RemoveFakeOrder(const fakeOrder: TFakeOrder);
    function WithOrder(const aLevel: string;
      const aItems: TArray<TVariantArray>): TFakeOrder;
  public
    [Setup]
    procedure TestSetup;
    [Teardown]
    procedure TestTeardown;
  published
    procedure OrderId_1;
    procedure OneNotDeductableItem;
  end;

implementation

function TestCalculateOrderTotalValue.WithOrder(const aLevel: string;
  const aItems: TArray<TVariantArray>): TFakeOrder;
var
  itemRecords: TArray<TItemRecord>;
  i: Integer;
  itemsCount: Integer;
begin
  DataModuleConnection.GetConnection().StartTransaction;
  Result.CustomerId := 'testuserid-' + Format('%.5d', [Random(100000)]);
  dmOrders.AddCustomer(Result.CustomerId, 'Firma01', aLevel);
  itemsCount := Length(aItems);
  SetLength(Result.Products, itemsCount);
  for i := 0 to itemsCount - 1 do
    Result.Products[i] := dmOrders.AddProduct(Format('test-product-%.2d',
      [i + 1]), aItems[i, 2]);
  SetLength(itemRecords, itemsCount);
  for i := 0 to itemsCount - 1 do
    itemRecords[i] := TItemRecord.Create(Result.Products[i], aItems[i, 0],
      aItems[i, 1]);
  Result.OrderId := dmOrders.AddOrder(Result.CustomerId,
    EncodeDate(2020, 10, 1 + Random(31)), itemRecords);
  DataModuleConnection.GetConnection().Commit;
end;

procedure TestCalculateOrderTotalValue.RemoveFakeOrder(const fakeOrder: TFakeOrder);
var
  i: Integer;
begin
  DataModuleConnection.GetConnection().StartTransaction;
  dmOrders.RemoveOrder(fakeOrder.OrderId);
  for i := 0 to High(fakeOrder.Products) do
    dmOrders.RemoveProduct(fakeOrder.Products[i]);
  dmOrders.RemoveCustomer(fakeOrder.CustomerId);
  DataModuleConnection.GetConnection().Commit;
end;

const
  Deductable = true;

procedure TestCalculateOrderTotalValue.TestSetup;
begin
  dmOrders := TDataModuleOrders.Create(DataModuleConnection.GetConnection());
end;

procedure TestCalculateOrderTotalValue.TestTeardown;
begin
  dmOrders.Free;
end;

// ------------------------------------------------------------------------
// Integration tests
// ------------------------------------------------------------------------

procedure TestCalculateOrderTotalValue.OneNotDeductableItem;
var
  CustomerId: string;
  fakeOrder: TFakeOrder;
  actual: Currency;
begin
  fakeOrder := WithOrder('silver',[[1000.00, 2, not Deductable]]);
  actual := dmOrders.CalculateOrderTotalValue(fakeOrder.OrderId);
  RemoveFakeOrder(fakeOrder);
  Assert.AreEqual(Currency(2000.00), actual, 0.0001);
end;

procedure TestCalculateOrderTotalValue.OrderId_1;
var
  actual: Currency;
  ProductId: Integer;
begin
  actual := dmOrders.CalculateOrderTotalValue(1);
  Assert.AreEqual(Currency(2371.60), actual, 0.0001);
end;

initialization

TDUnitX.RegisterTestFixture(TestCalculateOrderTotalValue);

finalization

end.
