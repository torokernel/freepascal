unit TestDBBasics;

{$IFDEF FPC}
  {$mode Delphi}{$H+}
{$ENDIF}

interface

uses
  fpcunit, testutils, testregistry, testdecorator,
  Classes, SysUtils, db;

type

  { TTestDBBasics }

  TTestDBBasics = class(TTestCase)
  private
    procedure TestOnFilterProc(DataSet: TDataSet; var Accept: Boolean);
    procedure TestfieldDefinition(AFieldType : TFieldType;ADatasize : integer;var ADS : TDataset; var AFld: TField);
    procedure TestcalculatedField_OnCalcfields(DataSet: TDataSet);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestIntFilter;
    procedure TestOnFilter;
    procedure TestStringFilter;

    procedure TestNullAtOpen;

    procedure TestSupportIntegerFields;
    procedure TestSupportSmallIntFields;
    procedure TestSupportStringFields;
    procedure TestSupportBooleanFields;
    procedure TestSupportFloatFields;
    procedure TestSupportLargeIntFields;
    procedure TestSupportDateFields;
    procedure TestSupportCurrencyFields;
    procedure TestSupportBCDFields;

    procedure TestIsEmpty;
    procedure TestAppendOnEmptyDataset;
    procedure TestInsertOnEmptyDataset;

    procedure TestBufDatasetCancelUpd; //bug 6938
    procedure TestEofAfterFirst;           //bug 7211
    procedure TestBufDatasetCancelUpd1;
    procedure TestDoubleClose;
    procedure TestCalculatedField;
    procedure TestAssignFieldftString;
    procedure TestAssignFieldftFixedChar;
    procedure TestSelectQueryBasics;
    procedure TestPostOnlyInEditState;
    procedure TestMove;                    // bug 5048
    procedure TestActiveBufferWhenClosed;
    procedure TestEOFBOFClosedDataset;
    procedure TestDataEventsResync;
    procedure TestBug7007;
    procedure TestBug6893;
    procedure TestRecordcountAfterReopen;  // partly bug 8228
    procedure TestdeFieldListChange;
    procedure TestLastAppendCancel;        // bug 5058
    procedure TestRecNo;                   // bug 5061
    procedure TestSetRecNo;                // bug 6919
    procedure TestRequired;
  end;

  { TSQLTestSetup }

  TDBBasicsTestSetup = class(TTestSetup)
  protected
    procedure OneTimeSetup; override;
    procedure OneTimeTearDown; override;
  end;

implementation

uses toolsunit, bufdataset;

type THackDataLink=class(TdataLink);

procedure TTestDBBasics.TestIsEmpty;
begin
  if not (DBConnector.GetNDataset(5) is TBufDataset) then
    Ignore('This test only applies to TBufDataset and descendents.');
  with tbufdataset(DBConnector.GetNDataset(True,1)) do
    begin
    open;
    delete;
    refresh;
    applyupdates;
    AssertTrue(IsEmpty);

    end;
end;

procedure TTestDBBasics.TestAppendOnEmptyDataset;
begin
  with DBConnector.GetNDataset(0) do
    begin
    open;
    AssertTrue(CanModify);
    AssertTrue(eof);
    AssertTrue(bof);
    append;
    AssertFalse(Bof);
    AssertTrue(Eof);
    post;
    AssertFalse(eof);
    AssertFalse(bof);
    end;
end;

procedure TTestDBBasics.TestInsertOnEmptyDataset;
begin
  with DBConnector.GetNDataset(0) do
    begin
    open;
    AssertTrue(CanModify);
    AssertTrue(eof);
    AssertTrue(bof);
    AssertTrue(IsEmpty);
    insert;
    AssertTrue(Bof);
    AssertTrue(Eof);
    AssertFalse(IsEmpty);
    post;
    AssertFalse(IsEmpty);
    AssertFalse(eof);
    AssertFalse(bof);
    end;
end;

procedure TTestDBBasics.TestSelectQueryBasics;
var b : TFieldType;
begin
  with DBConnector.GetNDataset(1) do
    begin
    Open;

    AssertEquals(1,RecNo);
    AssertEquals(1,RecordCount);

    AssertEquals(2,FieldCount);

    AssertTrue(CompareText('ID',fields[0].FieldName)=0);
    AssertTrue(CompareText('ID',fields[0].DisplayName)=0);
    AssertTrue('The datatype of the field ''ID'' is incorrect, it should be ftInteger',ftInteger=fields[0].DataType);

    AssertTrue(CompareText('NAME',fields[1].FieldName)=0);
    AssertTrue(CompareText('NAME',fields[1].DisplayName)=0);
    AssertTrue(ftString=fields[1].DataType);

    AssertEquals(1,fields[0].Value);
    AssertEquals('TestName1',fields[1].Value);

    Close;
    end;
end;

procedure TTestDBBasics.TestPostOnlyInEditState;
begin
  with DBConnector.GetNDataset(1) do
    begin
    open;
    AssertException('Post was called in a non-edit state',EDatabaseError,Post);
    end;
end;

procedure TTestDBBasics.TestMove;
var i,count      : integer;
    aDatasource  : TDataSource;
    aDatalink    : TDataLink;
    ABufferCount : Integer;

begin
  aDatasource := TDataSource.Create(nil);
  aDatalink := TTestDataLink.Create;
  aDatalink.DataSource := aDatasource;
  ABufferCount := 11;
  aDatalink.BufferCount := ABufferCount;
  DataEvents := '';
  for count := 0 to 32 do
    begin
    aDatasource.DataSet := DBConnector.GetNDataset(count);
    with aDatasource.Dataset do
      begin
      i := 1;
      Open;
      AssertEquals('deUpdateState:0;',DataEvents);
      DataEvents := '';
      while not EOF do
        begin
        AssertEquals(i,fields[0].AsInteger);
        AssertEquals('TestName'+inttostr(i),fields[1].AsString);
        inc(i);

        Next;
        if (i > ABufferCount) and not EOF then
          AssertEquals('deCheckBrowseMode:0;deDataSetScroll:-1;',DataEvents)
        else
          AssertEquals('deCheckBrowseMode:0;deDataSetScroll:0;',DataEvents);
        DataEvents := '';
        end;
      AssertEquals(count,i-1);
      close;
      AssertEquals('deUpdateState:0;',DataEvents);
      DataEvents := '';
      end;
    end;
end;

procedure TTestDBBasics.TestdeFieldListChange;

var i,count     : integer;
    aDatasource : TDataSource;
    aDatalink   : TDataLink;
    ds          : TDataset;

begin
  aDatasource := TDataSource.Create(nil);
  aDatalink := TTestDataLink.Create;
  aDatalink.DataSource := aDatasource;
  ds := DBConnector.GetNDataset(1);
  with ds do
    begin
    aDatasource.DataSet := ds;
    DataEvents := '';
    open;
    Fields.add(tfield.Create(DBConnector.GetNDataset(1)));
    AssertEquals('deUpdateState:0;deFieldListChange:0;',DataEvents);
    DataEvents := '';
    fields.Clear;
    AssertEquals('deFieldListChange:0;',DataEvents)
    end;
  aDatasource.Free;
  aDatalink.Free;
end;


procedure TTestDBBasics.TestActiveBufferWhenClosed;
begin
  with DBConnector.GetNDataset(0) do
    begin
    AssertNull(ActiveBuffer);
    open;
    AssertFalse('Activebuffer of an empty dataset shouldn''t be nil',ActiveBuffer = nil);
    end;
end;

procedure TTestDBBasics.TestEOFBOFClosedDataset;
begin
  with DBConnector.GetNDataset(1) do
    begin
    AssertTrue(EOF);
    AssertTrue(BOF);
    open;
    close;
    AssertTrue(EOF);
    AssertTrue(BOF);
    end;
end;

procedure TTestDBBasics.TestDataEventsResync;
var i,count     : integer;
    aDatasource : TDataSource;
    aDatalink   : TDataLink;
    ds          : tdataset;

begin
  aDatasource := TDataSource.Create(nil);
  aDatalink := TTestDataLink.Create;
  aDatalink.DataSource := aDatasource;
  ds := DBConnector.GetNDataset(6);
  ds.BeforeScroll := DBConnector.DataEvent;
  with ds do
    begin
    aDatasource.DataSet := ds;
    open;
    DataEvents := '';
    Resync([rmExact]);
    AssertEquals('deDataSetChange:0;',DataEvents);
    DataEvents := '';
    next;
    AssertEquals('deCheckBrowseMode:0;DataEvent;deDataSetScroll:0;',DataEvents);
    close;
    end;
  aDatasource.Free;
  aDatalink.Free;
end;

procedure TTestDBBasics.TestLastAppendCancel;

var count : integer;

begin
  for count := 0 to 32 do with DBConnector.GetNDataset(count) do
    begin
    open;

    Last;
    Append;
    Cancel;

    AssertEquals(count,fields[0].asinteger);
    AssertEquals(count,RecordCount);

    Close;

    end;
end;

procedure TTestDBBasics.TestRecNo;
var i       : longint;
    passed  : boolean;
begin
  with DBConnector.GetNDataset(0) do
    begin
    // Accessing RecNo on a closed dataset should raise an EDatabaseError or should
    // return 0
    passed := false;
    try
      i := recno;
    except on E: Exception do
      begin
      passed := E.classname = EDatabaseError.className
      end;
    end;
    if not passed then
      AssertEquals('Failed to get the RecNo from a closed dataset',0,RecNo);

    // Accessing Recordcount on a closed dataset should raise an EDatabaseError or should
    // return 0
    passed := false;
    try
      i := recordcount;
    except on E: Exception do
      begin
      passed := E.classname = EDatabaseError.className
      end;
    end;
    if not passed then
      AssertEquals('Failed to get the Recordcount from a closed dataset',0,RecNo);

    Open;

    AssertEquals(0,RecordCount);
    AssertEquals(0,RecNo);

    first;
    AssertEquals(0,RecordCount);
    AssertEquals(0,RecNo);

    last;
    AssertEquals(0,RecordCount);
    AssertEquals(0,RecNo);

    append;
    AssertEquals(0,RecNo);
    AssertEquals(0,RecordCount);

    first;
    AssertEquals(0,RecNo);
    AssertEquals(0,RecordCount);

    append;
    FieldByName('id').AsInteger := 1;
    AssertEquals(0,RecNo);
    AssertEquals(0,RecordCount);

    first;
    AssertEquals(1,RecNo);
    AssertEquals(1,RecordCount);

    last;
    AssertEquals(1,RecNo);
    AssertEquals(1,RecordCount);

    append;
    FieldByName('id').AsInteger := 1;
    AssertEquals(0,RecNo);
    AssertEquals(1,RecordCount);

    Close;
    end;
end;

procedure TTestDBBasics.TestSetRecNo;
begin
  with DBConnector.GetNDataset(15) do
    begin
    Open;
    RecNo := 1;
    AssertEquals(1,fields[0].AsInteger);
    AssertEquals(1,RecNo);

    RecNo := 2;
    AssertEquals(2,fields[0].AsInteger);
    AssertEquals(2,RecNo);

    RecNo := 8;
    AssertEquals(8,fields[0].AsInteger);
    AssertEquals(8,RecNo);

    RecNo := 15;
    AssertEquals(15,fields[0].AsInteger);
    AssertEquals(15,RecNo);

    RecNo := 3;
    AssertEquals(3,fields[0].AsInteger);
    AssertEquals(3,RecNo);

    RecNo := 14;
    AssertEquals(14,fields[0].AsInteger);
    AssertEquals(14,RecNo);

    RecNo := 15;
    AssertEquals(15,fields[0].AsInteger);
    AssertEquals(15,RecNo);

    // test for exceptions...
{    RecNo := 16;
    AssertEquals(15,fields[0].AsInteger);
    AssertEquals(15,RecNo);}

    Close;
    end;
end;

procedure TTestDBBasics.TestRequired;
begin
  with DBConnector.GetNDataset(2) do
    begin
    Open;
    FieldByName('ID').Required := True;
    Append;
    AssertException(EDatabaseError,Post);
    FieldByName('ID').AsInteger := 1000;
    Post;
    Close;
    end;
end;


procedure TTestDBBasics.SetUp;
begin
  DBConnector.StartTest;
end;

procedure TTestDBBasics.TearDown;
begin
  DBConnector.StopTest;
end;

procedure TTestDBBasics.TestOnFilterProc(DataSet: TDataSet; var Accept: Boolean);

var a : TDataSetState;
begin
  Accept := odd(Dataset.FieldByName('ID').AsInteger);
end;

procedure TTestDBBasics.TestOnFilter;
var tel : byte;
begin
  with DBConnector.GetNDataset(15) do
    begin
    OnFilterRecord := TestOnFilterProc;
    Filtered := True;
    Open;
    for tel := 1 to 8 do
      begin
      AssertTrue(odd(FieldByName('ID').asinteger));
      next;
      end;
    AssertTrue(EOF);
    end;
end;

procedure TTestDBBasics.TestIntFilter;
var tel : byte;
begin
  with DBConnector.GetNDataset(15) do
    begin
    Filtered := True;
    Filter := '(id>4) and (id<9)';
    Open;
    for tel := 5 to 8 do
      begin
      AssertEquals(tel,FieldByName('ID').asinteger);
      next;
      end;
    AssertTrue(EOF);
    Close;
    end;
end;

procedure TTestDBBasics.TestRecordcountAfterReopen;
var
  datalink1: tdatalink;
  datasource1: tdatasource;
  query1: TDataSet;

begin
  query1:= DBConnector.GetNDataset(11);
  datalink1:= TDataLink.create;
  datasource1:= tdatasource.create(nil);
  try
    datalink1.datasource:= datasource1;
    datasource1.dataset:= query1;

    query1.active := true;
    query1.active := False;
    AssertEquals(0, THackDataLink(datalink1).RecordCount);
    query1.active := true;
    AssertTrue(THackDataLink(datalink1).RecordCount>0);
    query1.active := false;
  finally
    datalink1.free;
    datasource1.free;
  end;
end;

procedure TTestDBBasics.TestStringFilter;
var tel : byte;
begin
  with DBConnector.GetNDataset(15) do
    begin
    Open;
    //FilterOptions := [foNoPartialCompare];
    //FilterOptions := [];
    Filter := '(name=''*Name3'')';
    Filtered := True;
    AssertFalse(EOF);
    AssertEquals(3,FieldByName('ID').asinteger);
    AssertEquals('TestName3',FieldByName('NAME').asstring);
    next;
    AssertTrue(EOF);
    Close;
    end;
end;

procedure TTestDBBasics.TestcalculatedField_OnCalcfields(DataSet: TDataSet);
begin
  case dataset.fieldbyname('ID').asinteger of
    1 : dataset.fieldbyname('CALCFLD').AsInteger := 5;
    2 : dataset.fieldbyname('CALCFLD').AsInteger := 70000;
    3 : dataset.fieldbyname('CALCFLD').Clear;
    4 : dataset.fieldbyname('CALCFLD').AsInteger := 1234;
    10 : dataset.fieldbyname('CALCFLD').Clear;
  else
    dataset.fieldbyname('CALCFLD').AsInteger := 1;
  end;
end;

procedure TTestDBBasics.TestCalculatedField;
var ds   : TDataset;
    AFld1, AFld2, AFld3 : Tfield;
begin
  ds := DBConnector.GetNDataset(5);
  with ds do
    begin
    AFld1 := TIntegerField.Create(ds);
    AFld1.FieldName := 'ID';
    AFld1.DataSet := ds;

    AFld2 := TStringField.Create(ds);
    AFld2.FieldName := 'NAME';
    AFld2.DataSet := ds;

    AFld3 := TIntegerField.Create(ds);
    AFld3.FieldName := 'CALCFLD';
    AFld3.DataSet := ds;
    Afld3.FieldKind := fkCalculated;

    AssertEquals(3,FieldCount);
    ds.OnCalcFields := TestcalculatedField_OnCalcfields;
    open;
    AssertEquals(1,FieldByName('ID').asinteger);
    AssertEquals(5,FieldByName('CALCFLD').asinteger);
    next;
    AssertEquals(70000,FieldByName('CALCFLD').asinteger);
    next;
    AssertEquals(true,FieldByName('CALCFLD').isnull);
    next;
    AssertEquals(1234,FieldByName('CALCFLD').AsInteger);
    edit;
    FieldByName('ID').AsInteger := 10;
    post;
    AssertEquals(true,FieldByName('CALCFLD').isnull);
    close;
    AFld1.Free;
    AFld2.Free;
    AFld3.Free;
    end;
end;

procedure TTestDBBasics.TestEofAfterFirst;
begin
  with DBConnector.GetNDataset(0) do
    begin
    open;
    AssertTrue(eof);
    AssertTrue(BOF);
    first;
    AssertTrue(eof);
    AssertTrue(BOF);
    end;
end;

procedure TTestDBBasics.TestfieldDefinition(AFieldType : TFieldType;ADatasize : integer;var ADS : TDataset; var AFld: TField);

var i          : byte;

begin
  ADS := DBConnector.GetFieldDataset;
  ADS.Open;

  AFld := ADS.FindField('F'+FieldTypeNames[AfieldType]);

  AssertNotNull('Fields of the type ' + FieldTypeNames[AfieldType] + ' are not supported by this type of dataset',AFld);
  AssertTrue(Afld.DataType = AFieldType);
  AssertEquals(ADatasize,Afld.DataSize );
end;

procedure TTestDBBasics.TestSupportIntegerFields;

var i          : byte;
    ds         : TDataset;
    Fld        : TField;

begin
  TestfieldDefinition(ftInteger,4,ds,Fld);

  for i := 0 to testValuesCount-1 do
    begin
    AssertEquals(testIntValues[i],Fld.AsInteger);
    ds.Next;
    end;
  ds.close;
end;

procedure TTestDBBasics.TestSupportSmallIntFields;

var i          : byte;
    ds         : TDataset;
    Fld        : TField;

begin
  TestfieldDefinition(ftSmallint,2,ds,Fld);

  for i := 0 to testValuesCount-1 do
    begin
    AssertEquals(testSmallIntValues[i],Fld.AsInteger);
    ds.Next;
    end;
  ds.close;
end;


procedure TTestDBBasics.TestSupportStringFields;

var i          : byte;
    ds         : TDataset;
    Fld        : TField;

begin
  TestfieldDefinition(ftString,11,ds,Fld);

  for i := 0 to testValuesCount-1 do
    begin
    AssertEquals(testStringValues[i],Fld.AsString);
    ds.Next;
    end;
  ds.close;
end;

procedure TTestDBBasics.TestSupportBooleanFields;

var i          : byte;
    ds         : TDataset;
    Fld        : TField;

begin
  TestfieldDefinition(ftBoolean,2,ds,Fld);

  for i := 0 to testValuesCount-1 do
    begin
    AssertEquals(testBooleanValues[i],Fld.AsBoolean);
    ds.Next;
    end;
  ds.close;
end;

procedure TTestDBBasics.TestSupportFloatFields;

var i          : byte;
    ds         : TDataset;
    Fld        : TField;

begin
  TestfieldDefinition(ftFloat,8,ds,Fld);

  for i := 0 to testValuesCount-1 do
    begin
    AssertEquals(testFloatValues[i],Fld.AsFloat);
    ds.Next;
    end;
  ds.close;
end;

procedure TTestDBBasics.TestSupportLargeIntFields;

var i          : byte;
    ds         : TDataset;
    Fld        : TField;

begin
  TestfieldDefinition(ftLargeint,8,ds,Fld);

  for i := 0 to testValuesCount-1 do
    begin
    AssertEquals(testLargeIntValues[i],Fld.AsLargeInt);
    ds.Next;
    end;
  ds.close;
end;

procedure TTestDBBasics.TestSupportDateFields;

var i          : byte;
    ds         : TDataset;
    Fld        : TField;

begin
  TestfieldDefinition(ftDate,8,ds,Fld);

  for i := 0 to testValuesCount-1 do
    begin
    AssertEquals(testDateValues[i],FormatDateTime('yyyy/mm/dd',Fld.AsDateTime));
    ds.Next;
    end;
  ds.close;
end;

procedure TTestDBBasics.TestSupportCurrencyFields;

var i          : byte;
    ds         : TDataset;
    Fld        : TField;

begin
  TestfieldDefinition(ftCurrency,8,ds,Fld);

  for i := 0 to testValuesCount-1 do
    begin
    AssertEquals(testCurrencyValues[i],Fld.AsCurrency);
    AssertEquals(testCurrencyValues[i],Fld.AsFloat);
    ds.Next;
    end;
  ds.close;
end;

procedure TTestDBBasics.TestSupportBCDFields;

var i          : byte;
    ds         : TDataset;
    Fld        : TField;

begin
  TestfieldDefinition(ftBCD,8,ds,Fld);

  for i := 0 to testValuesCount-1 do
    begin
    AssertEquals(testCurrencyValues[i],Fld.AsCurrency);
    AssertEquals(testCurrencyValues[i],Fld.AsFloat);
    ds.Next;
    end;
  ds.close;
end;

procedure TTestDBBasics.TestDoubleClose;
begin
  with DBConnector.GetNDataset(1) do
    begin
    close;
    close;
    open;
    close;
    close;
    end;
end;

procedure TTestDBBasics.TestAssignFieldftString;
var AParam : TParam;
    AField : TField;
begin
  AParam := TParam.Create(nil);

  with DBConnector.GetNDataset(1) do
    begin
    open;
    AField := fieldbyname('name');
    AParam.AssignField(AField);
    AssertTrue(ftString=AParam.DataType);
    close;
    end;
  AParam.Free;
end;

procedure TTestDBBasics.TestAssignFieldftFixedChar;
var AParam : TParam;
    AField : TField;
begin
  AParam := TParam.Create(nil);
  with DBConnector.GetNDataset(1) do
    begin
    open;
    AField := fieldbyname('name');
    (AField as tstringfield).FixedChar := true;
    AParam.AssignField(AField);
    AssertTrue(ftFixedChar=AParam.DataType);
    close;
    end;
  AParam.Free;
end;

procedure TTestDBBasics.TestBufDatasetCancelUpd;
var i : byte;
begin
  if not (DBConnector.GetNDataset(5) is TBufDataset) then
    Ignore('This test only applies to TBufDataset and descendents.');
  with DBConnector.GetNDataset(5) as TBufDataset do
    begin
    open;
    next;
    next;

    edit;
    FieldByName('name').AsString := 'changed';
    post;
    next;
    delete;
    
    CancelUpdates;

    First;

    for i := 1 to 5 do
      begin
      AssertEquals(i,fields[0].AsInteger);
      AssertEquals('TestName'+inttostr(i),fields[1].AsString);
      Next;
      end;
    end;
end;

procedure TTestDBBasics.Testbug7007;

var
  datalink1: tdatalink;
  datasource1: tdatasource;
  query1: TDataSet;

begin
  query1:= DBConnector.GetNDataset(6);
  datalink1:= TTestDataLink.create;
  datasource1:= tdatasource.create(nil);
  try
    datalink1.datasource:= datasource1;
    datasource1.dataset:= query1;
    datalink1.datasource:= datasource1;

    DataEvents := '';
    query1.open;
    datalink1.buffercount:= query1.recordcount;
    AssertEquals('deUpdateState:0;',DataEvents);
    AssertEquals(0, datalink1.ActiveRecord);
    AssertEquals(6, datalink1.RecordCount);
    AssertEquals(6, query1.RecordCount);
    AssertEquals(1, query1.RecNo);

    DataEvents := '';
    query1.append;
    AssertEquals('deCheckBrowseMode:0;deUpdateState:0;deDataSetChange:0;',DataEvents);
    AssertEquals(5, datalink1.ActiveRecord);
    AssertEquals(6, datalink1.RecordCount);
    AssertEquals(6, query1.RecordCount);
    AssertTrue(query1.RecNo in [0,7]);

    DataEvents := '';
    query1.cancel;
    AssertEquals('deCheckBrowseMode:0;deUpdateState:0;deDataSetChange:0;',DataEvents);
    AssertEquals(5, datalink1.ActiveRecord);
    AssertEquals(6, datalink1.RecordCount);
    AssertEquals(6, query1.RecordCount);
    AssertEquals(6, query1.RecNo);
  finally
    datalink1.free;
    datasource1.free;
  end;
end;

procedure TTestDBBasics.TestBug6893;
var
  datalink1: tdatalink;
  datasource1: tdatasource;
  query1: TDataSet;

begin
  query1:= DBConnector.GetNDataset(25);
  datalink1:= TDataLink.create;
  datasource1:= tdatasource.create(nil);
  try
    datalink1.datasource:= datasource1;
    datasource1.dataset:= query1;

    datalink1.buffercount:= 5;
    query1.active := true;
    query1.MoveBy(20);

    AssertEquals(5, THackDataLink(datalink1).Firstrecord);
    AssertEquals(4, datalink1.ActiveRecord);
    AssertEquals(21, query1.RecNo);

    query1.active := False;

    AssertEquals(0, THackDataLink(datalink1).Firstrecord);
    AssertEquals(0, datalink1.ActiveRecord);

    query1.active := true;

    AssertEquals(0, THackDataLink(datalink1).Firstrecord);
    AssertEquals(0, datalink1.ActiveRecord);
    AssertEquals(1, query1.RecNo);
    
  finally
    datalink1.free;
    datasource1.free;
  end;
end;

procedure TTestDBBasics.TestBufDatasetCancelUpd1;
var i : byte;
begin
  if not (DBConnector.GetNDataset(5) is TBufDataset) then
    Ignore('This test only applies to TBufDataset and descendents.');
  with DBConnector.GetNDataset(5) as TBufDataset do
    begin
    open;
    next;
    next;

    delete;
    insert;
    FieldByName('id').AsInteger := 100;
    post;

    CancelUpdates;

    last;

    for i := 5 downto 1 do
      begin
      AssertEquals(i,fields[0].AsInteger);
      AssertEquals('TestName'+inttostr(i),fields[1].AsString);
      Prior;
      end;
    end;
end;

procedure TTestDBBasics.TestNullAtOpen;
begin
  with dbconnector.getndataset(0) do
    begin
    active:= true;
    AssertTrue('Field isn''t NULL on a just-opened empty dataset',fieldbyname('id').IsNull);
    append;
    AssertTrue('Field isn''t NULL after append on an empty dataset',fieldbyname('id').IsNull);
    fieldbyname('id').asinteger:= 123;
    cancel;
    AssertTrue('Field isn''t NULL after cancel',fieldbyname('id').IsNull);
    end;

end;

{ TSQLTestSetup }
procedure TDBBasicsTestSetup.OneTimeSetup;
begin
  InitialiseDBConnector;
end;

procedure TDBBasicsTestSetup.OneTimeTearDown;
begin
  FreeAndNil(DBConnector);
end;

initialization
  RegisterTestDecorator(TDBBasicsTestSetup, TTestDBBasics);
end.
