unit Test.DataModuleOrders;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Delphi.Mocks,
  System.Rtti,
  {}
  DataModule.Connection,
  DataModule.Orders,
  ItemRecord, Repository, Domain.DiscountTable;

type
  TFakeOrder = record
    IsCreated: boolean;
    OrderId: Integer;
    CustomerId: string;
    Products: TArray<Integer>;
  end;

  TVariantArray = TArray<Variant>;

{$M+}

type

  [TestFixture]
  TestCalculateOrderTotalValue = class
  private
    fDiscountTableRepositoryMock: TMock<IDiscountTableRepository>;
    fDiscountTableSilver: TDiscountTable;
    dmOrders: TDataModuleOrders;
    fFakeOrder: TFakeOrder;
    procedure CreateFakeOrderInDatabase(const aLevel: string;
      const aItems: TArray<TVariantArray>);
    procedure RemoveFakeOrder;
  public
    [Setup]
    procedure TestSetup;
    [Teardown]
    procedure TestTeardown;
  published
    procedure OneDeductableItem;
    procedure OneNotDeductableItem;
    procedure TwoItems_OneDeductable;
    procedure ThreeItems_OneDeductable;
  end;

implementation

procedure TestCalculateOrderTotalValue.TestSetup;
begin
  fDiscountTableRepositoryMock := TMock<IDiscountTableRepository>.Create;
  fDiscountTableSilver := TDiscountTable.Create('silver');
  fDiscountTableRepositoryMock.Setup.WillReturn
    (TValue.From<TDiscountTable>(fDiscountTableSilver)).When.Get('silver');
  dmOrders := TDataModuleOrders.Create(DataModuleConnection.GetConnection(),
    fDiscountTableRepositoryMock);
end;

procedure TestCalculateOrderTotalValue.TestTeardown;
begin
  dmOrders.Free;
  RemoveFakeOrder;
end;

// ------------------------------------------------------------------------

procedure TestCalculateOrderTotalValue.CreateFakeOrderInDatabase
  (const aLevel: string; const aItems: TArray<TVariantArray>);
var
  itemRecords: TArray<TItemRecord>;
  i: Integer;
  itemsCount: Integer;
begin
  DataModuleConnection.GetConnection().StartTransaction;
  fFakeOrder.CustomerId := 'testuserid-' + Format('%.5d', [Random(100000)]);
  dmOrders.AddCustomer(fFakeOrder.CustomerId, 'Firma01', aLevel);
  itemsCount := Length(aItems);
  SetLength(fFakeOrder.Products, itemsCount);
  for i := 0 to itemsCount - 1 do
    fFakeOrder.Products[i] := dmOrders.AddProduct(Format('test-product-%.2d',
      [i + 1]), aItems[i, 2]);
  SetLength(itemRecords, itemsCount);
  for i := 0 to itemsCount - 1 do
    itemRecords[i] := TItemRecord.Create(fFakeOrder.Products[i], aItems[i, 0],
      aItems[i, 1]);
  fFakeOrder.OrderId := dmOrders.AddOrder(fFakeOrder.CustomerId,
    EncodeDate(2020, 10, 1 + Random(31)), itemRecords);
  DataModuleConnection.GetConnection().Commit;
  fFakeOrder.IsCreated := True;
end;

procedure TestCalculateOrderTotalValue.RemoveFakeOrder();
var
  i: Integer;
begin
  if fFakeOrder.IsCreated and (fFakeOrder.OrderId > 0) then
  begin
    DataModuleConnection.GetConnection().StartTransaction;
    dmOrders.RemoveOrder(fFakeOrder.OrderId);
    for i := 0 to High(fFakeOrder.Products) do
      dmOrders.RemoveProduct(fFakeOrder.Products[i]);
    dmOrders.RemoveCustomer(fFakeOrder.CustomerId);
    DataModuleConnection.GetConnection().Commit;
    fFakeOrder.IsCreated := False;
    fFakeOrder.OrderId := 0;
    fFakeOrder.Products := nil;
    fFakeOrder.CustomerId := '';
  end;
end;

// ------------------------------------------------------------------------
// Integration tests
// ------------------------------------------------------------------------

const
  Deductable = True;

procedure TestCalculateOrderTotalValue.OneNotDeductableItem;
var
  actual: Currency;
begin
  fDiscountTableSilver
  { } .Add(0, 800, 0)
  { } .Add(800, 1500, 2)
  { } .Add(1500, 2000, 3)
  { } .Build(5);
  CreateFakeOrderInDatabase('silver', [
    { } [1000.00, 2, not Deductable]]); // 2x 1000 = 2000
  // 2000 => 3% => 2000
  actual := dmOrders.CalculateOrderTotalValue(fFakeOrder.OrderId);
  Assert.AreEqual(Currency(2000.00), actual, 0.0001);
end;

procedure TestCalculateOrderTotalValue.OneDeductableItem;
var
  actual: Currency;
begin
  fDiscountTableSilver
  { } .Add(0, 800, 0)
  { } .Add(800, 1500, 2)
  { } .Add(1500, 2000, 3)
  { } .Build(5);
  CreateFakeOrderInDatabase('silver', [
    { } [600.00, 2, Deductable]]); // 2x 600 = 1200
  // 1200 => 2% => 1200*98% = 1176
  actual := dmOrders.CalculateOrderTotalValue(fFakeOrder.OrderId);
  Assert.AreEqual(Currency(1176.00), actual, 0.0001);
end;

procedure TestCalculateOrderTotalValue.TwoItems_OneDeductable;
var
  actual: Currency;
begin
  fDiscountTableSilver
  { } .Add(0, 800, 0)
  { } .Add(800, 1500, 2)
  { } .Add(1500, 2000, 3)
  { } .Build(5);
  CreateFakeOrderInDatabase('silver', [
    { } [300.00, 2, Deductable], // 2x 300 = 600
    { } [600.00, 1, not Deductable]]); // 600
  // 1200 => 2% => 600*98% + 600 = 1188
  actual := dmOrders.CalculateOrderTotalValue(fFakeOrder.OrderId);
  Assert.AreEqual(Currency(1188.00), actual, 0.0001);
end;

procedure TestCalculateOrderTotalValue.ThreeItems_OneDeductable;
var
  actual: Currency;
begin
  fDiscountTableSilver
  { } .Add(0, 800, 0)
  { } .Add(800, 1500, 2)
  { } .Add(1500, 2000, 3)
  { } .Build(5);
  CreateFakeOrderInDatabase('silver', [
    { } [50.00, 20, Deductable], // 20x 50 = 1000
    { } [100.00, 1, not Deductable], // 100
    { } [15.00, 80, Deductable]]); // 80x 15.00 = 1200
  // 2300 => 5% => 2200*95% + 100 = 2090 + 100 = 2190
  actual := dmOrders.CalculateOrderTotalValue(fFakeOrder.OrderId);
  Assert.AreEqual(Currency(2190.00), actual, 0.0001);
end;

initialization

TDUnitX.RegisterTestFixture(TestCalculateOrderTotalValue);

finalization

end.
