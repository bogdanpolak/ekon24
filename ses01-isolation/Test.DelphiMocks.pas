unit Test.DelphiMocks;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  System.SysUtils,
  System.Rtti,
  Delphi.Mocks;

type
{$M+}
  IMockable = interface(IInterface)
  end;
{$M-}

type
  IRepository = interface(IMockable)
    ['{69162E72-8C1E-421B-B970-15230BBB3B2B}']
    function GetString(aIdx: Integer): string;
    function ConvertStringToInt(const aText: string;
      out aValue: Integer): boolean;
    function StringListToArray(const sl: TStringList): TArray<String>;
  end;

type
{$M+}

  [TestFixture]
  TestDelphiMocks = class
  private
    fOwner: TComponent;
    fStringList: TStringList;
    fRepositoryMock: TMock<IRepository>;
    fRepository: IRepository;
  public
    [Setup]
    procedure TestSetup;
    [Teardown]
    procedure TestTeardown;
  published
    procedure GetString_WillReturnDefault;
    procedure GetString_WillReturn_When1;
    procedure GetString_WillExecute;
    procedure GetString_WillExecute_WhenIt0IsAny;
    procedure ConvertStringToInt_WillExecute;
    procedure StringListToArray_WillExecute;
    procedure VerifyBehaviour;
  end;
{$M-}

implementation

procedure TestDelphiMocks.TestSetup;
begin
  fOwner := TComponent.Create(nil);
  fStringList := TStringList.Create;
  fRepositoryMock := TMock<IRepository>.Create();
  fRepository := fRepositoryMock;
end;

procedure TestDelphiMocks.TestTeardown;
begin
  fStringList.Free;
  fOwner.Free;
  fRepositoryMock.Free;
end;

// -------------------------------------------------------------------
// Test Mock Setup
// -------------------------------------------------------------------

procedure TestDelphiMocks.GetString_WillReturnDefault;
begin
  // fProcessorMock.Setup.WillReturnDefault('GetString', 'Hello');
  fRepositoryMock.Setup.WillReturn('Hello').When.GetString(It0.IsAny<Integer>);
  Assert.AreEqual('Hello', fRepository.GetString(0));
end;

procedure TestDelphiMocks.GetString_WillReturn_When1;
begin
  fRepositoryMock.Setup.WillReturn('item-01').When.GetString(1);
  Assert.AreEqual('item-01', fRepository.GetString(1));
end;

procedure TestDelphiMocks.GetString_WillExecute;
begin
  fRepositoryMock.Setup.WillExecute('GetString',
    function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
    begin
      // args[0] is the Self interface reference - here IProcessor01
      case args[1].AsInteger of
        0:
          Result := '--select-item--';
        1 .. 9:
          Result := Format('item-%s', [chr(ord('A') + args[1].AsInteger - 1)]);
      else
        Result := '--error--';
      end;
    end);
  Assert.AreEqual('item-A', fRepository.GetString(1));
end;

procedure TestDelphiMocks.GetString_WillExecute_WhenIt0IsAny;
begin
  fRepositoryMock.Setup.WillExecute(
    function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
    begin
      Result := Format('item-%s', [chr(ord('A') + args[1].AsInteger - 1)]);
    end).When.GetString(It0.IsAny<Integer>);
  Assert.AreEqual('item-@', fRepository.GetString(0));
end;

procedure TestDelphiMocks.ConvertStringToInt_WillExecute;
var
  number: Integer;
begin
  fRepositoryMock.Setup.WillExecute('ConvertStringToInt',
    function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
    var
      value: Integer;
      ok: boolean;
    begin
      ok := TryStrToInt(args[1].AsString, value);
      if ok then
        args[2] := value
      else
        args[2] := 0;
      Result := ok;
    end);
  fRepository.ConvertStringToInt('120', number);
  Assert.AreEqual(120, number);
end;

procedure TestDelphiMocks.StringListToArray_WillExecute;
var
  stringArr: TArray<string>;
begin
  fRepositoryMock.Setup.WillExecute(
    function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
    var
      arr: TArray<string>;
    begin
      arr := args[1].AsType<TStringList>.CommaText.Split([',']);
      Result := TValue.From < TArray < string >> (arr);
    end).When.StringListToArray(It0.IsAny<TStringList>);
  fStringList.Add('Bogdan Polak');
  fStringList.Add('Michael Feathers');
  fStringList.Add('Adam Tornhill');
  stringArr := fRepository.StringListToArray(fStringList);
  Assert.AreEqual('"Michael Feathers"', stringArr[1])
end;

// -------------------------------------------------------------------
// Test Mock Behaviour
// -------------------------------------------------------------------

type
  IProductRepository = interface(IInvokable)
    procedure TransactionStart;
    function AddProduct(const aProductName: string;
    AListPice: Currency): Integer;
    procedure TransactionCommit;
  end;

  TVariantArray = TArray<Variant>;

function AddProducts(const aRepository: IProductRepository;
const aProducts: TArray<TVariantArray>): TArray<Integer>;
var
  iRow: Integer;
  aName: string;
  aPrice: Currency;
  iCount: Integer;
begin
  Result := [];
  if Length(aProducts) > 0 then
  begin
    aRepository.TransactionStart();
    for iRow := 0 to High(aProducts) do
    begin
      aName := aProducts[iRow, 0];
      aPrice := aProducts[iRow, 1];
      if (Trim(aName) <> '') or (aPrice >= 0) then
      begin
        iCount := Length(Result);
        SetLength(Result, iCount + 1);
        Result[iCount] := aRepository.AddProduct(aName, aPrice);
      end;
    end;
    aRepository.TransactionCommit();
  end;
end;

procedure TestDelphiMocks.VerifyBehaviour;
var
  mock: TMock<IProductRepository>;
  repo: IProductRepository;
  productIds: TArray<Integer>;
begin
  // Create mock --------------------------
  mock := TMock<IProductRepository>.Create();
  mock.Setup.WillReturnNil.When.AddProduct(It0.IsAny<string>,
    It0.IsAny<Currency>);
  // Define expected behaviour --------------------------
  mock.Setup.Expect.Once.When.TransactionStart;
  mock.Setup.Expect.Once.When.TransactionCommit;
  mock.Setup.Expect.Between(2, 3).When.AddProduct(It0.IsAny<string>,
    It0.IsAny<Currency>);
  // Act --------------------------
  repo := mock;
  productIds := AddProducts(repo, [
  { } ['winter boy coat', 169.00],
  { } ['green socks pack 6 pack', 14.00]]);
  // Assert/Verify --------------------------
  mock.Verify();
  Assert.Pass();
end;

initialization

TDUnitX.RegisterTestFixture(TestDelphiMocks);

end.
