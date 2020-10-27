unit Domain.DiscountCalculator;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  {}
  Database.Module;

type
  TDiscountCalculator = class
  private
    // fDataModule: TDataModule1;
    function FindDiscount(const aLevel: String; aTotalValue: Currency): Integer;
  public
    constructor Create();
    destructor Destroy; override;
    function OrderTotalValue(aOrderId: Integer): Currency;
  end;

implementation

uses
  FireDAC.Comp.Client,
  FireDAC.Stan.Param;

constructor TDiscountCalculator.Create();
begin
  // fDataModule := aDataModule;
end;

destructor TDiscountCalculator.Destroy;
begin
  inherited;
end;

function InRange(aValue: Currency; aLimit1: Currency;
  aLimit2: Currency): boolean;
begin
  Result := (aLimit1 <= aValue) and (aValue < aLimit2);  
end;

function TDiscountCalculator.FindDiscount(const aLevel: string;
  aTotalValue: Currency): Integer;
var
  dataset: TFDQuery;
  level: string;
  limit1: Currency;
  limit2: Currency;
begin
  dataset := DataModule1.fdqThresholds;
  dataset.Open();
  dataset.First;
  dataset.Locate('Level', aLevel);
  limit1 := 0;
  Result := 0;
  while not dataset.Eof do
  begin
    level := dataset.FieldByName('Level').AsString;
    limit2 := dataset.FieldByName('LimitBottom').AsCurrency;
    if (level <> aLevel) or InRange(aTotalValue, limit1, limit2) then
      Exit;
    Result := dataset.FieldByName('Discount').AsInteger;
    limit1 := limit2;
    dataset.Next;
  end;
end;

function RoundUnitPrice(price: Currency): Currency;
begin
  Result := Round(Int(price * 100))/100;
end;

function TDiscountCalculator.OrderTotalValue(aOrderId: Integer): Currency;
var
  dataset: TFDQuery;
  customerId: string;
  level: string;
  unitprice: Currency;
  units: Integer;
  totalBeforeDeduction: Currency;
  totalAfterDeduction: Currency;
  discount: Integer;
  isDeductable: Boolean;
  deductedPrice: Currency;
begin
  DataModule1.fdqOrderItems.ParamByName('OrderId').AsInteger := aOrderId;
  dataset := DataModule1.fdqOrderItems;
  dataset.Open();
  if dataset.Eof then
    Exit(0);
  customerId := dataset.FieldByName('CustomerId').AsString;
  level := DataModule1.GetCustomerLevel(customerId);
  totalBeforeDeduction := 0;
  while not dataset.Eof do
  begin
    unitprice := dataset.FieldByName('UnitPrice').AsCurrency;
    units := dataset.FieldByName('Units').AsInteger;
    totalBeforeDeduction := totalBeforeDeduction + unitprice*units;
    dataset.Next;
  end;
  discount := FindDiscount(level,totalBeforeDeduction);
  totalAfterDeduction := 0;
  dataset.First;
  DataModule1.FDConnection1.StartTransaction;
  DataModule1.UpdateOrderDiscount(aOrderId, discount);
  while not dataset.Eof do
  begin
    unitprice := dataset.FieldByName('UnitPrice').AsCurrency;
    units := dataset.FieldByName('Units').AsInteger;
    isDeductable := (dataset.FieldByName('AllowDeduction').AsInteger > 0);
    if isDeductable then
      deductedPrice := RoundUnitPrice(unitprice*((100-discount)/100))
    else
      deductedPrice := unitprice;
    totalAfterDeduction := totalAfterDeduction + deductedPrice*units;
    dataset.Edit;
    dataset.FieldByName('DeductedPrice').AsCurrency :=  deductedPrice;
    dataset.Post;
    dataset.Next;
  end;
  DataModule1.FDConnection1.Commit;
  Result := totalAfterDeduction;
end;

end.
