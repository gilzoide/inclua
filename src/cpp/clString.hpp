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

#pragma once

#include <clang-c/CXString.h>
#include <iostream>

/** A RAII wrapper for clang's CXString, with automatic cast to const char*
 */
class clString {
public:
	/// Ctor
	clString (CXString str) : str (str) {}
	/// Dtor
	~clString () {
		clang_disposeString (str);
	}
	/// Assignment directly from a CXString
	clString& operator= (CXString& str) {
		this->str = str;
		return *this;
	}
	/// Cast to const char*
	operator const char* () {
		return clang_getCString (str);
	}

private:
	/// The CXString
	CXString str;
};
