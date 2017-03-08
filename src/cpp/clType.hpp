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

#include <clang-c/Index.h>

#include "clString.hpp"

/** RAII wrapper for clang's CXType, with automatic cast to const char*
 */
class clType {
public:
	/// Ctor
	clType(CXType type) : type(type), str(clang_getTypeSpelling(type)) {}
	/// Assignment directly from a CXString
	clType& operator=(CXType& type) {
		this->type = type;
		return *this;
	}
	/// Cast to const char*
	operator const char*() {
		return str;
	}

private:
	/// The CXType
	CXType type;
	/// And it's spelling
	clString str;
};

