// Echo field
// Returns the fields from the request in the response
//
// Parameters:
// Field1 - String - Field 1 value - field1
// Field2 - String - Field 2 value - field2
// Field3 - String - Field 3 value - field3
//
// Returns:
// Structure Of KeyAndValue - Echo
Function FieldsEcho(Val Field1, Val Field2, Val Field3 = "") Export
	Return New Structure("field1,field2,field3", Field1, Field2, Field3);
EndFunction
