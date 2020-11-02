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
    [Test]
    [TestCase('[silver    0.00]', 'silver, 0, 0')]
    [TestCase('[silver  999.99]', 'silver, 999.99, 0')]
    [TestCase('[silver 1000.00]', 'silver, 1000.00, 1')]
    [TestCase('[silver 1999.99]', 'silver, 1999.99, 1')]
    [TestCase('[silver 2000.00]', 'silver, 2000, 3')]
    [TestCase('[silver 3000.00]', 'silver, 3000, 9')]
    procedure Calculate(const aLevel: String; aTotal: Currency;
      aExpectedDiscount: Integer);
  published
    procedure Integration_Calculate;
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

type
  TDataRow = TArray<Variant>;

function GivenTresholdsDataSet(aOwner: TComponent;
  const aRecordArray: TArray<TDataRow>): TDataSet;
var
  ds: TClientDataSet;
  idxRow: Integer;
  idxField: Integer;
begin
  ds := TClientDataSet.Create(aOwner);
  with ds do
  begin
    FieldDefs.Add('Level', ftWideString, 10);
    with FieldDefs.AddFieldDef do
    begin
      Name := 'LimitBottom';
      DataType := ftFMTBcd;
      Precision := 19;
      Size := 4;
    end;
    FieldDefs.Add('Discount', ftInteger);
    CreateDataSet;
  end;
  for idxRow := 0 to High(aRecordArray) do
  begin
    ds.Append;
    for idxField := 0 to High(aRecordArray[idxRow]) do
      ds.Fields[idxField].Value := aRecordArray[idxRow][idxField];
    ds.Post;
  end;
  ds.First;
  Result := ds;
end;

procedure TTestDiscountCalculator.Calculate(const aLevel: String;
  aTotal: Currency; aExpectedDiscount: Integer);
var
  ds: TDataSet;
  actual: Integer;
begin
  ds := GivenTresholdsDataSet(fOwner, [
    { } ['gold', 1000, 99],
    { } ['silver', 1000, 1],
    { } ['silver', 2000, 3],
    { } ['silver', 3000, 9],
    { } ['standard', 1000, 99]]);
  actual := TDiscountCalculator.Calculate(ds, aLevel, aTotal);
  Assert.AreEqual(aExpectedDiscount, actual);
end;

procedure TTestDiscountCalculator.Integration_Calculate;
var
  mainmodule: TMainDataModule;
  actualDiscount: Integer;
begin
  mainmodule := TMainDataModule.Create(fOwner);
  actualDiscount := mainmodule.CalculateDiscount('PL5352679105', 2500);
  Assert.AreEqual(5,actualDiscount);
  actualDiscount := mainmodule.CalculateDiscount('PL5352679105', 1999);
  Assert.AreEqual(3,actualDiscount);
  actualDiscount := mainmodule.CalculateDiscount('PL5352679105', 1999);
  Assert.AreEqual(3,actualDiscount);
  actualDiscount := mainmodule.CalculateDiscount('PL5352679105', 1450);
  Assert.AreEqual(2,actualDiscount);
  actualDiscount := mainmodule.CalculateDiscount('PL5352679105', 750);
  Assert.AreEqual(0,actualDiscount);
end;


initialization

TDUnitX.RegisterTestFixture(TTestDiscountCalculator);

end.

