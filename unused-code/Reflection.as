
// debug function for printing members of a MwClassInfo recursively
void _printMembers(const Reflection::MwClassInfo@ ty) {
   auto members = ty.Members;
   string extra;
   for (uint i = 0; i < members.Length; i++) {
      // extra = " (" + members[i].Members.Length + " children)";
      print("  " + members[i].Name + extra);
   }
   if (ty.BaseType !is null) {
      _printMembers(ty.BaseType);
   }
}


// debug function for sorta pretty-printing the members of anything that inherits from CMwNod
void printMembers(CMwNod@ nod) {
   if (nod is null) {
      warn(">>> Object of type: null <<<");
      return;
   }
   auto ty = Reflection::TypeOf(nod);
   auto name = ty.Name;
   print("\n>>> Object of type: " + name + " <<<");
   print("Members:");
   _printMembers(ty);
   print("");
}


void printNameAndType(string varName, CMwNod@ nod) {
   auto ty = Reflection::TypeOf(nod);
   print("VAR/TYPE: " + varName + " :: " + (ty is null ? "null" : ty.Name));
}
