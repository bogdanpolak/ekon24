unit Test.DiscountCalculator;

interface

uses
  DUnitX.TestFramework,
  {}
  Database.Module,
  Domain.DiscountCalculator;

{$M+}

type

  [TestFixture]
  TTestDiscountCalculator = class
  private
    fDiscountCalculator: TDiscountCalculator;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  published
    procedure GetCustomerLevel_ShouldEqualStandard;
    procedure OrderTotalValue_OrderId1;
  end;

implementation

procedure TTestDiscountCalculator.Setup;
begin
  DataModule1.FDConnection1.Open();
  fDiscountCalculator := TDiscountCalculator.Create()
end;

procedure TTestDiscountCalculator.TearDown;
begin
  fDiscountCalculator.Free();
end;

procedure TTestDiscountCalculator.GetCustomerLevel_ShouldEqualStandard;
var
  actual: string;
begin
  actual := DataModule1.GetCustomerLevel('DE136695976');
  Assert.AreEqual('standard', actual);
end;

procedure TTestDiscountCalculator.OrderTotalValue_OrderId1;
var
  actual: Currency;
begin
  DataModule1.FDConnection1.StartTransaction;
  actual := fDiscountCalculator.OrderTotalValue(1);
  Assert.AreEqual(Currency(2371.60), actual, 0.0001);
  DataModule1.FDConnection1.Commit;
end;

initialization

TDUnitX.RegisterTestFixture(TTestDiscountCalculator);

end.
