/* Copyright 2016-2017 Gil Barbosa Reis <gilzoide@gmail.com>
 * This file is part of Inclua.
 *
 * Inclua is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Inclua is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Inclua.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "visitor.hpp"
#include "clString.hpp"

#include <iostream>

CXChildVisitResult visitor (CXCursor cursor, CXCursor, CXClientData) {  
	CXCursorKind kind = clang_getCursorKind(cursor);

	// Consider functions and methods
	switch (kind) {
		case CXCursor_FunctionDecl:
		case CXCursor_CXXMethod:
			clString cursorName = clang_getCursorDisplayName(cursor);

			// Get the source location
			CXSourceRange range = clang_getCursorExtent(cursor);
			CXSourceLocation location = clang_getRangeStart(range);

			CXFile file;
			unsigned line;
			unsigned column;
			clang_getFileLocation(location, &file, &line, &column, nullptr);

			clString fileName = clang_getFileName(file);

			std::cout << "Found call to " << cursorName << " at "
				<< line << ":" << column << " in " << fileName
				<< std::endl;
			break;
	}

	return CXChildVisit_Recurse;
}

int visitHeader (const char *headername, vector<const char*> args) {
	auto idx = clang_createIndex (1, 1);
	auto tu = clang_parseTranslationUnit (idx, headername, args.data (),
			args.size (), NULL, 0, CXTranslationUnit_SkipFunctionBodies);
	if (!tu) {
		return 0;
	}
	clang_visitChildren (clang_getTranslationUnitCursor (tu), visitor, 0);

	clang_disposeTranslationUnit (tu);
	clang_disposeIndex (idx);
	return 1;
}

