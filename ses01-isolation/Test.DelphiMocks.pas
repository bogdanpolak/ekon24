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
  IProcessor = interface
    ['{69162E72-8C1E-421B-B970-15230BBB3B2B}']
    function GetString(aIdx: Integer): string;
    function ConvertStringToInt(const aText: string;
      out aValue: Integer): boolean;
    function StringListToArray(const sl: TStringList): TArray<String>;
  end;
{$M-}
{$M+}

  [TestFixture]
  TestDelphiMocks = class
  private
    fOwner: TComponent;
    fProcessorMock: TMock<IProcessor>;
    fProcessor: IProcessor;
    fStringList: TStringList;
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
  end;
{$M-}

implementation

procedure TestDelphiMocks.TestSetup;
begin
  fOwner := TComponent.Create(nil);
  fStringList := TStringList.Create;
  fProcessorMock := TMock<IProcessor>.Create();
  fProcessor := fProcessorMock;
end;

procedure TestDelphiMocks.TestTeardown;
begin
  fProcessorMock.Free;
  fStringList.Free;
  fOwner.Free;
end;

// -------------------------------------------------------------------
// Tests
// -------------------------------------------------------------------

procedure TestDelphiMocks.GetString_WillReturnDefault;
begin
  // fProcessorMock.Setup.WillReturnDefault('GetString', 'Hello');
  fProcessorMock.Setup.WillReturn('Hello').When.GetString(It0.IsAny<Integer>);
  Assert.AreEqual('Hello', fProcessorMock.Instance.GetString(0));
end;

procedure TestDelphiMocks.GetString_WillReturn_When1;
begin
  fProcessorMock.Setup.WillReturn('item-01').When.GetString(1);
  Assert.AreEqual('item-01', fProcessor.GetString(1));
end;

procedure TestDelphiMocks.GetString_WillExecute;
begin
  fProcessorMock.Setup.WillExecute('GetString',
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
  Assert.AreEqual('item-A', fProcessor.GetString(1));
end;

procedure TestDelphiMocks.GetString_WillExecute_WhenIt0IsAny;
begin
  fProcessorMock.Setup.WillExecute(
    function(const args: TArray<TValue>; const ReturnType: TRttiType): TValue
    begin
      Result := Format('item-%s', [chr(ord('A') + args[1].AsInteger - 1)]);
    end).When.GetString(It0.IsAny<Integer>);
  Assert.AreEqual('item-@', fProcessor.GetString(0));
end;

procedure TestDelphiMocks.ConvertStringToInt_WillExecute;
var
  number: Integer;
begin
  fProcessorMock.Setup.WillExecute('ConvertStringToInt',
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
  fProcessor.ConvertStringToInt('120', number);
  Assert.AreEqual(120, number);
end;

procedure TestDelphiMocks.StringListToArray_WillExecute;
var
  stringArr: TArray<string>;
begin
  fProcessorMock.Setup.WillExecute(
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
  stringArr := fProcessor.StringListToArray(fStringList);
  Assert.AreEqual('"Michael Feathers"', stringArr[1])
end;

initialization

TDUnitX.RegisterTestFixture(TestDelphiMocks);

end.
