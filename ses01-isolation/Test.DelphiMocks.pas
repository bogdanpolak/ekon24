unit Test.DelphiMocks;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  System.SysUtils,
  System.Rtti,
  Delphi.Mocks;

type
  IProcessor = interface(IInvokable)
    ['{B43E2C6D-581B-4C97-9C9D-E0D6DD22C2E0}']
    function GetString(aInd: Integer): string;
  end;

type
{$M+}

  [TestFixture]
  TestDelphiMocks = class
  private
    fOwner: TComponent;
    fStringList: TStringList;
    fMockProcessor: TMock<IProcessor>;
    fProcessor: IProcessor;
  public
    [Setup]
    procedure TestSetup;
    [Teardown]
    procedure TestTeardown;
  published
    procedure Test01;
  end;
{$M-}

implementation

procedure TestDelphiMocks.TestSetup;
begin
  fOwner := TComponent.Create(nil);
  fStringList := TStringList.Create;
  fMockProcessor := TMock<IProcessor>.Create();
  fProcessor := fMockProcessor;
end;

procedure TestDelphiMocks.TestTeardown;
begin
  fStringList.Free;
  fOwner.Free;
  fMockProcessor.Free;
end;

// -------------------------------------------------------------------
// Test Mock Setup
// -------------------------------------------------------------------

procedure TestDelphiMocks.Test01;
begin
  fMockProcessor.Setup.WillReturn('abc').When.GetString(It0.IsAny<Integer>);

  fMockProcessor.Setup.Expect.Once.When.GetString(It0.IsAny<Integer>);

  Assert.AreEqual('abc',fProcessor.GetString(0));

  fMockProcessor.Verify();
end;


// -------------------------------------------------------------------
// Test Mock Behaviour
// -------------------------------------------------------------------

initialization

TDUnitX.RegisterTestFixture(TestDelphiMocks);

end.
