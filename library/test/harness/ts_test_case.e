indexing

	description:

		"Test cases"

	library: "Gobo Eiffel Test Library"
	copyright: "Copyright (c) 2000-2008, Eric Bezault and others"
	license: "MIT License"
	date: "$Date$"
	revision: "$Revision$"

deferred class TS_TEST_CASE

inherit

	TS_TEST

	TS_ASSERTION_ROUTINES

feature {NONE} -- Initialization

	make_default is
			-- Default initialization.
		do
			initialize
		end

feature -- Initialization

	initialize is
			-- Initialize current test case.
			-- (This routine is called by the creation routine
			-- and can be redefined in descendant classes.)
		do
		end

	set_test (a_name: like name; a_test_feature: PROCEDURE [TS_TEST_CASE, TUPLE]) is
			-- Identify one of the test features of current test case
			-- as being the one that will be executed when running
			-- this test case.
		require
			a_name_not_void: a_name /= Void
			a_test_feature_not_void: a_test_feature /= Void
		do
			internal_name := a_name
			internal_test_feature := a_test_feature
		ensure
			name_set: name = a_name
			internal_test_feature_set: internal_test_feature = a_test_feature
		end

feature -- Access

	name: STRING is
			-- Name
		do
			Result := internal_name
			if Result = Void then
				Result := default_test_name
			end
		end

	variables: TS_VARIABLES is
			-- Defined variables
		do
			if internal_variables = Void then
				create internal_variables.make
			end
			Result := internal_variables
		end

	assertions: TS_ASSERTIONS is
			-- Assertions
		do
			if internal_assertions = Void then
				create internal_assertions.make
			end
			Result := internal_assertions
		end

	test_logger: TS_TEST_LOGGER is
			-- Logger for tests and assertion checkings
		obsolete
			"[080210] Use `logger' instead"
		do
			Result := logger
		end

	logger: TS_TEST_LOGGER is
			-- Logger for tests and assertion checkings
		do
			if internal_logger = Void then
				create {TS_NULL_TEST_LOGGER} internal_logger.make
			end
			Result := internal_logger
		end

feature -- Setting

	set_variables (a_variables: like variables) is
			-- Set `variables' to `a_variables'.
		require
			a_variables_not_void: a_variables /= Void
		do
			internal_variables := a_variables
		ensure
			variables_set: variables = a_variables
		end

	set_test_logger (a_logger: like test_logger) is
			-- Set `logger' to `a_logger'.
		obsolete
			"[080210] Use `set_logger' instead"
		require
			a_logger_not_void: a_logger /= Void
		do
			set_logger (a_logger)
		ensure
			logger_set: logger = a_logger
		end

	set_logger (a_logger: like logger) is
			-- Set `logger' to `a_logger'.
		do
			internal_logger := a_logger
		ensure
			logger_set: logger = a_logger
		end

feature -- Measurement

	count: INTEGER is 1
			-- Number of test cases

feature -- Execution

	execute (a_summary: TS_SUMMARY) is
			-- Run test and put results in `a_summary'.
		do
			assertions.reset
			a_summary.start_test (Current)
			if a_summary.fail_on_rescue then
				execute_without_rescue (a_summary)
			else
				execute_with_rescue (a_summary)
			end
			a_summary.end_test (Current, assertions.count)
			assertions.reset
		end

	set_up is
			-- Setup for a test.
			-- (Can be redefined in descendant classes.)
		do
		end

	tear_down is
			-- Tear down after a test.
			-- (Can be redefined in descendant classes.)
		do
		end

	default_test is
			-- Run default test case.
			-- (Can be redefined in descendant classes.)
		do
		end

feature {NONE} -- Execution

	execute_without_rescue (a_summary: TS_SUMMARY) is
			-- Run test and put results in `a_summary'.
		require
			a_summary_not_void: a_summary /= Void
		local
			i, nb: INTEGER
			an_error_messages: DS_ARRAYED_LIST [STRING]
		do
			set_up
			if internal_test_feature /= Void then
				internal_test_feature.call ([])
			else
				default_test
			end
			tear_down
			an_error_messages := assertions.error_messages
			nb := an_error_messages.count
			if nb = 0 then
				a_summary.put_success (Current)
			else
				from i := 1 until i > nb loop
					a_summary.put_failure (Current, an_error_messages.item (i))
					i := i + 1
				end
			end
		end

	execute_with_rescue (a_summary: TS_SUMMARY) is
			-- Run test and put results in `a_summary'.
		require
			a_summary_not_void: a_summary /= Void
		local
			retried: BOOLEAN
			i, nb: INTEGER
			an_error_messages: DS_ARRAYED_LIST [STRING]
		do
			if not retried then
				execute_without_rescue (a_summary)
			else
				tear_down
				if assertions.exception_raised then
					assertions.catch_exception
					an_error_messages := assertions.error_messages
					nb := an_error_messages.count
					if nb = 0 then
							-- This should not happen: if an exception has
							-- been raised, there must be a reported error.
						a_summary.put_success (Current)
					else
						from i := 1 until i > nb loop
							a_summary.put_failure (Current, an_error_messages.item (i))
							i := i + 1
						end
					end
				else
					a_summary.put_abort (Current, "Eiffel exception")
				end
			end
		rescue
			if not retried then
				retried := True
				retry
			end
		end

feature {NONE} -- Implementation

	internal_name: STRING
			-- Internal implementation of `name'

	internal_test_feature: PROCEDURE [TS_TEST_CASE, TUPLE]
			-- Internal implementation of test feature to be executed
			-- (Should be an agent to one of test features of the current test case.)

	internal_variables: TS_VARIABLES
			-- Internal implementation of `variables'

	internal_assertions: TS_ASSERTIONS
			-- Internal implementation of `assertions'

	internal_logger: TS_TEST_LOGGER
			-- Internal implementation of `logger'

feature {NONE} -- Constants

	default_test_name: STRING is "Default test"
			-- Name for default test

end
