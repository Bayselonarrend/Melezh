#Use oint

// Fields echo
//
// Parameters:
// Field1 - String - Field 1 value - field1
// Field2 - String - Field 2 value - field2
// Field3 - String - Field 3 value - field3
//
// Returns:
// Structure Of KeyAndValue - Echo
Function FieldsEcho(Val Field1, Val Field2, Val Field3 = "") Export
	A = True;
	Return New Structure("field1,field2,field3", Field1, Field2, Field3);
EndFunction

// Echo text
//
// Parameters:
// Field1 - String - Field 1 value - field1
// Field2 - String - Field 2 value - field2
// Field3 - String - Field 3 value - field3
//
// Returns:
// String - Echo
Function EchoText(Val Field1, Val Field2, Val Field3 = "") Export
	Return StrTemplate("field1=%1&field2=%2&field3=%3", Field1, Field2, Field3);
EndFunction

// Return data by URL
//
// Parameters:
// URL - String - URL for data receiving - url
//
// Returns:
// BinaryData - Data
Function ReturnDataByURL(Val URL) Export

	OPI_TypeConversion.GetBinaryData(URL);
	Return URL;

EndFunction



#Region Alternate

Function ЭхоПолей(Val Поле1, Val Поле2, Val Поле3 = "") Export
	Return FieldsEcho(Поле1, Поле2, Поле3);
EndFunction

Function ЭхоТекст(Val Поле1, Val Поле2, Val Поле3 = "") Export
	Return EchoText(Поле1, Поле2, Поле3);
EndFunction

Function ВернутьДанныеПоURL(Val URL) Export
	Return ReturnDataByURL(URL);
EndFunction

#EndRegion