// Get file from folder
//
// Parameters:
// Directory - String - Folder path - catalog
// FileName - String - File name with extension - file
// MIME - String - MIME type - mime
// Context - HTTPContext - Request context - melezhcontext
//
// Returns:
// Structure Of KeyAndValue, BinaryData - file data or error info
Function GetFileFromFolder(Val Directory, Val FileName, Val MIME, Val Context) Export

	Directory = StrReplace(Directory, "\", "/");
	Directory = ?(StrEndsWith(Directory, "/"), Directory, Directory + "/");

	FullPath = Directory + FileName;
	PathFile = New File(FullPath);

	If Not PathFile.Exists() Then

		Context.Response.StatusCode = 404;
		Context.Response.ContentType = "application/json";
		Return New Structure("result,error", False, "Not Found");

	Else
		Context.Response.ContentType = MIME;
		Return New BinaryData(FullPath);
	EndIf;

EndFunction

#Region Alternate

Function ПолучитьФайлИзКаталога(Val Каталог, Val ИмяФайла, Val MIME, Val Контекст) Export
	Return GetFileFromFolder(Каталог, ИмяФайла, MIME, Контекст);
EndFunction

#EndRegion