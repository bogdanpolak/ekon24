unit ItemRecord;

interface

type
  TItemRecord = record
    ProductId: integer;
    UnitPrice: Currency;
    Units: Integer;
    constructor Create(aProductId: integer; aUnitPrice: Currency; aUnits: Integer);
  end;

implementation

constructor TItemRecord.Create(aProductId: integer; aUnitPrice: Currency;
  aUnits: Integer);
begin
  ProductId := aProductId;
  UnitPrice := aUnitPrice;
  Units := aUnits;
end;

end.
