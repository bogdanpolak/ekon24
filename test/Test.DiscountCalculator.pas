unit Test.DiscountCalculator;

interface

uses
  DUnitX.TestFramework, Database.Module;

{$M+}

type

  [TestFixture]
  TTestDiscountCalculator = class
  private
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  published
    procedure GetCustomerLevel_ShouldEqualStandard;
    procedure UpdateOrderDiscount_Granted4;
  end;

implementation

procedure TTestDiscountCalculator.Setup;
begin
  DataModule1.FDConnection1.Open();
end;

procedure TTestDiscountCalculator.TearDown;
begin
end;

procedure TTestDiscountCalculator.GetCustomerLevel_ShouldEqualStandard;
var
  actual: string;
begin
  actual := DataModule1.GetCustomerLevel('DE136695976');
  Assert.AreEqual('standard', actual);
end;

procedure TTestDiscountCalculator.UpdateOrderDiscount_Granted4;
var
  orderid: Integer;
  actual: Integer;
begin
  orderid := 5;
  DataModule1.UpdateOrderDiscount(orderid, 4);
  actual := DataModule1.FDConnection1.ExecSQLScalar
    ('select GrantedDiscount from Orders where OrderId = :OrderID', [orderid]);
  Assert.AreEqual(4, actual);
end;

initialization

TDUnitX.RegisterTestFixture(TTestDiscountCalculator);

end.
