{
	
	DESCRIPTION: Keeps all records that are present in the last master from your masters list.
	
	USE CASE SCENARIO: Example: Create a patch-mod to revert some of another mod's changes back to a master's records.
	
	== == == == == == == == == ==
	SCRIPT BY: David Richard (user: avidichard)
	== == == == == == == == == ==
}
unit RemoveUnusedRecordsFromLastMaster;

var
iItem: Integer;							// Current processed item
iRecordCount: Integer;			// Total number of records to process
iRecCountLast: Integer;			// Total number of records in last master file
iMasterCount: Integer;			// Number of masters in current file
iMasterLast: Integer;				// Index of last master of the file
oLastMaster: IInterface;		// Object reference of last Master file
bHideMess: Boolean;					// If we should hide messages or not
iRecordDeleted: Integer;		// Total deleted records
iRecordKept: Integer;				// Total records kept
sLastMasterName: String;		// Name of the last master file
sFileName: String;					// Current file's name
bPerformActions: Boolean;		// If we perform the actual delete action on the records
sHeadSigCode: String;				// Signature that detects the File Header
iPerc: Double;							// Percentage done

// Initialise variables (My programming background hyper-sensibility to make sure the values are at default)
function Initialize: integer;

	var
	oFile: IInterface;			// Currewnt file object to get basic information
	oFilesSel: TStringList;	// List of selected files in xEdit's IDE

	begin
		AddMessage('========== INITIALISATION ==========');
		
		bPerformActions := true;		// <== To perform a test WITHOUT changing any records, set this to FALSE
		bHideMess := false;					// <== If you just want to see the results and not the entire list of records while processing, set this to TRUE
		sHeadSigCode := 'TES4';			// <== Depending on the game you use, you may change this to the File Header's --> Record Header's --> Signature
		
		iItem := 0;
		iMasterLast := -1;
		iMasterCount := 0;
		iRecordDeleted := 0;
		iRecordKept := 0;
		iPerc := 0;
		
		// Check if more than 1 file has been selected and abort if it's the case
		oFilesSel := TStringList.Create;
		wbSelectedFilesToFileNames(oFilesSel);
		
		if oFilesSel.Count > 1 then begin
			oFilesSel.free;
			AddMessage('========== EXECUTION ABORTED ==========');
			raise Exception.Create('MULTIPLE FILES SELECTED: Too many files selected. Select 1 single file only.');
		end;
		
		// Get file information
		sFileName := oFilesSel[0];
		oFilesSel.free;
		
		AddMessage(' > PROCESSING FILE: ' + sFileName);
		
		oFile := FileByName(sFileName);
		iMasterCount := MasterCount(oFile);
		
		// Abort if there are no masters
		if iMasterCount = 0 then begin
			AddMessage('========== EXECUTION ABORTED ==========');
			raise Exception.Create('NO MASTERS FOUND: File must contain at least 1 master and this file contains no masters.');
		end;
		
		iMasterLast := iMasterCount - 1;
		oLastMaster := MasterByIndex(oFile, iMasterLast);
		iRecordCount := RecordCount(oFile) + 1;
		sLastMasterName := GetFileName(oLastMaster);
		iRecCountLast := RecordCount(oLastMaster) + 1;
		
		AddMessage(' > NUMBER OF MASTERS: ' + IntToStr(iMasterCount));
		AddMessage(' > LAST MASTER: ' + sLastMasterName);
		AddMessage(' > NUMBER OF RECORDS TO PROCESS: ' + IntToStr(iRecordCount));
		AddMessage('========== PROCESSING RECORDS ==========');
		
		Result := 0;
		
	end;

function Process(oRecord: IInterface): Integer;
	
	var
	oRecLast: IInterface;		// Record in the last master
	iFormID: Cardinal;			// Current form ID processed
	iLastFormID: Cardinal;	// Form ID found in the last master
	sFormID: String;				// String format of the form ID
	oCurRec: IInterface;		// Current record being checked
	
	begin
		
		iItem := iItem + 1;
		iPerc := (iItem / iRecordCount) * 100;
		iPerc := Round(iPerc * 100) / 100;
		iLastFormID := $FFFFFFFF;
		
		// Get current record FOrmID
		iFormID := FixedFormID(oRecord);
		sFormID := IntToHex(iFormID, 8);
		
		// ==========
		// Process records for comparison
		// ==========
		if bHideMess = false then begin
			// Show current processed record
			AddMessage(FloatToStr(iPerc) + '% -> Processing record #' + IntToStr(iItem) + ' [' + sFormID +'] ' + Name(oRecord));
		end;
		
		// Search for current FormID in last master's records
		oRecLast :=  RecordByFormID(oLastMaster,iFormID, false);
		
		// Check the last record's file name to make sure it's the same as the file we are targeting
		if SameText(GetFileName(oRecLast), sLastMasterName) = true then begin
			iLastFormID := FixedFormID(oRecLast);
		end;
		
		// Make sure this is not the header record
		if UpperCase(Signature(oRecord)) = sHeadSigCode then begin
			iLastFormID := iFormID;
		end;
		
		// Check if we have a matching form ID (meaning, the entry exists in the last master file)
		if iFormID = iLastFormID then begin
			iRecordKept := iRecordKept + 1;
			if bHideMess = false then begin
				AddMessage('   --> unchanged');
			end;
		end else begin
			// Actually delete record if actions need to be performed
			if bPerformActions = true then begin
				Remove(oRecord);
			end;
			iRecordDeleted := iRecordDeleted + 1;
			if bHideMess = false then begin
				AddMessage('   --> DELETED');
			end;
		end;
		
	end;

function Finalize: integer;

	begin
		AddMessage('========== PROCESSING RESULTS ==========');
		if bPerformActions = true then begin
			AddMessage('LIVE: Changes have been made and records removed when necessary!');
		end else begin
			AddMessage('TEST: NO CHANGES were made. This was a test run.');
		end;
		AddMessage(' > PROCESSED FILE: ' + sFileName);
		AddMessage(' > LAST MASTER USED: ' + sLastMasterName);
		AddMessage(' > NUMBER OF RECORDS IN LAST MASTER: ' + IntToStr(iRecCountLast));
		AddMessage(' > UNCHANGED RECORDS: ' + IntToStr(iRecordKept));
		AddMessage(' > DELETED RECORDS: ' + IntToStr(iRecordDeleted));
		AddMessage(' > NUMBER OF RECORDS PROCESSED: ' + IntToStr(iItem));
		AddMessage('========== FINISHED PROCESSING RECORDS ==========');
		Result := 0;
	end;

end.
