unit DiscountCalculator;

interface

uses
  System.Classes,
  Data.DB;

type
  TDiscountCalculator = class
  public
    class function Calculate(const aDataset: TDataSet; const aLevel: String;
      aTotalValue: Currency): Integer; static;
  end;

implementation

function InRange(aValue: Currency; aLimit1: Currency;
  aLimit2: Currency): boolean;
begin
  Result := (aLimit1 <= aValue) and (aValue < aLimit2);
end;

class function TDiscountCalculator.Calculate(const aDataset: TDataSet;
  const aLevel: String;  aTotalValue: Currency): Integer;
var
  limit1: Currency;
  limit2: Currency;
begin
  aDataset.Locate('Level', aLevel, []);
  Result := 0;
  limit1 := 0;
  while not(aDataset.Eof) and
    (aDataset.FieldByName('Level').AsString = aLevel) do
  begin
    limit2 := aDataset.FieldByName('LimitBottom').AsCurrency;
    if InRange(aTotalValue, limit1, limit2) then
      Exit;
    Result := aDataset.FieldByName('Discount').AsInteger;
    limit1 := limit2;
    aDataset.Next;
  end;
end;

end.
