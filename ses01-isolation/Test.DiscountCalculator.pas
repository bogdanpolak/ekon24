unit Test.DiscountCalculator;

interface

uses
  DUnitX.TestFramework,
  System.Classes;

{$M+}

type

  [TestFixture]
  TTestEkonDemo = class
  public
    [Test]
    [TestCase('[silver    0.00]', 'silver, 0, 0')]
    [TestCase('[silver  999.99]', 'silver, 999.99, 0')]
    [TestCase('[silver 1000.00]', 'silver, 1000.00, 1')]
    [TestCase('[silver 1999.99]', 'silver, 1999.99, 1')]
    [TestCase('[silver 2000.00]', 'silver, 2000, 3')]
    [TestCase('[silver 3000.00]', 'silver, 3000, 9')]
    procedure TestFindDiscount(const aLevel: String; aTotal: Currency;
      aExpectedDiscount: Integer);
  end;

implementation

uses
  Data.DB,
  Datasnap.DBClient;

function GivenTresholdsDataSet(aOwner: TComponent;
  const aRecordArray: TArray < TArray < Variant >> ): TDataSet;
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

function InRange(aValue: Currency; aLimit1: Currency;
  aLimit2: Currency): boolean;
begin
  Result := (aLimit1 <= aValue) and (aValue < aLimit2);
end;

function FindDiscount(dsThresholds: TDataSet; const aLevel: string;
  aTotalValue: Currency): Integer;
var
  level: string;
  limit1: Currency;
  limit2: Currency;
begin
  dsThresholds.Locate('Level', aLevel, []);
  limit1 := 0;
  Result := 0;
  while not dsThresholds.Eof do
  begin
    level := dsThresholds.FieldByName('Level').AsString;
    limit2 := dsThresholds.FieldByName('LimitBottom').AsCurrency;
    if (level <> aLevel) or InRange(aTotalValue, limit1, limit2) then
      Exit;
    Result := dsThresholds.FieldByName('Discount').AsInteger;
    limit1 := limit2;
    dsThresholds.Next;
  end;
end;

{ TTestEkonDemo }

procedure TTestEkonDemo.TestFindDiscount(const aLevel: String; aTotal: Currency;
  aExpectedDiscount: Integer);
var
  ds: TDataSet;
  actual: Integer;
begin
  ds := GivenTresholdsDataSet(nil, [
    { } ['gold', 1000, 99],
    { } ['silver', 1000, 1],
    { } ['silver', 2000, 3],
    { } ['silver', 3000, 9],
    { } ['standard', 1000, 99]]);
  actual := FindDiscount(ds, aLevel, aTotal);
  Assert.AreEqual(aExpectedDiscount, actual);
end;

initialization

TDUnitX.RegisterTestFixture(TTestEkonDemo);

end.
