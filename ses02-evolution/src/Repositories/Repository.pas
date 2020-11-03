unit Repository;

interface

uses
  System.SysUtils,
  Domain.DiscountTable,
  Domain.Order;

type
  EOrderRepositoryError = class(Exception);

  IDiscountTableRepository = interface(IInvokable)
    ['{BC365076-0A8A-4C49-8BF2-5DD77D9E2DEE}']
    function Get(const aLevel: string): TDiscountTable;
  end;

  ICustomerRepository = interface(IInvokable)
    ['{07008C47-861B-4D5C-983D-D216613BBEA4}']
    function GetLevel(const aCustomerId: string): string;
  end;

  IOrderRepository = interface(IInvokable)
    ['{DF90EAC0-F0BC-4F3C-A431-65D2567D3D38}']
    function Get(const aOrderId: Integer): TOrder;
    procedure ApplyDiscount(discount: Integer);
  end;

implementation

end.
