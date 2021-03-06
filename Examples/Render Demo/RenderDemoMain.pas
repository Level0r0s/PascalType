unit RenderDemoMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, PT_Types, PT_Classes, PT_Tables, PT_Storage,
  PT_StorageSFNT, PT_FontEngineGDI, PT_Windows, RenderDemoFontNameScanner;

{$I ..\..\Source\PT_Compiler.inc}  

type
  TFontNameFile = packed record
    FullFontName : string;
    FileName     : TFileName;
  end;

  TFmRenderDemo = class(TForm)
    ComboBoxFont: TComboBox;
    ComboBoxFontSize: TComboBox;
    EditText: TEdit;
    LabelFont: TLabel;
    LabelFontSize: TLabel;
    LabelFontEngine: TLabel;
    LabelText: TLabel;
    PaintBox: TPaintBox;
    PanelText: TPanel;
    RadioButtonPascalType: TRadioButton;
    RadioButtonWindows: TRadioButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ComboBoxFontChange(Sender: TObject);
    procedure ComboBoxFontSizeChange(Sender: TObject);
    procedure EditTextChange(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject);
    procedure PanelTextResize(Sender: TObject);
    procedure RadioButtonPascalTypeClick(Sender: TObject);
    procedure RadioButtonWindowsClick(Sender: TObject);
  private
    FFontEngine  : TPascalTypeFontEngineGDI;
    FFontScanner : TFontNameStorageScan;
    FFontArray   : array of TFontNameFile;
    FBitmap      : TBitmap;
    FText        : string;
    FFontSize    : Integer;
    FFontName    : string;
    procedure FontScannedHandler(Sender: TObject; FontFileName: TFilename;
      Font: TCustomPascalTypeStorage);
    procedure SetText(const Value: string);
    procedure SetFontSize(const Value: Integer);
    procedure SetFontName(const Value: string);
  protected
    procedure FontNameChanged; virtual;
    procedure FontSizeChanged; virtual;
    procedure RenderText; virtual;
    procedure TextChanged; virtual;
  public
    property Text: string read FText write SetText;
    property FontSize: Integer read FFontSize write SetFontSize;
    property FontName: string read FFontName write SetFontName;
  end;

var
  FmRenderDemo: TFmRenderDemo;

implementation

{$R *.dfm}

uses
  Math, Types;

procedure TFmRenderDemo.FormCreate(Sender: TObject);
begin
 SetCurrentDir(GetFontDirectory);

 // create bitmap buffer
 FBitmap := TBitmap.Create;

 // create FontEngine
 FFontEngine := TPascalTypeFontEngineGDI.Create;

 // set initial properties
 FBitmap.Canvas.Font.Size := StrToInt(ComboBoxFontSize.Text);
 FFontEngine.FontSize := StrToInt(ComboBoxFontSize.Text);

 FFontScanner := TFontNameStorageScan.Create(True);
 with FFontScanner do
  begin
   OnFontScanned := FontScannedHandler;
   Resume;
  end;
end;

procedure TFmRenderDemo.FormDestroy(Sender: TObject);
begin
 // free FontEngine
 FreeAndNil(FFontEngine);

 with FFontScanner do
  begin
   Terminate;
   WaitFor;
  end;
 FreeAndNil(FFontScanner);
end;

procedure TFmRenderDemo.FormShow(Sender: TObject);
begin
 Text := EditText.Text;
end;

procedure TFmRenderDemo.PaintBoxPaint(Sender: TObject);
begin
 if Assigned(FBitmap)
  then PaintBox.Canvas.Draw(0, 0, FBitmap);
end;

procedure TFmRenderDemo.PanelTextResize(Sender: TObject);
begin
 if Assigned(FBitmap) then
  with FBitmap do
   begin
    Width := PaintBox.Width;
    Height := PaintBox.Height;
   end;
end;

procedure TFmRenderDemo.TextChanged;
begin
 RenderText;
end;

procedure TFmRenderDemo.FontNameChanged;
var
  FontIndex : Integer;
begin
 FBitmap.Canvas.Font.Name := FFontName;
 for FontIndex := 0 to Length(FFontArray) - 1 do
  if FFontArray[FontIndex].FullFontName = FFontName then
   begin
    FFontEngine.LoadFromFile(FFontArray[FontIndex].FileName);
    Break;
   end;

 RenderText;
end;

procedure TFmRenderDemo.FontSizeChanged;
begin
 FBitmap.Canvas.Font.Size := FFontSize;
 FFontEngine.FontSize := FFontSize;
 RenderText;
end;

procedure TFmRenderDemo.RadioButtonPascalTypeClick(Sender: TObject);
begin
 RenderText;
end;

procedure TFmRenderDemo.RadioButtonWindowsClick(Sender: TObject);
begin
 RenderText;
end;

procedure TFmRenderDemo.RenderText;
begin
 with FBitmap, Canvas do
  begin
   // clear bitmap
   Brush.Color := clWhite;
   FillRect(ClipRect);

   if RadioButtonWindows.Checked then
    begin
     with Font do
      begin
       Color := clBlack;
       Name := ComboBoxFont.Text;
      end;

     TextOut(0, 0, FText);
    end;

   if RadioButtonPascalType.Checked
    then FFontEngine.RenderText(FText, Canvas, 0, 0);
  end;
 PaintBox.Invalidate;
end;

procedure TFmRenderDemo.SetFontName(const Value: string);
begin
 if FFontName <> Value then
  begin
   FFontName := Value;
   FontNameChanged;
  end;
end;

procedure TFmRenderDemo.SetFontSize(const Value: Integer);
begin
 if FFontSize <> Value then
  begin
   FFontSize := Value;
   FontSizeChanged;
  end;
end;

procedure TFmRenderDemo.SetText(const Value: string);
begin
 if FText <> Value then
  begin
   FText := Value;
   TextChanged;
  end;
end;

procedure TFmRenderDemo.ComboBoxFontChange(Sender: TObject);
begin
 if (ComboBoxFont.ItemIndex >= 0) and (ComboBoxFont.ItemIndex < Length(FFontArray)) then
  with FFontArray[ComboBoxFont.ItemIndex]
   do Self.FontName := FontName;
end;

procedure TFmRenderDemo.ComboBoxFontSizeChange(Sender: TObject);
begin
 FontSize := StrToInt(ComboBoxFontSize.Text);
end;

procedure TFmRenderDemo.EditTextChange(Sender: TObject);
begin
 Text := EditText.Text;
end;

procedure TFmRenderDemo.FontScannedHandler(Sender: TObject; FontFileName: TFilename;
  Font: TCustomPascalTypeStorage);
var
  CurrentFontName : string;
begin
 // add font name to font combo box
 CurrentFontName := TCustomPascalTypeStorageSFNT(Font).FontName;
 ComboBoxFont.Items.Add(CurrentFontName);

 SetLength(FFontArray, Length(FFontArray) + 1);
 with FFontArray[Length(FFontArray) - 1] do
  begin
   FullFontName := CurrentFontName;
   FileName := FontFileName;
  end;

 // check if current font is the one requested
 if CurrentFontName = 'Arial' then
  begin
   ComboBoxFont.ItemIndex := ComboBoxFont.Items.Count - 1;
   FontName := CurrentFontName;
  end;
end;

end.
