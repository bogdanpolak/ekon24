unit Test.OrderCalculator;

interface

uses
  DUnitX.TestFramework,
  { }
  OrderCalculator;

{$M+}

type

  [TestFixture]
  TTestOrderCalculator = class
  private
    fOrderCalculator: TOrderCalculator;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  published
    procedure OrderTotalValue_OrderId_1;
  end;

implementation

procedure TTestOrderCalculator.Setup;
begin
  fOrderCalculator := TOrderCalculator.Create()
end;

procedure TTestOrderCalculator.TearDown;
begin
  fOrderCalculator.Free();
end;

procedure TTestOrderCalculator.OrderTotalValue_OrderId_1;
var
  actual: Currency;
begin
  actual := fOrderCalculator.OrderTotalValue(1);
  Assert.AreEqual(Currency(2371.60), actual, 0.0001);
end;

initialization

TDUnitX.RegisterTestFixture(TTestOrderCalculator);

end.

