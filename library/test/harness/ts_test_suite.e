indexing

	description:

		"Test suites"

	library:    "Gobo Eiffel Test Library"
	author:     "Eric Bezault <ericb@gobosoft.com>"
	copyright:  "Copyright (c) 2000-2001, Eric Bezault and others"
	license:    "Eiffel Forum Freeware License v1 (see forum.txt)"
	date:       "$Date$"
	revision:   "$Revision$"

class TS_TEST_SUITE

inherit

	TS_TEST

creation

	make

feature {NONE} -- Initialization

	make (a_name: STRING; a_variables: like variables) is
			-- Create a new test suite named `a_name'.
		require
			a_name_not_void: a_name /= Void
			a_variables_not_void: a_variables /= Void
			no_void_variable_name: not a_variables.has (Void)
			no_void_variable_value: not a_variables.has_item (Void)
		do
			name := a_name
			variables := a_variables
			!! tests.make
		ensure
			name_set: name = a_name
			variables_set: variables = a_variables
		end

feature -- Access

	name: STRING
			-- Name

feature -- Measurement

	count: INTEGER is
			-- Number of test cases
		local
			a_cursor: DS_LIST_CURSOR [TS_TEST]
		do
			a_cursor := tests.new_cursor
			from a_cursor.start until a_cursor.after loop
				Result := Result + a_cursor.item.count
				a_cursor.forth
			end
		end

feature -- Execution

	execute (a_summary: TS_SUMMARY) is
			-- Run test and put results in `a_summary'.
		local
			a_cursor: DS_LIST_CURSOR [TS_TEST]
		do
			a_cursor := tests.new_cursor
			from a_cursor.start until a_cursor.after loop
				a_cursor.item.execute (a_summary)
				a_cursor.forth
			end
		end

feature -- Element change

	put_test (a_test: TS_TEST) is
			-- Add `a_test' to test suite.
		require
			a_test_not_void: a_test /= Void
		do
			tests.put_last (a_test)
		end

feature {NONE} -- Implementation

	tests: DS_LINKED_LIST [TS_TEST]
			-- Tests held in test suite

invariant

	tests_not_void: tests /= Void
	no_void_test: not tests.has (Void)

end -- class TS_TEST_SUITE
