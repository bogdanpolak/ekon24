unit Domain.Order;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections;

type
  TItem = class
  private
    fProductId: Integer;
    fUnitPrice: Currency;
    fUnits: Integer;
    fDeductedPrice: Currency;
    fAllowDeduction: boolean;
  public
    property ProductId: Integer read fProductId;
    property UnitPrice: Currency read fUnitPrice;
    property Units: Integer read fUnits;
    property DeductedPrice: Currency read fDeductedPrice;
    property AllowDeduction: boolean read fAllowDeduction;
    constructor Create(aProductId: Integer; aUnitPrice: Currency;
      aUnits: Integer; aDeductedPrice: Currency; aAllowDeduction: boolean);
  end;

  TOrder = class
  private
    fCustomerId: string;
    fOrderDate: TDateTime;
    fItems: TObjectList<TItem>;
    fDiscount: Integer;
  public
    property CustomerId: string read fCustomerId;
    property OrderDate: TDateTime read fOrderDate;
    property Discount: Integer read fDiscount;
    constructor Create(const aCustomerId: string; const aOrderDate: TDateTime);
    function AddItem(const aProductId: Integer; const aUnitPrice: Currency;
      const aUnits: Integer; const aDeductedPrice: Currency;
      const aAllowDeduction: boolean): TOrder;
    function GetTotal(): Currency;
    function GetDiscountedTotal(): Currency;
  end;

implementation

{ TOrder }

constructor TOrder.Create(const aCustomerId: string;
  const aOrderDate: TDateTime);
begin
  self.fCustomerId := aCustomerId;
  self.fOrderDate := aOrderDate;
end;

function TOrder.GetDiscountedTotal: Currency;
var
  item: TItem;
begin
  Result := 0;
  for item in fItems do
    Result := Result + item.UnitPrice * item.Units;
end;

function TOrder.GetTotal: Currency;
var
  item: TItem;
begin
  Result := 0;
  for item in fItems do
    Result := Result + item.UnitPrice * item.Units;
end;

function TOrder.AddItem(const aProductId: Integer; const aUnitPrice: Currency;
  const aUnits: Integer; const aDeductedPrice: Currency;
  const aAllowDeduction: boolean): TOrder;
begin
  fItems.Add(TItem.Create(aProductId, aUnitPrice, aUnits, aDeductedPrice,
    aAllowDeduction));
  Result := self;
end;

{ TItem }

constructor TItem.Create(aProductId: Integer; aUnitPrice: Currency;
  aUnits: Integer; aDeductedPrice: Currency; aAllowDeduction: boolean);
begin
  self.fProductId := aProductId;
  self.fUnitPrice := aUnitPrice;
  self.fUnits := aUnits;
  self.fDeductedPrice := aDeductedPrice;
  self.fAllowDeduction := aAllowDeduction;
end;

end.
