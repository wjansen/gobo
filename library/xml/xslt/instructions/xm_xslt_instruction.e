indexing

	description:

		"Objects that represent an XSLT instruction"

	library: "Gobo Eiffel XSLT Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

deferred class XM_XSLT_INSTRUCTION

feature -- Access

	children: DS_ARRAYED_LIST [XM_XSLT_INSTRUCTION]
			-- Child instructions

	result_type: XM_XPATH_SEQUENCE_TYPE is
			-- Static type of values generated by `Current'
		do
			create Result.make_any_sequence
		ensure
			result_type_not_void: Result /= void
		end

feature -- Status report

	last_tail_call: XM_XSLT_INSTRUCTION
			-- Residue from last call to `process_leaving_tail'

feature -- Evaluation

	process_leaving_tail (a_context: XM_XSLT_CONTEXT) is
			-- Execute `Current', writing results to the current `XM_XPATH_RECEIVER'.
		require
			evaluation_context_not_void: a_context /= Void
		deferred
		ensure
			possible_tail_call: last_tail_call = Void or else last_tail_call /= Void
		end

	process (a_context: XM_XSLT_CONTEXT) is
			-- Execute `Current' completely, writing results to the current `XM_XPATH_RECEIVER'.
		require
			evaluation_context_not_void: a_context /= Void
		do
			process_leaving_tail (a_context)
			from
			until
				last_tail_call = Void
			loop
				last_tail_call.process_leaving_tail (a_context)
			end
		ensure
			no_tail_calls: last_tail_call = Void
		end

	process_children (a_context: XM_XSLT_CONTEXT) is
		-- Execute children of `Current' completely, writing results to the current `XM_XPATH_RECEIVER'.
		require
			evaluation_context_not_void: a_context /= Void
		local
			a_transformer: XM_XSLT_TRANSFORMER
			a_cursor: DS_ARRAYED_LIST_CURSOR [XM_XSLT_INSTRUCTION]
		do
			a_transformer := a_context.transformer
			if a_transformer.is_tracing then
				-- TODO
			end
			from
				a_cursor := children.new_cursor
				a_cursor.start
			variant
				children.count + 1 - a_cursor.index
			until
				a_cursor.after
			loop
				if a_transformer.is_tracing then
					-- TODO
				end
				a_cursor.item.process (a_context)
				-- TODO - add error handling
				if a_transformer.is_tracing then
					-- TODO
				end
				a_cursor.forth
			end
		ensure
			no_tail_calls: last_tail_call = Void
		end
invariant

	children_not_void: children /= Void

end
	