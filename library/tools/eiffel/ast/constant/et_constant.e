indexing

	description:

		"Eiffel constants"

	library: "Gobo Eiffel Tools Library"
	copyright: "Copyright (c) 2002-2005, Eric Bezault and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

deferred class ET_CONSTANT

inherit

	ET_EXPRESSION

feature -- Status report

	is_boolean_constant: BOOLEAN is
			-- Is current constant a BOOLEAN constant?
		do
			-- Result := False
		end

	is_character_constant: BOOLEAN is
			-- Is current constant a CHARACTER constant?
		do
			-- Result := False
		end

	is_integer_constant: BOOLEAN is
			-- Is current constant an INTEGER constant?
		do
			-- Result := False
		end

	is_real_constant: BOOLEAN is
			-- Is current constant a REAL constant?
		do
			-- Result := False
		end

	is_string_constant: BOOLEAN is
			-- Is current constant a STRING constant?
		do
			-- Result := False
		end

	is_bit_constant: BOOLEAN is
			-- Is current constant a BIT constant?
		do
			-- Result := False
		end

	is_type_constant: BOOLEAN is
			-- Is current constant a TYPE constant?
		do
			-- Result := False
		end

end
