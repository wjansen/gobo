indexing

	description:

		"Eiffel manifest strings with no special character"

	library: "Gobo Eiffel Tools Library"
	copyright: "Copyright (c) 1999-2002, Eric Bezault and others"
	license: "Eiffel Forum License v1 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class ET_REGULAR_MANIFEST_STRING

inherit

	ET_MANIFEST_STRING

creation

	make, make_with_position

feature {NONE} -- Initialization

	make (a_literal: like literal) is
			-- Create a new manifest string.
		require
			a_literal_not_void: a_literal /= Void
			-- valid_literal: regexp: \"[^"%\n]*\"
		do
			value := a_literal
			make_leaf
		ensure
			literal_set: literal = a_literal
			line_set: line = no_line
			column_set: column = no_column
		end

	make_with_position (a_literal: like literal; a_line, a_column: INTEGER) is
			-- Create a new manifest string at given position.
		require
			a_literal_not_void: a_literal /= Void
			-- valid_literal: regexp: \"[^"%\n]*\"
			a_line_positive: a_line >= 0
			a_column_positive: a_column >= 0
		do
			value := a_literal
			make_leaf_with_position (a_line, a_column)
		ensure
			literal_set: literal = a_literal
			line_set: a_line <= maximum_line implies line = a_line
			no_line_set: a_line > maximum_line implies line = no_line
			column_set: a_column <= maximum_column implies column = a_column
			no_column_set: a_column > maximum_column implies column = no_column
		end

feature -- Access

	value: STRING
			-- String value

	literal: STRING is
			-- Literal value
		do
			Result := value
		end

feature -- Status report

	computed: BOOLEAN is True
			-- Has manifest string been succesfully computed?

feature -- Compilation

	compute (error_handler: ET_ERROR_HANDLER) is
			-- Compute manifest string, expand special characters.
			-- Make result available in `value'.
		do
			-- Do nothing.
		end

feature -- Processing

	process (a_processor: ET_AST_PROCESSOR) is
			-- Process current node.
		do
			a_processor.process_regular_manifest_string (Current)
		end

invariant

	-- valid_literal: regexp: \"[^"%\n]*\"
	value_not_void: value /= Void

end
