{
	
	DESCRIPTION: Removes all records that do not contain the references of the Editor IDs in the sKeep list.
	
	== == == == == == == == == ==
	SCRIPT BY: David Richard (user: avidichard)
	== == == == == == == == == ==
}
unit RemoveAllRecordsExcept;

var
iItem: Integer;							// Current processed item
oFile: IInterface;					// Current file
iRecordCount: Integer;			// Total number of records to process
iRecCountLast: Integer;			// Total number of records in last master file
bHideMess: Boolean;					// If we should hide messages or not
iRecordDeleted: Integer;		// Total deleted records
iRecordKept: Integer;				// Total records kept
sFileName: String;					// Current file's name
bPerformActions: Boolean;		// If we perform the actual delete action on the records
sHeadSigCode: String;				// Signature that detects the File Header
sGroup: String;							// A special prefix to identify group names
iPerc: Double;							// Percentage done
sKeep: TStringList;					// Record types (Editor IDs) to keep (USER GENERATED)
sKeepFID: TStringList;			// List of all the Form IDs to keep automatically built from the sKeep list and their Referneces

procedure SetIDList;
	
	var
	ictr: integer;
	iref: Integer;
	irefCount: Integer;
	oRec: IInterface;
	oRefRec: IInterface;
	oGroup: IInterface;
	sCurGroup: String;
	sRefFID: String;
	iFormID: Cardinal;
	sFormID: String;
	
	begin
		sKeep := TStringList.Create;
		sKeepFID := TStringList.Create;
		sGroup := '~~DaRicXG~';	// DO NOT CHANGE THIS LINE
		// ====================
		// Add all of your EditorIDs to keep here. Copy this line below without the "//" and
		// insert your EditorID between the single quotes, Example: sKeep.Add('Your_EditorID_Here');
		// sKeep.Add('');
		
		// === sGroup lines ===
		// REQUIRED !!! This coresponds to the group name or (folder as I call them) in xEdit.
		// You put the name of that group and then all the .Add lines that follow should be the Editor IDs in that group.
		// You can add more than one sGroup as long as you follow it by the .Add of the Editor IDs in that group.
		// ====================
		// Check INITIALISATION after this function to set script values for testing or to trigger the perform actions
		// as well as hide or show progress messages.
		// ====================
		sKeep.Add(sGroup + 'TREE');
		sKeep.Add('Falkreath_TreePineForest01');
		sKeep.Add('Falkreath_TreePineForest01Dead');
		sKeep.Add('Falkreath_TreePineForest02');
		sKeep.Add('Falkreath_TreePineForest02Dead');
		sKeep.Add('Falkreath_TreePineForest03');
		sKeep.Add('Falkreath_TreePineForest03Dead');
		sKeep.Add('Falkreath_TreePineForest04');
		sKeep.Add('Falkreath_TreePineForest04Dead');
		sKeep.Add('Falkreath_TreePineForest05');
		sKeep.Add('Falkreath_TreePineForest05Dead');
		sKeep.Add('Falkreath_TreePineForestSnow01');
		sKeep.Add('Falkreath_TreePineForestSnow02');
		sKeep.Add('Falkreath_TreePineForestSnow02Dead');
		sKeep.Add('Falkreath_TreePineForestSnow03');
		sKeep.Add('Falkreath_TreePineForestSnow03Dead');
		sKeep.Add('Falkreath_TreePineForestSnow04');
		sKeep.Add('Falkreath_TreePineForestSnow04Dead');
		sKeep.Add('Falkreath_TreePineForestSnow05');
		sKeep.Add('Falkreath_TreePineForestSnow05Dead');
		sKeep.Add('Falkreath_TreePineForestSnowL01');
		sKeep.Add('Falkreath_TreePineForestSnowL01Dead');
		sKeep.Add('Falkreath_TreePineForestSnowL02');
		sKeep.Add('Falkreath_TreePineForestSnowL02Dead');
		sKeep.Add('Falkreath_TreePineForestSnowL03');
		sKeep.Add('Falkreath_TreePineForestSnowL03Dead');
		sKeep.Add('Falkreath_TreePineForestSnowL04');
		sKeep.Add('Falkreath_TreePineForestSnowL04Dead');
		sKeep.Add('Falkreath_TreePineForestSnowL05');
		sKeep.Add('Falkreath_TreePineForestSnowL05Dead');
		sKeep.Add('ArdbellOak01');
		sKeep.Add('ArdbellOak02');
		sKeep.Add('ArdbellOak03');
		sKeep.Add('MossyOak01');
		sKeep.Add('MossyOak02');
		sKeep.Add('RainOak01');
		sKeep.Add('RainOak02');
		sKeep.Add('RainOak03');
		sKeep.Add('RainOak04');
		sKeep.Add('RainOak05');
		sKeep.Add('RainOak06');
		sKeep.Add('RainOakBlue01');
		sKeep.Add('RainOakStubby01');
		sKeep.Add('TheArchwood');
		sKeep.Add('ThinOak01');
		sKeep.Add('ThinOak02');
		sKeep.Add('UnderOak01');
		sKeep.Add('UnderOak02');
		sKeep.Add('YharnaTree01');
		sKeep.Add('YharnaTree02');
		// ====================
		// END OF USER ADDED EDITOR IDs
		// ====================
		AddMessage('========== GENERATING FORM ID LIST FROM USER EDITOR ID LIST ==========');
		for ictr := 0 to sKeep.Count - 1 do begin
			// Get group name if necessary
			if Copy(sKeep[ictr],1,Length(sGroup)) = sGroup then begin
				sCurGroup := Copy(sKeep[ictr], Length(sGroup) + 1, Length(sKeep[ictr]) - Length(sGroup));
				oGroup := GroupBySignature(oFile, sCurGroup);
				if not bHideMess then AddMessage('--> BUILDING ID LIST FROM GROUP: ' + sCurGroup);
			end else begin
				// Get record
				oRec := MainRecordByEditorID(oGroup, sKeep[ictr]);
				if not bHideMess then AddMessage('--> CHECKING EDITOR ID: ' + sKeep[ictr]);
				// Get the FORM ID for later lookup
				iFormID := FixedFormID(oRec);
				sFormID := IntToHex(iFormID, 8);
				sFormID := Copy(sFormID, 3, 6);
				sFormID := UpperCase(sFormID);
				sKeepFID.Add(sFormID);
				if not bHideMess then AddMessage('   --> FORM ID: ' + sFormID);
				irefCount := ReferencedByCount(oRec);
				if not bHideMess then AddMessage('   --> TOTAL REFERENCED BY: ' + IntToStr(irefCount));
				if irefCount > 0 then begin
					// Loop all references
					for iref := 0 to irefCount - 1 do begin
						// Get referenced element
						oRefRec := ReferencedByIndex(oRec, iref);
						sRefFID := IntToHex(FixedFormID(oRefRec), 8);
						sRefFID := Copy(sRefFID, 3, 6);
						sRefFID := UpperCase(sRefFID);
						// Add referenced form id to the sRefs TSList
						if sKeepFID.IndexOf(sRefFID) < 0 then sKeepFID.Add(sRefFID);
					end;
				end;
			end;
			
		end;
		// Make sure there are no duplicates and sort the list for faster searching
		sKeepFID.Sort;
	end;

// Initialise variables (My programming background hyper-sensibility to make sure the values are at default)
function Initialize: integer;

	var
	oFilesSel: TStringList;	// List of selected files in xEdit's IDE

	begin
		AddMessage('========== INITIALISATION ==========');
		
		bPerformActions := false;		// <== To perform a test WITHOUT changing any records, set this to FALSE
		bHideMess := false;					// <== If you just want to see the results and not the entire list of records while processing, set this to TRUE
		sHeadSigCode := 'TES4';			// <== Depending on the game you use, you may change this to the File Header's --> Record Header's --> Signature
		
		iItem := 0;
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
		
		// Create the list of records to keep
		SetIDList;
		
		iRecordCount := RecordCount(oFile) + 1;
		
		AddMessage(' > NUMBER OF RECORDS TO PROCESS: ' + IntToStr(iRecordCount));
		AddMessage('========== PROCESSING RECORDS ==========');
		
		Result := 0;
		
	end;

function Process(oRecord: IInterface): Integer;
	
	var
	iFormID: Cardinal;			// Current form ID processed
	sFormID: String;				// String format of the form ID
	bRemove: Boolean;				// If record is to be removed or not
	
	begin
		
		bRemove := false;
		
		iItem := iItem + 1;
		iPerc := (iItem / iRecordCount) * 100;
		iPerc := Round(iPerc * 100) / 100;
		
		// Get current record Editor and Form IDs
		iFormID := FixedFormID(oRecord);
		sFormID := IntToHex(iFormID, 8);
		sFormID := Copy(sFormID, 3, 6);
		sFormID := UpperCase(sFormID);
		
		// ==========
		// Process records for comparison
		// ==========
		if not bHideMess then begin
			// Show current processed record
			AddMessage(FloatToStr(iPerc) + '% -> Processing record #' + IntToStr(iItem) + ' [' + sFormID +'] ' + Name(oRecord));
		end;
		
		// Make sure this is not the header record
		if not SameText(Signature(oRecord), sHeadSigCode) then begin
		
			// Check if form ID exists
			if sKeepFID.IndexOf(sFormID) < 0 then bRemove := true;
			
		end;
		
		// Remove record if needed
		if bRemove then begin
			// Remove record if we perform the actions
			if bPerformActions then Remove(oRecord);
			iRecordDeleted := iRecordDeleted + 1;
			if not bHideMess then AddMessage('   --> DELETED');
		end else begin
			// Record is kept, nothing happens, just a user message
			iRecordKept := iRecordKept + 1;
			if not bHideMess then AddMessage('   --> unchanged');
		end;
		
	end;

function Finalize: integer;

	begin
		// Free the TSList tables from memory
		sKeep.Free;
		sKeepFID.free;
		// Display results
		AddMessage('========== PROCESSING RESULTS ==========');
		if bPerformActions then begin
			AddMessage('LIVE: Changes have been made and records removed when necessary!');
		end else begin
			AddMessage('TEST: NO CHANGES were made. This was a test run.');
		end;
		AddMessage(' > PROCESSED FILE: ' + sFileName);
		AddMessage(' > UNCHANGED RECORDS: ' + IntToStr(iRecordKept));
		AddMessage(' > DELETED RECORDS: ' + IntToStr(iRecordDeleted));
		AddMessage(' > NUMBER OF RECORDS PROCESSED: ' + IntToStr(iItem));
		AddMessage('========== FINISHED PROCESSING RECORDS ==========');
		Result := 0;
	end;

end.
