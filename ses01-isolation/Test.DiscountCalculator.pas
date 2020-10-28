unit Test.DiscountCalculator;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  { }
  DataModule.Main,
  DiscountCalculator;

{$M+}

type

  [TestFixture]
  TTestDiscountCalculator = class
  private
    fOwner: TComponent;
  public
    [Setup]
    procedure TestSetup;
    [Teardown]
    procedure TestTeardown;
  end;

implementation

uses
  Data.DB,
  Datasnap.DBClient;

procedure TTestDiscountCalculator.TestSetup;
begin
  fOwner := TComponent.Create(nil);
end;

procedure TTestDiscountCalculator.TestTeardown;
begin
  fOwner.Free;
end;

initialization

TDUnitX.RegisterTestFixture(TTestDiscountCalculator);

end.
