unit Test.DiscountCalculator;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDiscountCalculator = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  published
    procedure Test1;
  end;

implementation

procedure TTestDiscountCalculator.Setup;
begin
end;

procedure TTestDiscountCalculator.TearDown;
begin
end;

procedure TTestDiscountCalculator.Test1;
begin
  Assert.Fail();
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDiscountCalculator);

end.
