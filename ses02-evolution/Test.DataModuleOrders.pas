unit Test.DataModuleOrders;

interface

uses
  DUnitX.TestFramework,
  {}
  DataModule.Connection,
  DataModule.Orders;

{$M+}

type

  [TestFixture]
  TTestDMOrders = class
  private
    dmOrders: TDataModuleOrders;
  public
    [Setup]
    procedure TestSetup;
    [Teardown]
    procedure TestTeardown;
  published
    procedure OrderTotalValue_OrderId_1;
  end;

implementation


procedure TTestDMOrders.OrderTotalValue_OrderId_1;
var
  actual: Currency;
begin
  actual := dmOrders.OrderTotalValue(1);
  Assert.AreEqual(Currency(2371.60), actual, 0.0001);
end;

procedure TTestDMOrders.TestSetup;
begin
  dmOrders := TDataModuleOrders.Create(DataModuleConnection.GetConnection());
end;

procedure TTestDMOrders.TestTeardown;
begin
  dmOrders.Free;
end;

initialization

TDUnitX.RegisterTestFixture(TTestDMOrders);

finalization

end.
