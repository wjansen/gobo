indexing

	description:

		"Objects that represent the document node of a temporary tree"

	library: "Gobo Eiffel XSLT Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class XM_XSLT_COMPILED_DOCUMENT

inherit

	XM_XSLT_EXPRESSION_INSTRUCTION
		redefine
			analyze, evaluate_item
		end
	
	XM_XPATH_SHARED_NODE_KIND_TESTS

creation

	make

feature {NONE} -- Initialization

	make (text_only: BOOLEAN;  a_constant_text: STRING; a_base_uri: STRING) is
			-- Establish invariant.
		require
			constant_text: text_only implies a_constant_text /= Void
			base_uri: a_base_uri /= Void
		do
			instruction_name := "document"
			create children.make (0)
			make_expression_instruction
			set_cardinality_exactly_one
		end

feature -- Access
	
	instruction_name: STRING
			-- Name of instruction, for diagnostics
	
	item_type: XM_XPATH_ITEM_TYPE is
			-- Data type of the expression, when known
		do
			Result := document_node_kind_test
		end
	
feature -- Comparison

	same_expression (other: XM_XPATH_EXPRESSION): BOOLEAN is
			-- Are `Current' and `other' the same expression?
		do
			Result := False
			todo ("same_expression", True)
		end

feature -- Status report

	display (a_level: INTEGER; a_pool: XM_XPATH_NAME_POOL) is
			-- Diagnostic print of expression structure to `std.error'
		local
			a_string: STRING
		do
			a_string := STRING_.appended_string (indentation (a_level), "document-constructor")
			std.error.put_string (a_string)
			std.error.put_new_line
			if children.count = 0 then
				a_string := STRING_.appended_string (indentation (a_level + 1), "empty content")
				std.error.put_string (a_string)
				std.error.put_new_line
			else
				display_children (a_level + 1, a_pool)
			end
		end

	
feature -- Optimization

	analyze (a_context: XM_XPATH_STATIC_CONTEXT) is
			-- Perform static analysis of `Current' and its subexpressions.
		local
			a_sequence_instruction: XM_XSLT_SEQUENCE_INSTRUCTION
			an_expression: XM_XSLT_EXPRESSION_INSTRUCTION
			a_cursor: DS_ARRAYED_LIST_CURSOR [XM_XSLT_INSTRUCTION]	
		do
			from
				a_cursor := children.new_cursor
				a_cursor.start
			variant
				children.count + 1 - a_cursor.index
			until
				a_cursor.after
			loop
				an_expression ?= a_cursor.item
				if an_expression /= Void then
					an_expression.analyze (a_context)
					a_cursor.replace (an_expression)
				else
					set_last_error_from_string ("BUG: Children of an XM_XSLT_EXPRESSION_INSTRUCTION must themselves be Expressions", 0, Type_error)
				end
				a_cursor.forth
			end
		end

	promote_instruction (an_offer: XM_XPATH_PROMOTION_OFFER) is
			-- Promote this instruction.
		local
			a_cursor: DS_ARRAYED_LIST_CURSOR [XM_XSLT_INSTRUCTION]
			an_expression: XM_XPATH_EXPRESSION
			an_instruction: XM_XSLT_INSTRUCTION
		do
			from
				a_cursor := children.new_cursor
				a_cursor.start
			variant
				children.count + 1 - a_cursor.index
			until
				a_cursor.after
			loop
				an_expression ?= a_cursor.item
				if an_expression = Void then
					a_cursor.go_after
					set_last_error_from_string ("BUG: Children of an XM_XSLT_EXPRESSION_INSTRUCTION must themselves be Expressions", 0, Type_error)
				else
					an_expression.promote (an_offer)
					--if an_expression.was_expression_replaced then an_expression := an_expression.replacement_expression end
					an_instruction ?= an_expression
					if an_instruction /= Void then
						a_cursor.replace (an_instruction)
					else
						check
							cant_happen: False
						end
						--create a_sequence_instruction.make (an_expression, Void)
						--a_cursor.replace (a_sequence_instruction)
					end
				end
				a_cursor.forth
			end					
		end

feature -- Evaluation

	evaluate_item (a_context: XM_XPATH_CONTEXT) is
			-- Evaluate as a single item.
		local
			an_evaluation_context: XM_XSLT_EVALUATION_CONTEXT
			a_transformer: XM_XSLT_TRANSFORMER
		do
			an_evaluation_context ?= a_context
			check
				evaluation_context: an_evaluation_context /= Void
				-- as it is the only supported form of dynamicx context for XSLT in the library
			end
			a_transformer := an_evaluation_context.transformer
			todo ("evaluae_item", true)
		end

	process_leaving_tail (a_context: XM_XSLT_CONTEXT) is
			-- Execute `Current', writing results to the current `XM_XPATH_RECEIVER'.
		do
			todo ("process_leaving_tail", False)
		end

feature {XM_XSLT_EXPRESSION_INSTRUCTION} -- Local

	xpath_expressions (an_instruction_list: DS_ARRAYED_LIST [XM_XSLT_EXPRESSION_INSTRUCTION]): DS_ARRAYED_LIST [XM_XPATH_EXPRESSION] is
			-- All the XPath expressions associated with this instruction;
			--  (in XSLT terms, the expressions present on attributes of the instruction,
			--  as distinct from the child instructions in a sequence construction)
		do
			create Result.make (0)
			Result.set_equality_tester (expression_tester)
		end

end

