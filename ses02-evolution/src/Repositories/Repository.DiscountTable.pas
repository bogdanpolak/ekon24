unit Repository.DiscountTable;

interface

uses
  System.Classes,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  {}
  Repository,
  Domain.DiscountTable;

type
  TDiscountTableRepository = class(TInterfacedObject, IDiscountTableRepository)
  private
    fOwner: TComponent;
    fTables: TObjectDictionary<string,TDiscountTable>;
    fdqThresholds: TFDQuery;
    fConnection: TFDConnection;
  public
    constructor Create(aConnection: TFDConnection);
    destructor Destroy; override;
    function Get(const aLevel: string): TDiscountTable;
  end;

implementation

constructor TDiscountTableRepository.Create(aConnection: TFDConnection);
begin
  fOwner := TComponent.Create(nil);
  fTables := TObjectDictionary<string,TDiscountTable>.Create([doOwnsValues]);
  fConnection := aConnection;
  fdqThresholds := TFDQuery.Create(fOwner);
  fdqThresholds.connection := fConnection;
  fdqThresholds.SQL.Text :=
    'SELECT Level, LimitBottom, Discount FROM Thresholds' +
    ' ORDER BY Level, LimitBottom';
end;

destructor TDiscountTableRepository.Destroy;
begin
  fOwner.Free;
  fTables.Free;
  inherited;
end;

function TDiscountTableRepository.Get(const aLevel: string): TDiscountTable;
var
  limit1: Currency;
  limit2: Currency;
  discount: Integer;
begin
  if fTables.TryGetValue(aLevel, Result) then
    exit;
  Result := TDiscountTable.Create(aLevel);
  fTables.Add(aLevel,Result);
  fdqThresholds.Open();
  fdqThresholds.First;
  fdqThresholds.Locate('Level', aLevel);
  limit1 := 0;
  discount := 0;
  while not(fdqThresholds.Eof) and (aLevel = fdqThresholds.FieldByName('Level')
    .AsString) do
  begin
    limit2 := fdqThresholds.FieldByName('LimitBottom').AsCurrency;
    Result.Add(limit1,limit2,discount);
    discount := fdqThresholds.FieldByName('Discount').AsInteger;
    limit1 := limit2;
    fdqThresholds.Next;
  end;
  Result.Build(discount);
end;

end.
