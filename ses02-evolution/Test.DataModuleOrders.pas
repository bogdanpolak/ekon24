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
  [TestFixture]
  TestCalculateOrderTotalValue = class
  private
    dmOrders: TDataModuleOrders;
  public
    [Setup]
    procedure TestSetup;
    [Teardown]
    procedure TestTeardown;
  published
  end;

implementation

procedure TestCalculateOrderTotalValue.TestSetup;
begin
  dmOrders := TDataModuleOrders.Create(DataModuleConnection.GetConnection());
end;

procedure TestCalculateOrderTotalValue.TestTeardown;
begin
  dmOrders.Free;
end;

initialization

TDUnitX.RegisterTestFixture(TestCalculateOrderTotalValue);

finalization

end.
