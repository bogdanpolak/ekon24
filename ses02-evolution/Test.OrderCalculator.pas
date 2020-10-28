unit Test.OrderCalculator;

interface

uses
  DUnitX.TestFramework,
  { }
  DataModule.Main;

{$M+}

type

  [TestFixture]
  TTestOrderCalculator = class
  public
  published
    procedure OrderTotalValue_OrderId_1;
  end;

implementation

procedure TTestOrderCalculator.OrderTotalValue_OrderId_1;
var
  actual: Currency;
begin
  actual := DataModuleMain.OrderTotalValue(1);
  Assert.AreEqual(Currency(2371.60), actual, 0.0001);
end;

initialization

TDUnitX.RegisterTestFixture(TTestOrderCalculator);

end.

