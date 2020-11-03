unit Domain.DiscountTable;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  {}
  Helper.Currency;

type
  EDiscountTableError = class(Exception);

  TDiscountRow = class
    LimitLow: Currency;
    LimitHigh: Currency;
    Discount: Integer;
    constructor Create(aLow, aHigh: Currency; const aDiscount: Integer);
  end;

  TDiscountTable = class
  private const
    MaxValue = MaxLongInt;
  private
    fBuilded: boolean;
    fRows: TObjectList<TDiscountRow>;
    fLevel: string;
  public
    constructor Create(const aLevel: string);
    destructor Destroy; override;
    function Add(aLow, aHigh: Currency; aDiscount: Integer): TDiscountTable;
    function Build(aMaxDiscount: Integer): TDiscountTable;
    function CalculateDiscount(const aValule: Currency): Integer;
    property Level: string read fLevel;
  end;

implementation

constructor TDiscountTable.Create(const aLevel: string);
begin
  self.fLevel := aLevel;
  self.fBuilded := false;
  self.fRows := TObjectList<TDiscountRow>.Create;
end;

destructor TDiscountTable.Destroy;
begin
  fRows.Free;
  inherited;
end;

function TDiscountTable.Add(aLow, aHigh: Currency; aDiscount: Integer)
  : TDiscountTable;
begin
  if fBuilded then
    raise EDiscountTableError.Create
      ('Table was builded and it is not able to modify now');
  fRows.Add(TDiscountRow.Create(aLow, aHigh, aDiscount));
  Result := self;
end;

function TDiscountTable.Build(aMaxDiscount: Integer): TDiscountTable;
begin
  if fRows.Count = 0 then
    Add(0, MaxValue, aMaxDiscount)
  else
    Add(fRows.Last.LimitLow, MaxValue, aMaxDiscount);
  fBuilded := True;
  Result := self;
end;

function TDiscountTable.CalculateDiscount(const aValule: Currency): Integer;
var
  row: TDiscountRow;
begin
  if not fBuilded then
    raise EDiscountTableError.Create
      ('Please complete adding items and call Build() method');
  Result := 0;
  for row in fRows do
    if aValule.IsInRangeLeft(row.LimitLow, row.LimitHigh) then
      exit(row.Discount);
end;

{ TDiscountRow }

constructor TDiscountRow.Create(aLow, aHigh: Currency;
  const aDiscount: Integer);
begin
  self.LimitLow := aLow;
  self.LimitHigh := aHigh;
  self.Discount := aDiscount;
end;

end.
