indexing

	description:

		"XPath Parent Node Expressions - '..' or 'parent::node()'"

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class XM_XPATH_PARENT_NODE_EXPRESSION

inherit

	XM_XPATH_SINGLE_NODE_EXPRESSION
		redefine
			same_expression
		end

	XM_XPATH_EXCEPTIONS

creation

	make

feature {NONE} -- Initialization

	make is
			-- Create intrinsic dependencies.
		do
			create intrinsic_dependencies.make (1, 6)
			intrinsic_dependencies.put (True, 2) -- depends_upon_context_item												
		end

feature -- Access

	node (a_context: XM_XPATH_CONTEXT): XM_XPATH_NODE is
			-- The single node
		local
			an_item: XM_XPATH_ITEM
			a_node: XM_XPATH_NODE
			a_document: XM_XPATH_DOCUMENT
			an_exception_message: STRING
		do
			an_item := a_context.context_item
			if an_item = Void then
				an_exception_message := STRING_.appended_string (Xpath_dynamic_error_prefix, "Evaluating 'parent::node()': the context item is not set")
				Exceptions.raise (an_exception_message)
			else
				a_node ?= an_item
				if a_node = Void then
					Result := Void
				else
					Result := a_node.parent
				end
			end
		end

feature -- Comparison

	same_expression (other: XM_XPATH_EXPRESSION): BOOLEAN is
			-- Are `Current' and `other' the same expression?
		local
			another_parent: XM_XPATH_PARENT_NODE_EXPRESSION
		do
			another_parent ?= other
			Result := another_parent /= Void
		end

feature -- Status report

	display (a_level: INTEGER; a_pool: XM_XPATH_NAME_POOL) is
			-- Diagnostic print of expression structure to `std.error'
		local
			a_string: STRING
		do
			a_string := STRING_.appended_string (indent (a_level), "..")
			std.error.put_string (a_string)
			std.error.put_new_line
		end
	
end