unit DPKG.Types;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface


type

  TAppParams = record
    TemplateFile: string;        // -t, --template
    PackageDescription: string;  // -d, --description
    LibPrefix: string;           // -p, --lib-prefix
    LibSuffix: string;           // -s, --lib-suffix
    LibVersion: string;          // -v, --lib-version
    OutputFile: string;          // -o, --output-file
  end;

  
implementation

end.
