unit Test.OrderCalculator;

interface

uses
  DUnitX.TestFramework,
  {}
  DataModule.Orders;

{$M+}

type

  [TestFixture]
  TTestOrderCalculator = class
  public
  published
    procedure OrderTotalValue_OrderId_1;
  end;

implementation

var
  DataModuleOrders: TDataModuleOrders;

procedure TTestOrderCalculator.OrderTotalValue_OrderId_1;
var
  actual: Currency;
begin
  actual := DataModuleOrders.OrderTotalValue(1);
  Assert.AreEqual(Currency(2371.60), actual, 0.0001);
end;

initialization

DataModuleOrders := TDataModuleOrders.Create(nil);
TDUnitX.RegisterTestFixture(TTestOrderCalculator);

finalization

DataModuleOrders.FDConnection1.Close;

end.
