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

  [TestFixture]
  TestDelphiMocks = class
  private
    fOwner: TComponent;
    fStringList: TStringList;
  public
    [Setup]
    procedure TestSetup;
    [Teardown]
    procedure TestTeardown;
  published
  end;
{$M-}

implementation

procedure TestDelphiMocks.TestSetup;
begin
  fOwner := TComponent.Create(nil);
  fStringList := TStringList.Create;
end;

procedure TestDelphiMocks.TestTeardown;
begin
  fStringList.Free;
  fOwner.Free;
end;

// -------------------------------------------------------------------
// Test Mock Setup
// -------------------------------------------------------------------

// -------------------------------------------------------------------
// Test Mock Behaviour
// -------------------------------------------------------------------

initialization

TDUnitX.RegisterTestFixture(TestDelphiMocks);

end.
