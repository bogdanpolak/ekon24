unit Helper.Currency;

interface

type
  TCurrencyRecordHelper = record helper for Currency
  public
    /// <summary>
    /// self in [aLimit1, aLimit2)
    /// </summary>
    function IsInRangeLeft(aLimit1: Currency; aLimit2: Currency): boolean;
    /// <summary>
    /// self in (aLimit1, aLimit2)
    /// </summary>
    function IsInRangeOpen(aLimit1: Currency; aLimit2: Currency): boolean;
    /// <summary> self in [aLimit1, aLimit2] </summary>
    function IsInRangeClosed(aLimit1, aLimit2: Currency): boolean;
    /// <summary> self in [aLimit1, aLimit2) </summary>
    function IsInRangeRight(aLimit1, aLimit2: Currency): boolean;
  end;

implementation

function TCurrencyRecordHelper.IsInRangeClosed(aLimit1: Currency;
  aLimit2: Currency): boolean;
begin
  Result := (aLimit1 <= self) and (self <= aLimit2);
end;

function TCurrencyRecordHelper.IsInRangeLeft(aLimit1: Currency;
  aLimit2: Currency): boolean;
begin
  Result := (aLimit1 <= self) and (self < aLimit2);
end;

function TCurrencyRecordHelper.IsInRangeRight(aLimit1: Currency;
  aLimit2: Currency): boolean;
begin
  Result := (aLimit1 < self) and (self <= aLimit2);
end;

function TCurrencyRecordHelper.IsInRangeOpen(aLimit1: Currency;
  aLimit2: Currency): boolean;
begin
  Result := (aLimit1 < self) and (self < aLimit2);
end;

end.
