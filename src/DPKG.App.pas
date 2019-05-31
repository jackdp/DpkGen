unit DPKG.App;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

{$DEFINE USE_CUSTOM_STRING_LIST}

interface

uses 
  SysUtils,
  {$IFDEF USE_CUSTOM_STRING_LIST}
  JPL.StrList,
  {$ELSE}
  Classes,
  {$ENDIF}
  JPL.Strings,
  JPL.Console,
  JPL.ConsoleApp,
  JPL.CmdLineParser,
  DPKG.Types;

type

  {$IFDEF USE_CUSTOM_STRING_LIST}
  TStringList = TJPStrList;
  {$ENDIF}

  TApp = class(TJPConsoleApp)
  private
    AppParams: TAppParams;
  public
    procedure Init;
    procedure Run;

    procedure RegisterOptions;
    procedure ProcessOptions;

    procedure CreateDpkFile;

    procedure DisplayHelpAndExit(const ExCode: integer);
    procedure DisplayShortUsageAndExit(const Msg: string; const ExCode: integer);
    procedure DisplayBannerAndExit(const ExCode: integer);
    procedure DisplayMessageAndExit(const Msg: string; const ExCode: integer);
  end;



implementation



{$region '                    Init                              '}

procedure TApp.Init;
begin
  //----------------------------------------------------------------------------

  AppName := 'DpkGen';
  MajorVersion := 1;
  MinorVersion := 0;
  Date := EncodeDate(2019, 5, 31);
  FullNameFormat := '%AppName% %MajorVersion%.%MinorVersion% [%OSShort% %Bits%-bit] (%AppDate%)';
  Description := 'Generates Delphi package files (DPK) based on the given template file.';
  LicenseName := 'Freeware, OpenSource';
  Author := 'Jacek Pazera';
  //HomePage := 'http://www.pazera-software.com/products/dpk-generator/';
  HomePage := 'https://github.com/jackdp/DpkGen';
  HelpPage := HomePage;

  //-----------------------------------------------------------------------------

  TryHelpStr := ENDL + 'Try "' + ExeShortName + ' --help for more info.';

  ShortUsageStr :=
    ENDL +
    'Usage: ' + ExeShortName +
    ' -t=FILE -o=FILE [-d=STR] [-p=STR] [-s=STR] [-v=STR] [-h] [-V] [--home]' + ENDL +
    ENDL +
    'Mandatory arguments to long options are mandatory for short options too.' + ENDL +
    'Options are <color=cyan>case-sensitive</color>. Options in square brackets are optional.';

  ExtraInfoStr :=
    ENDL +
    'Exit codes:' + ENDL +
    '  ' + CON_EXIT_CODE_OK.ToString + ' - OK - no errors.' + ENDL +
    '  ' + CON_EXIT_CODE_SYNTAX_ERROR.ToString + ' - Syntax error.' + ENDL +
    '  ' + CON_EXIT_CODE_ERROR.ToString + ' - Other error.' + ENDL +
    ENDL +
    'You can use relative paths when specifying an input template file and an output DPK file. ' + ENDL +
    'If the output directory does not exist, it will be created automatically.';

  //------------------------------------------------------------------------------

  AppParams.TemplateFile := '';
  AppParams.PackageDescription := '';
end;
{$endregion Init}


{$region '                    Run                               '}
procedure TApp.Run;
begin
  inherited;

  RegisterOptions;
  Cmd.Parse;
  ProcessOptions;
  if Terminated then Exit;

  CreateDpkFile; // <----- the main procedure
end;
{$endregion Run}


{$region '                    RegisterOptions                   '}
procedure TApp.RegisterOptions;
const
  MAX_LINE_LEN = 120;
var
  Category: string;
begin

  Cmd.CommandLineParsingMode := cpmCustom;
  Cmd.UsageFormat := cufWget;


  // ------------ Registering command-line options -----------------

  Category := 'inout';

  Cmd.RegisterOption('t', 'template-file', cvtRequired, True, False, 'Template DPK file.', 'FILE', Category);
  Cmd.RegisterOption('o', 'output-file', cvtRequired, False, False, 'The output DPK file.', 'FILE', Category);

  Cmd.RegisterOption(
    'd', 'description', cvtRequired, False, False,
    'Package description. All instances of the text <color=yellow><DESCRIPTION></color> in the template file will be ' +
    'replaced by the string specified in this option.',
    'STR', Category
  );

  Cmd.RegisterOption(
    'p', 'lib-prefix', cvtRequired, False, False,
    'Library prefix. All instances of the text <color=yellow><LIBPREFIX></color> in the template file will be ' +
    'replaced by the string specified in this option.',
    'STR', Category
  );

  Cmd.RegisterOption(
    's', 'lib-suffix', cvtRequired, False, False,
    'Library suffix. All instances of the text <color=yellow><LIBSUFFIX></color> in the template file will be ' +
    'replaced by the string specified in this option.',
    'STR', Category
  );

  Cmd.RegisterOption(
    'v', 'lib-version', cvtRequired, False, False,
    'Library version. All instances of the text <color=yellow><LIBVERSION></color> in the template file will be ' +
    'replaced by the string specified in this option.',
    'STR', Category
  );

  Category := 'info';
  Cmd.RegisterOption('h', 'help', cvtNone, False, False, 'Show this help.', '', Category);
  Cmd.RegisterShortOption('?', cvtNone, False, True, '', '', '');
  Cmd.RegisterOption('V', 'version', cvtNone, False, False, 'Show application version.', '', Category);
  Cmd.RegisterLongOption('home', cvtNone, False, False, 'Opens program home page in the default browser.', '', Category);

  UsageStr :=
    ENDL +
    'Input/output:' + ENDL + Cmd.OptionsUsageStr('  ', 'inout', MAX_LINE_LEN, '  ', 30) + ENDL + ENDL +
    'Info:' + ENDL + Cmd.OptionsUsageStr('  ', 'info', MAX_LINE_LEN, '  ', 30);

end;
{$endregion RegisterOptions}


{$region '                    ProcessOptions                    '}
procedure TApp.ProcessOptions;
begin

  // ---------------------------- Invalid options -----------------------------------

  if Cmd.ErrorCount > 0 then
  begin
    DisplayShortUsageAndExit(Cmd.ErrorsStr, CON_EXIT_CODE_SYNTAX_ERROR);
    Exit;
  end;


  //------------------------------------ Help ---------------------------------------

  if (ParamCount = 0) or (Cmd.IsLongOptionExists('help')) or (Cmd.IsOptionExists('?')) then
  begin
    DisplayHelpAndExit(CON_EXIT_CODE_OK);
    Exit;
  end;


  //---------------------------------- Home -----------------------------------------

  if Cmd.IsLongOptionExists('home') then GoToHomePage; // and continue


  //------------------------------- Version ------------------------------------------

  if Cmd.IsOptionExists('version') then
  begin
    DisplayBannerAndExit(CON_EXIT_CODE_OK);
    Exit;
  end;


  //------------------------------- Template file ------------------------------------

  if not Cmd.IsOptionExists('t') then
  begin
    DisplayShortUsageAndExit('You must provide an input template file.', CON_EXIT_CODE_SYNTAX_ERROR);
    Exit;
  end
  else
  begin
    AppParams.TemplateFile := Trim(Cmd.GetOptionValue('t'));

    if AppParams.TemplateFile = '' then
    begin
      DisplayShortUsageAndExit('Invalid template file name.', CON_EXIT_CODE_SYNTAX_ERROR);
      Exit;
    end;

    AppParams.TemplateFile := ExpandFileName(AppParams.TemplateFile);

    if not FileExists(AppParams.TemplateFile) then
    begin
      DisplayShortUsageAndExit('Template file "' + AppParams.TemplateFile + '" does not exists!', CON_EXIT_CODE_ERROR);
      Exit;
    end;
  end;


  //----------------------------- Output DPK file ---------------------------------------

  if not Cmd.IsOptionExists('o') then
  begin
    DisplayShortUsageAndExit('You must provide an output DPK file name.', CON_EXIT_CODE_SYNTAX_ERROR);
    Exit;
  end
  else
    AppParams.OutputFile := Trim(Cmd.GetOptionValue('o'));

  if AppParams.OutputFile = '' then
  begin
    DisplayShortUsageAndExit('Invalid output DPK file name.', CON_EXIT_CODE_SYNTAX_ERROR);
    Exit;
  end;
  AppParams.OutputFile := ExpandFileName(AppParams.OutputFile);


  //--------------------------------- The Rest---------------------------------------

  if Cmd.IsOptionExists('d') then AppParams.PackageDescription := Cmd.GetOptionValue('d'); // Description
  if Cmd.IsOptionExists('p') then AppParams.LibPrefix := Cmd.GetOptionValue('p');          // Lib prefix
  if Cmd.IsOptionExists('s') then AppParams.LibSuffix := Cmd.GetOptionValue('s');          // Lib suffix
  if Cmd.IsOptionExists('v') then AppParams.LibVersion := Cmd.GetOptionValue('v');         // Lib version

end;


{$endregion ProcessOptions}


{$region '                    CreateDpkFile                     '}
procedure TApp.CreateDpkFile;
var
  OutDir, Text: string;
  sl: TStringList;
begin

  OutDir := ExtractFileDir(AppParams.OutputFile);
  if not DirectoryExists(OutDir) then ForceDirectories(OutDir);
  if not DirectoryExists(OutDir) then
  begin
    DisplayError('Cannot create output directory "' + OutDir + '"');
    ExitCode := CON_EXIT_CODE_ERROR;
    Exit;
  end;


  sl := TStringList.Create;
  try

    sl.LoadFromFile(AppParams.TemplateFile);
    Text := sl.Text;

    {if AppParams.PackageDescription <> '' then} Text := ReplaceAll(Text, '<DESCRIPTION>', AppParams.PackageDescription, True);
    {if AppParams.LibPrefix <> '' then} Text := ReplaceAll(Text, '<LIBPREFIX>', AppParams.LibPrefix, True);
    {if AppParams.LibSuffix <> '' then} Text := ReplaceAll(Text, '<LIBSUFFIX>', AppParams.LibSuffix, True);
    {if AppParams.LibVersion <> '' then} Text := ReplaceAll(Text, '<LIBVERSION>', AppParams.LibVersion, True);

    sl.Text := Text;
    try
      sl.SaveToFile(AppParams.OutputFile);
    except
      on E: Exception do
      begin
        Writeln('An error occurred while saving the output file "' + AppParams.OutputFile + '"');
        DisplayError('Error: ' + E.Message);
        Exit;
      end;
    end;

    Write('File saved: ');
    TConsole.WriteColoredTextLine(AppParams.OutputFile, TConsole.clLightGreenText, TConsole.clBlackBg);

  finally
    sl.Free;
  end;

end;
{$endregion CreateDpkFile}


{$region '                    Display... procs                  '}
procedure TApp.DisplayHelpAndExit(const ExCode: integer);
begin
  DisplayBanner;
  DisplayShortUsage;
  DisplayUsage;
  DisplayExtraInfo;
  ExitCode := ExCode;
  Terminate;
end;

procedure TApp.DisplayShortUsageAndExit(const Msg: string; const ExCode: integer);
begin
  if Msg <> '' then Writeln(Msg);
  DisplayShortUsage;
  DisplayTryHelp;
  ExitCode := ExCode;
  Terminate;
end;

procedure TApp.DisplayBannerAndExit(const ExCode: integer);
begin
  DisplayBanner;
  ExitCode := ExCode;
  Terminate;
end;

procedure TApp.DisplayMessageAndExit(const Msg: string; const ExCode: integer);
begin
  Writeln(Msg);
  ExitCode := ExCode;
  Terminate;
end;
{$endregion Display... procs}



end.
