program Session01Isolation;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  Test.DiscountCalculator in 'Test.DiscountCalculator.pas',
  DataModule.Main in 'src\DataModule.Main.pas',
  DiscountCalculator in 'src\DiscountCalculator.pas',
  Delphi.Mocks.AutoMock in '..\components\Delphi-Mocks\Delphi.Mocks.AutoMock.pas',
  Delphi.Mocks.Behavior in '..\components\Delphi-Mocks\Delphi.Mocks.Behavior.pas',
  Delphi.Mocks.Expectation in '..\components\Delphi-Mocks\Delphi.Mocks.Expectation.pas',
  Delphi.Mocks.Helpers in '..\components\Delphi-Mocks\Delphi.Mocks.Helpers.pas',
  Delphi.Mocks.Interfaces in '..\components\Delphi-Mocks\Delphi.Mocks.Interfaces.pas',
  Delphi.Mocks.MethodData in '..\components\Delphi-Mocks\Delphi.Mocks.MethodData.pas',
  Delphi.Mocks.ObjectProxy in '..\components\Delphi-Mocks\Delphi.Mocks.ObjectProxy.pas',
  Delphi.Mocks.ParamMatcher in '..\components\Delphi-Mocks\Delphi.Mocks.ParamMatcher.pas',
  Delphi.Mocks in '..\components\Delphi-Mocks\Delphi.Mocks.pas',
  Delphi.Mocks.Proxy in '..\components\Delphi-Mocks\Delphi.Mocks.Proxy.pas',
  Delphi.Mocks.Proxy.TypeInfo in '..\components\Delphi-Mocks\Delphi.Mocks.Proxy.TypeInfo.pas',
  Delphi.Mocks.ReturnTypePatch in '..\components\Delphi-Mocks\Delphi.Mocks.ReturnTypePatch.pas',
  Delphi.Mocks.Utils in '..\components\Delphi-Mocks\Delphi.Mocks.Utils.pas',
  Delphi.Mocks.Validation in '..\components\Delphi-Mocks\Delphi.Mocks.Validation.pas',
  Delphi.Mocks.VirtualInterface in '..\components\Delphi-Mocks\Delphi.Mocks.VirtualInterface.pas',
  Delphi.Mocks.VirtualMethodInterceptor in '..\components\Delphi-Mocks\Delphi.Mocks.VirtualMethodInterceptor.pas',
  Delphi.Mocks.WeakReference in '..\components\Delphi-Mocks\Delphi.Mocks.WeakReference.pas',
  Delphi.Mocks.When in '..\components\Delphi-Mocks\Delphi.Mocks.When.pas';

procedure ExecuteTestProject;
{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger : ITestLogger;
{$ENDIF}
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end;

begin
  ExecuteTestProject();
end.
