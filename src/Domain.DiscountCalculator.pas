unit Domain.DiscountCalculator;

interface

uses
  System.Classes,
  System.SysUtils,
  Database.Module;

type
  TDiscountCalculator = class
  private
    fDataModule: TDataModule1;
  public
    constructor Create(aDataModule: TDataModule1);
    function OrderTotalValue(aOrderId: integer): Currency;
  end;

implementation

{ TDiscountCalculator }

constructor TDiscountCalculator.Create(aDataModule: TDataModule1);
begin
  fDataModule := aDataModule;
end;

function TDiscountCalculator.OrderTotalValue(aOrderId: integer): Currency;
begin

end;

end.
