unit Repository.Order;

interface

uses
  System.SysUtils,
  System.Classes,
  FireDAC.Stan.Param,
  FireDAC.Comp.Client,
  {}
  Domain.Order,
  Repository;

type
  TOrderRepository = class(TInterfacedObject, IOrderRepository)
  private
    fOwner: TComponent;
    fConnection: TFDConnection;
    fdqOrders: TFDQuery;
    fdqOrderItems: TFDQuery;
    function BuildQuery(const aSQL: string): TFDQuery;
  public
    constructor Create(aConnection: TFDConnection);
    destructor Destroy; override;
    function Get(const aOrderId: Integer): TOrder;
    procedure ApplyDiscount(discount: Integer);
  end;

implementation

function TOrderRepository.BuildQuery(const aSQL: string): TFDQuery;
begin
  Result := TFDQuery.Create(fOwner);
  Result.Connection := fConnection;
  Result.SQL.Text := aSQL;
end;

constructor TOrderRepository.Create(aConnection: TFDConnection);
begin
  self.fConnection := aConnection;
  fOwner := TComponent.Create(nil);
  fdqOrders := BuildQuery('SELECT CustomerId, GrantedDiscount, OrderDate' +
    ' FROM Orders WHERE OrderId = :OrderId');
  fdqOrderItems := BuildQuery
    ('SELECT' +
    ' Items.ProductId, Items.UnitPrice, Items.DeductedPrice, Items.Units,' +
    ' Products.Name, Products.AllowDeduction' + ' FROM Items' +
    ' INNER JOIN Products ON Items.ProductId = Products.ProductId' +
    ' WHERE Orders.OrderId = :OrderId');
end;

destructor TOrderRepository.Destroy;
begin
  fOwner.Free;
  inherited;
end;

function TOrderRepository.Get(const aOrderId: Integer): TOrder;
var
  allowDeduction: Boolean;
begin
  fdqOrders.ParamByName('OrderId').AsInteger := aOrderId;
  fdqOrders.Open();
  if fdqOrders.Eof then
    raise EOrderRepositoryError.Create
      (Format('Can''t find order with id: %d in the database', [aOrderId]));
  Result := TOrder.Create(fdqOrders.FieldByName('CustomerId').AsString,
    fdqOrders.FieldByName('OrderDate').AsDateTime);
  // -------
  fdqOrderItems.ParamByName('OrderId').AsInteger := aOrderId;
  fdqOrderItems.Open();
  while not fdqOrderItems.Eof do
  begin
    allowDeduction := fdqOrderItems.FieldByName('AllowDeduction').AsInteger > 0;
    Result.AddItem(fdqOrderItems.FieldByName('ProductId').AsInteger,
      fdqOrderItems.FieldByName('UnitPrice').AsCurrency,
      fdqOrderItems.FieldByName('Units').AsInteger,
      fdqOrderItems.FieldByName('DeductedPrice').AsCurrency, allowDeduction);
    fdqOrderItems.Next;
  end;
end;

procedure TOrderRepository.ApplyDiscount(discount: Integer);
begin
  // TODO: Code have to migrated here from TDataModuleOrders
end;

end.
