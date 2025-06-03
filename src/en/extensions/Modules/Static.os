// Get file from folder
//
// Parameters:
// Directory - String - Folder path - catalog
// FileName - String - File name with extension - file
//
// Returns:
// Structure Of KeyAndValue, BinaryData - file data or error info
Function GetFileFromFolder(Val Directory, Val FileName) Export

	Directory = StrReplace(Directory, "\", "/");
	Directory = ?(StrEndsWith(Directory, "/"), Directory, Directory + "/");

	FullPath = Directory + FileName;
	PathFile = New File(FullPath);

	If Not PathFile.Exist() Then
		Return New Structure("result,error", False, "Not Found");
	Else
		Return New BinaryData(FullPath);
	EndIf;

EndFunction
