indexing

	description:

		"XPath Path Expressions"

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class XM_XPATH_PATH_EXPRESSION

inherit

	XM_XPATH_COMPUTED_EXPRESSION
		redefine
			simplify, promote, compute_dependencies, compute_special_properties, sub_expressions, same_expression
		end

	-- TODO: XM_XPATH_MAPPING_FUNCTION

	XM_XPATH_ROLE

	XM_XPATH_AXIS

	XM_XPATH_TYPE_CHECKER

	XM_XPATH_PROMOTION_ACTIONS

creation

	make

feature {NONE} -- Initialization

	make (a_start: XM_XPATH_EXPRESSION; a_step: XM_XPATH_EXPRESSION) is
			-- Establish invariant.
		require
			start_not_void: a_start /= Void
			step_not_void: a_step /= Void
		local
			a_step_path: XM_XPATH_PATH_EXPRESSION
		do
			start := a_start
			step := a_step

			-- If start is a path expression such as a, and step is b/c, then
			--  instead of a/(b/c) we construct (a/b)/c.
			-- This is because it often avoids a sort.

		  -- The "/" operator in XPath 2.0 is not always associative. Problems
		  -- can occur if position() and last() are used on the rhs, or if node-constructors
		  -- appear, e.g. //b/../<d/>. So we only do this rewrite if the step is a path
		  -- expression in which both operands are axis expression optionally with predicates

			a_step_path ?= step
			if a_step_path /= Void then
				if is_filtered_axis_path (a_step_path.start) and then is_filtered_axis_path (a_step_path.start) then
					create {XM_XPATH_PATH_EXPRESSION} start.make (start, a_step_path.start)
					-- TODO - copy location information
					step := a_step_path.step
				end
			end
		end

feature -- Access
	
	item_type: INTEGER is
			--Determine the data type of the expression, if possible
		local
			a_step_type: INTEGER
		do
			a_step_type := step.item_type
			if is_node_type (a_step_type) then
				Result := a_step_type
			else

				-- rely on dynamic typing to ensure that it always returns nodes
				
				Result := Any_node
			end
		end


	sub_expressions: DS_ARRAYED_LIST [XM_XPATH_EXPRESSION] is
			-- Immediate sub-expressions of `Current'
		do
			create Result.make (2)
			Result.set_equality_tester (expression_tester)
			Result.put (start, 1)
			Result.put (step, 2)
		end

feature -- Comparison

	same_expression (other: XM_XPATH_EXPRESSION): BOOLEAN is
			-- Are `Current' and `other' the same expression?
		local
			a_path: XM_XPATH_PATH_EXPRESSION
		do
			a_path ?= other
			if a_path /= Void then
				Result := start.same_expression (a_path.start) and then step.same_expression (a_path.step)
			end
		end

feature -- Status report

	display (a_level: INTEGER; a_pool: XM_XPATH_NAME_POOL) is
			-- Diagnostic print of expression structure to `std.error'
		local
			a_string: STRING
		do
			a_string := STRING_.appended_string (indent (a_level), "path /")
			std.error.put_string (a_string)
			std.error.put_new_line
			start.display (a_level + 1, a_pool)
			step.display (a_level + 1, a_pool)
		end

feature -- Status setting

	compute_dependencies is
			-- Compute dependencies on context.
		do
			if not are_intrinsic_dependencies_computed then compute_intrinsic_dependencies end
			create dependencies.make (1, 6)

			dependencies := start.dependencies
			if step.Depends_upon_xslt_context then
				dependencies.put (True, 1)
				dependencies.put (True, 6)
			end
			are_dependencies_computed := True
		end
	
feature -- Optimization

	simplify: XM_XPATH_EXPRESSION is
			-- Simplify `Current'
		local
			an_expression: XM_XPATH_EXPRESSION
			an_empty_sequence: XM_XPATH_EMPTY_SEQUENCE
			a_context_item: XM_XPATH_CONTEXT_ITEM_EXPRESSION
			a_root: XM_XPATH_ROOT_EXPRESSION
			a_parent_step: XM_XPATH_PARENT_NODE_EXPRESSION
			a_result_expression, a_step_path, a_start_path, a_path: XM_XPATH_PATH_EXPRESSION
		do
			a_result_expression := clone (Current)
			an_expression := start.simplify
			if not start.is_static_type_error then
				a_result_expression.set_start (an_expression)
				an_expression := step.simplify
				if not step.is_static_type_error then
					a_result_expression.set_step (an_expression)
				
					an_empty_sequence ?= a_result_expression.start
					if an_empty_sequence /= Void then
						
						-- if the start expression is an empty node-set, then the whole path-expression is empty
						
						Result := an_empty_sequence
					else
						
						-- Remove a redundant "." from the path.
						-- Note: we are careful not to do this unless the other operand is naturally sorted.
						-- In other cases, ./E (or E/.) is not a no-op, because it forces sorting.
						
						a_context_item ?= a_result_expression.start
						a_step_path ?= a_result_expression.step
						if a_context_item /= Void and then a_step_path /= Void and then a_step_path.Ordered_nodeset then
							a_result_expression := a_step_path
						else
							a_context_item ?= a_result_expression.step
							a_start_path ?= a_result_expression.start
							if a_context_item /= Void and then a_start_path /= Void and then a_start_path.Ordered_nodeset then
								a_result_expression := a_start_path
							else
								
								-- the expression /.. is sometimes used to represent the empty node-set
								
								a_root ?= a_result_expression.start
								a_parent_step ?= a_result_expression.step
								if a_root /= Void and then a_parent_step /= Void then
									create {XM_XPATH_EMPTY_SEQUENCE} Result.make
								end
							end
						end
						if Result = Void then Result := a_result_expression end
					end
				else
					is_static_type_error := True
					set_last_static_type_error (step.last_static_type_error)
				end
			else
				is_static_type_error := True
				set_last_static_type_error (start.last_static_type_error)
			end
		end

	analyze (a_context: XM_XPATH_STATIC_CONTEXT): XM_XPATH_EXPRESSION is
			-- Perform static analysis of `Current' and its subexpressions
		local
			an_expression, another_expression: XM_XPATH_EXPRESSION
			a_result_expression, a_path: XM_XPATH_PATH_EXPRESSION
			a_role, another_role: XM_XPATH_ROLE_LOCATOR
			a_node_sequence: XM_XPATH_SEQUENCE_TYPE
			an_offer: XM_XPATH_PROMOTION_OFFER
			a_let_expression: XM_XPATH_LET_EXPRESSION
			path_not_void: BOOLEAN
		do
			a_result_expression := clone (Current)
			an_expression := start.analyze (a_context)
			if not start.is_static_type_error then
				a_result_expression.set_start (an_expression)
				an_expression := step.analyze (a_context)
				if not an_expression.is_static_type_error then
					a_result_expression.set_step (an_expression)
					
					-- We don't need the operands to be sorted;
					--  any sorting that's needed will be done at the top level
					
					a_result_expression.set_start (a_result_expression.start.unsorted (False))
					a_result_expression.set_step (a_result_expression.step.unsorted (False))
					
					-- Both operands must be of type node()*
					
					create a_role.make (Binary_expression_role, "/", 0)
					create a_node_sequence.make_node_sequence
					a_result_expression.set_start (static_type_check(a_result_expression.start, a_node_sequence, False, a_role))
					if not is_static_type_check_error then
						create another_role.make (Binary_expression_role, "/", 1)
						a_result_expression.set_step (static_type_check (a_result_expression.step, a_node_sequence, False, another_role))
						if not is_static_type_check_error then
							
							-- Try to simplify expressions such as a//b

							a_path := simplify_descendant_path (a_result_expression)
							path_not_void := a_path /= Void
							if path_not_void then
								a_path ?= a_path.simplify
								path_not_void := a_path /= Void
								if is_static_type_check_error then
									is_static_type_error := True
									set_last_static_type_error (static_type_check_error_message)
								else
										check
											path_not_void: a_path /= Void
										end
									a_path ?= a_path.analyze (a_context)
									if is_static_type_check_error then
										is_static_type_error := True
										set_last_static_type_error (static_type_check_error_message)
									else
											check
												path_not_void: a_path /= Void
											end
										Result := a_path
									end
								end
								if path_not_void then

									-- If any subexpressions within the step are not dependent on the focus, promote them:
									-- this causes them to be evaluated once, outside the path  expression.

									create an_offer.make (Focus_independent, Void, a_result_expression, False, a_result_expression.start.Context_document_nodeset)
									an_expression := a_result_expression.step.promote (an_offer)
									a_result_expression.set_step (an_expression)
									a_let_expression ?= an_offer.containing_expression
									if a_let_expression /= Void then
										another_expression := a_let_expression.analyze (a_context)
										if a_let_expression.is_static_type_error then
											is_static_type_error := True
											set_last_static_type_error (a_let_expression.last_static_type_error)
										else
											an_offer.set_containing_expression (another_expression)
										end
										
										-- Decide whether the result needs to be wrapped in a sorting
										-- expression to deliver the results in document order
										
										if not is_static_type_error then
											a_path ?= an_offer.containing_expression
											if a_path = Void then
												if a_path.Ordered_nodeset then
													Result := a_path
												elseif a_path.Reverse_document_order then
													create {XM_XPATH_REVERSER} Result.make (a_path)
												else
													create {XM_XPATH_DOCUMENT_SORTER} Result.make (a_path)
												end
											else
												Result := an_offer.containing_expression
											end
										end
									end
								end
							else
								is_static_type_error := True
								set_last_static_type_error (static_type_check_error_message)
							end
						else
							is_static_type_error := True
							set_last_static_type_error (static_type_check_error_message)
						end
					else
						is_static_type_error := True
						set_last_static_type_error (step.last_static_type_error)
					end
				else
					is_static_type_error := True
					set_last_static_type_error (start.last_static_type_error)
				end
			end
		end

	promote (an_offer: XM_XPATH_PROMOTION_OFFER): XM_XPATH_EXPRESSION is
			-- Offer promotion for `Current'
		local
			a_result_expression: XM_XPATH_PATH_EXPRESSION
		do
			a_result_expression ?= an_offer.accept (Current)
			if a_result_expression = Void then
				a_result_expression := clone (Current)
				a_result_expression.set_start (start.promote (an_offer))
				if an_offer.action = Inline_variable_references then

					-- Don't pass on other requests. We could pass them on, but only after augmenting
					--  them to say we are interested in subexpressions that don't depend on either the
					--  outer context or the inner context.

					a_result_expression.set_step (step.promote (an_offer))
				end
			end
			Result := a_result_expression
		end

feature {XM_XPATH_EXPRESSION} -- Restricted
	
	compute_cardinality is
			-- Compute cardinality.
		local
			c1, c2, c3: INTEGER
			an_expression: XM_XPATH_COMPUTED_EXPRESSION
		do
			if not start.are_cardinalities_computed then
				an_expression ?= start
					check
						start_is_computed: an_expression /= Void
						-- as it can't be a value
					end
				an_expression.compute_cardinality
			end
			if not step.are_cardinalities_computed then
				an_expression ?= step
					check
						step_is_computed: an_expression /= Void
						-- as it can't be a value
					end
				an_expression.compute_cardinality
			end
			c1 := start.cardinality
			c2 := step.cardinality
			c3 := multiply_cardinality (c1, c2)
			set_cardinality (c3)
			are_cardinalities_computed := True
		end

feature {XM_XPATH_PATH_EXPRESSION} -- Local

	start: XM_XPATH_EXPRESSION
			-- Starting node-set
	
	step: XM_XPATH_EXPRESSION
			-- Step from each node in starting node-set

	set_start (a_start: XM_XPATH_EXPRESSION) is
			-- Set `start'.
		require
			start_not_void: a_start /= Void
		do
			start := a_start
		ensure
			start_set: start = a_start
		end

	set_step (a_step: XM_XPATH_EXPRESSION) is
			-- Set `start'.
		require
			step_not_void: a_step /= Void
		do
			step := a_step
		ensure
			step_set: step = a_step
		end
	
feature {NONE} -- Implementation

	is_filtered_axis_path (exp: XM_XPATH_EXPRESSION): BOOLEAN is
			-- Is `exp' an axis step with optional filter predicates?
		require
			expression_not_void: exp /= Void
		local
			an_axis: XM_XPATH_AXIS_EXPRESSION
			a_filter: XM_XPATH_FILTER_EXPRESSION
			an_expression: XM_XPATH_EXPRESSION
		do
			an_axis ?= exp
			if an_axis /= Void then
				Result := True
			else
				from
					an_expression := exp
					a_filter ?= an_expression
				until
					a_filter = Void
				loop
					an_expression := a_filter.base_expression
					a_filter ?= an_expression
				end
				an_axis ?= an_expression
				Result := an_axis /= Void
			end
		end

	simplify_descendant_path (an_expression: XM_XPATH_PATH_EXPRESSION): XM_XPATH_PATH_EXPRESSION is
		local
			st: XM_XPATH_EXPRESSION
			an_axis: XM_XPATH_AXIS_EXPRESSION
			a_context_item_expression: XM_XPATH_CONTEXT_ITEM_EXPRESSION
			a_path: XM_XPATH_PATH_EXPRESSION
			a_test: XM_XPATH_NODE_TEST
			any_node_test: XM_XPATH_ANY_NODE_TEST
			a_filter: XM_XPATH_FILTER_EXPRESSION
			any_positional_filter: BOOLEAN
			a_new_step: XM_XPATH_COMPUTED_EXPRESSION
			a_node_kind_test: XM_XPATH_NODE_KIND_TEST
		do
			st := an_expression.start

			-- Detect .//x as a special case; this will appear as descendant-or-self::node()/x

			an_axis ?= st
			if an_axis /= Void and then an_axis.axis /= Descendant_or_self_axis then
			else
				if an_axis /= Void then
					create a_context_item_expression.make -- TODO copy location information
					create {XM_XPATH_PATH_EXPRESSION} st.make (a_context_item_expression, an_axis)	-- TODO copy location information
				end
				a_path ?= st
				if a_path = Void then
					Result := Void
				else
					an_axis ?= a_path.step
					if an_axis = Void then
						Result := Void
					elseif an_axis.axis /= Descendant_or_self_axis then
						Result := Void
					else
						a_test ?= an_axis
						any_node_test ?= an_axis
						if a_test = Void or else any_node_test /= Void then
							Result := Void
						else
							from
								any_positional_filter := False
								a_filter ?= an_expression.step
							until
								any_positional_filter or else a_filter = Void
							loop
								if a_filter.is_positional then
									Result := Void
									any_positional_filter := True
								else
									a_filter ?= a_filter.base_expression
									an_axis ?= a_filter.base_expression
								end
							end
							if not any_positional_filter then
								if an_axis = Void then
									Result := Void
								else
									if an_axis.axis = Child_axis then
										create {XM_XPATH_AXIS_EXPRESSION} a_new_step.make (Descendant_axis, an_axis.node_test )	-- TODO copy location information
										from
											a_filter ?= an_expression.step
										until
											a_filter = Void
										loop

											-- Add any filters to the new expression. We know they aren't
											-- positional, so the order of the filters doesn't matter.

											create {XM_XPATH_FILTER_EXPRESSION} a_new_step.make (a_new_step, a_filter.filter)	-- TODO copy location information
											a_filter ?= a_filter.base_expression
										end
										create a_path.make (a_path.start, a_new_step)	-- TODO copy location information
										Result := a_path
									elseif an_axis.axis = Attribute_axis then

										-- turn the expression a//@b into a/descendant-or-self::*/@b

										create a_node_kind_test.make (Element_node)
										create {XM_XPATH_AXIS_EXPRESSION} a_new_step.make (Descendant_or_self_axis, a_node_kind_test )	-- TODO copy location information
										create a_path.make (a_path.start, a_new_step)
										create a_path.make (a_path, an_expression.step)	-- TODO copy location information
										Result := a_path
									end
								end
							end
						end
					end
				end
			end
		end

	compute_special_properties is
			-- Compute special properties.
		local
			an_expression: XM_XPATH_COMPUTED_EXPRESSION
		do
			create special_properties.make (1, 6)

			-- All `False' by default

			if not are_cardinalities_computed then compute_cardinality end
			if not start.are_special_properties_computed then
				an_expression ?= start
					check
						start_is_computed: an_expression /= Void
						-- as it can't be a value
					end
				an_expression.compute_special_properties
			end
			if not step.are_special_properties_computed then
				an_expression ?= step
					check
						step_is_computed: an_expression /= Void
						-- as it can't be a value
					end
				an_expression.compute_special_properties
			end
			if not start.cardinality_allows_many then
				start.set_ordered_nodeset
				start.set_peer_nodeset
			end
			if not step.cardinality_allows_many then
				step.set_ordered_nodeset
				step.set_peer_nodeset
			end

			if start.context_document_nodeset and then step.context_document_nodeset then
				set_context_document_nodeset
			end
			if start.peer_nodeset and then step.peer_nodeset then
				set_peer_nodeset
			end
			if start.subtree_nodeset and then step.subtree_nodeset then
				set_subtree_nodeset
			end

			if is_naturally_sorted then
				set_ordered_nodeset
			end

			if is_naturally_reverse_sorted then
				set_reverse_document_order
			end

			are_special_properties_computed := True
		end

	is_naturally_sorted: BOOLEAN is
			-- Are nodes guarenteed to be delivered in document order?

			-- This is true if the start nodes are sorted peer nodes
			--  and the step is based on an Axis within the subtree rooted at each node.
			-- It is also true if the start is a singleton node and the axis is sorted.
		require
			start_special_properties_computed: start.are_special_properties_computed
			step_special_properties_computed: step.are_special_properties_computed
		do
			if start.Ordered_nodeset and then step.Ordered_nodeset then

				-- We know now that both the start and the step are sorted. But this does
				-- not necessarily mean that the combination is sorted

				-- The result is sorted if the start is sorted and the step selects attributes
				-- or namespaces
					
				if step.Attribute_ns_nodeset then
					Result := True
				else

					-- The result is sorted if the start selects "peer nodes" (that is, a node-set in which
					-- no node is an ancestor of another) and the step selects within the subtree rooted
					-- at the context node

					if start.peer_nodeset and then step.subtree_nodeset then
						Result := True
					end
				end
			end
		end

	is_naturally_reverse_sorted: BOOLEAN is
			-- Are nodes guarenteed to be delivered in reverse document order?

			--  Some examples of expressions that are naturally reverse sorted:
			--     ../@x
			--     ancestor::*[@lang]
			--     ../preceding-sibling::x
			--     $x[1]/preceding-sibling::node()

			-- This information is used to do a simple reversal of the nodes
			-- instead of a full sort, which is significantly cheaper, especially
			-- when using tree models in which comparing
			-- nodes in document order is an expensive operation.
		require
			start_special_properties_computed: start.are_special_properties_computed
			step_special_properties_computed: step.are_special_properties_computed
		local
			an_axis: XM_XPATH_AXIS_EXPRESSION
			an_attribute_reference: XM_XPATH_ATTRIBUTE_REFERENCE_EXPRESSION
		do
			an_axis ?= step
			if not start.cardinality_allows_many and then an_axis /= Void then
				Result := not is_forward_axis (an_axis.axis)
			else
				an_axis ?= start
				if start /= void then
					if is_forward_axis (an_axis.axis) then
						Result := False
					else
						an_attribute_reference ?= step
						Result := an_attribute_reference /= Void
					end
				end
			end
		end

invariant

	start_not_void: start /= Void
	step_not_void: step /= Void

end