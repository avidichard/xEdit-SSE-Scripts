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

// Gets a record's path without all of the extra information (as you would see it in the xEdit interface)
function GetRecordPath(objectRecord: IInterface): TStringList;
	var
	ooPath: TStringList;
	soPath: String;
	stPath: String;
	ipos: Integer;
	iPos2: Integer;
	sText: String;
	bLoop: Boolean;
	
	begin
		ooPath := TStringList.Create;
		soPath := PathName(objectRecord);
		
		bLoop := true;
		iPos := Pos('\', soPath);
		if iPos = 0 then bLoop := false;
		while bLoop do begin
			if iPos = 0 then begin
				bLoop := false;
				stPath := Trim(soPath);
			end else begin
				stPath := Copy(soPath, 1, iPos - 1);
				stPath := Trim(stPath);
			end;
			// Only add to the path list if there's a name
			// Usually, this should only apply to the first entry
			if Length(stPath) > 0 then begin
				// Trim extra uneeded information
				// This is the initial index value
				iPos2 := Pos(']', stPath);
				stPath := Copy(stPath, iPos2 + 1, Length(stPath) - iPos2);
				stPath := Trim(stPath);
				// Any "Children of" is removed also
				sText := 'CHILDREN OF';
				iPos2 := Pos(sText, UpperCase(stPath));
				if (iPos2 > 0) then begin
					iPos2 := iPos2 + Length(sText);
					stPath := Copy(stPath, iPos2 + 1, Length(stPath) - iPos2);
					stPath := Trim(stPath);
				end;
				// Trim down extra possible information, usually last record in the path such as [REFR:00000000]
				// This is usually the actual record so it's always going to be 8 characters long (Form ID length)
				iPos2 := Pos(':', stPath);
				if iPos2 > 0 then stPath := Copy(stPath, iPos2 + 1, 8);
				// Finally, check if this last part is a HEX number, basically, a Form ID
				if Length(stPath) = 8 then begin
					if StrToInt64Def('$' + stPath, -1) >= 0 then stPath := 'fid:' + UpperCase(stPath);
				end;
				ooPath.Add(stPath);
			end;
			// Get next container/group/folder in the path
			soPath := Copy(soPath, iPos + 1, Length(soPath) - ipos);
			iPos := Pos('\', soPath);
			
		end;
		
		Result := ooPath;
	end;

procedure SetIDList;
	
	var
	ictr: integer;
	iref: Integer;
	iPath: Integer;
	ipos: Integer;
	irefCount: Integer;
	oRec: IInterface;
	oRefRec: IInterface;
	oGroup: IInterface;
	sCurGroup: String;
	sRefFID: String;
	iFormID: Cardinal;
	sFormID: String;
	soPath: TStringList;
	spRec: String;
	sFullPath: String;
	
	begin
		sKeep := TStringList.Create;
		sKeepFID := TStringList.Create;
		sGroup := '~~DaRicXG~';	// DO NOT CHANGE THIS LINE
		soPath := TStringList.Create;
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
		// The following are examples, replace to match your needs
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
		// ====================
		// END OF USER ADDED EDITOR IDs
		// ====================
		AddMessage('========== PLEASE WAIT... GENERATING LIST OF RECORDS TO KEEP ==========');
		for ictr := 0 to sKeep.Count - 1 do begin
			// Get group name if necessary
			if Copy(sKeep[ictr],1,Length(sGroup)) = sGroup then begin
				sCurGroup := Copy(sKeep[ictr], Length(sGroup) + 1, Length(sKeep[ictr]) - Length(sGroup));
				oGroup := GroupBySignature(oFile, sCurGroup);
			end else begin
				// Get record
				oRec := MainRecordByEditorID(oGroup, sKeep[ictr]);
				// Get the FORM ID for later lookup
				iFormID := FixedFormID(oRec);
				sFormID := IntToHex(iFormID, 8);
				sFormID := Copy(sFormID, 3, 6);
				sFormID := UpperCase(sFormID);
				if not bHideMess then AddMessage(' > KEEP REC: ' + sFormID);
				sKeepFID.Add(sFormID);
				irefCount := ReferencedByCount(oRec);
				// Loop all references if any
				if irefCount > 0 then begin	
					for iref := 0 to irefCount - 1 do begin
						// Get referenced element
						oRefRec := ReferencedByIndex(oRec, iref);
						sRefFID := IntToHex(FixedFormID(oRefRec), 8);
						sRefFID := Copy(sRefFID, 3, 6);
						sRefFID := UpperCase(sRefFID);
						// Add referenced form id to the sRefs TSList
						if not bHideMess then AddMessage(' > KEEP REF: ' + sRefFID);
						if sKeepFID.IndexOf(sRefFID) < 0 then sKeepFID.Add(sRefFID);
						
						// Get full path of element
						soPath := GetRecordPath(oRefRec);
						// Keep records that have form ids and put them in the list of items to keep
						if soPath.Count > 0 then begin
							sFullPath := '';
							for iPath := 0 to soPath.Count - 1 do begin
								sFullPath := sFullPath + '\' + soPath[iPath];
								iPos := Pos('fid:', soPath[iPath]);
								if iPos > 0 then begin
									if not bHideMess then AddMessage(' > KEEP GRP: ' + soPath[iPath]);
									spRec := Copy(soPath[iPath], 7, 6);
									if sKeepFID.IndexOf(spRec) < 0 then sKeepFID.Add(spRec);
								end;
							end;
							if not bHideMess then AddMessage(' > FULL PATH: ' + sFullPath);
						end else begin
							if not bHideMess then AddMessage(' > EMPTY PATH OR ROOT');
						end;
						soPath.Free;
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
		
		bPerformActions := true;		// <== To perform a test WITHOUT changing any records, set this to FALSE
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
		
		// Make sure this is not the header record or a GRUP (a folder)
		if (not SameText(Signature(oRecord), sHeadSigCode) AND not SameText(Signature(oRecord), 'GRUP')) then begin
		
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
