indexing

	description:

		"xsl:transform or xsl:stylesheet element nodes"

	library: "Gobo Eiffel XSLT Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class XM_XSLT_STYLESHEET

inherit

	XM_XSLT_STYLE_ELEMENT
		redefine
			make_style_element, target_name_pool, precedence, process_all_attributes, validate, is_global_variable_declared
		end

	XM_XSLT_PROCEDURE

	XM_XSLT_STRING_ROUTINES

	XM_XSLT_VALIDATION

creation {XM_XSLT_NODE_FACTORY}

	make_style_element

feature {NONE} -- Initialization
	
	make_style_element (an_error_listener: XM_XSLT_ERROR_LISTENER; a_document: XM_XPATH_TREE_DOCUMENT;  a_parent: XM_XPATH_TREE_COMPOSITE_NODE;
		an_attribute_collection: XM_XPATH_ATTRIBUTE_COLLECTION; a_namespace_list:  DS_ARRAYED_LIST [INTEGER];
		a_name_code: INTEGER; a_sequence_number: INTEGER) is
			-- Establish invariant.
		local
			a_code_point_collator: ST_COLLATOR
		do
			target_name_pool := a_document.name_pool
			create named_templates_index.make_map (5)
			create variables_index.make_map (5)
			create namespace_alias_list.make (5)
			create key_manager.make
			create decimal_format_manager.make
			create collation_map.make_with_equality_testers (1, Void, string_equality_tester)
			create a_code_point_collator
			declare_collation ("http://www.w3.org/2003/11/xpath-functions/collation/codepoint", a_code_point_collator)
			create stylesheet_module_map.make_with_equality_testers (5, Void, string_equality_tester)
			Precursor (an_error_listener, a_document, a_parent, an_attribute_collection, a_namespace_list, a_name_code, a_sequence_number)
		end

feature -- Access

	importer: like Current
			-- The stylesheet that imported or included `Current';
			-- `Void' for the prinicpal stylesheet.

	target_name_pool: XM_XPATH_NAME_POOL
			-- Name pool to be used at run-time;
			-- This namepool holds the names used in
			--  all XPath expressions and patterns.

	prepared_stylesheet: XM_XSLT_PREPARED_STYLESHEET
			-- Prepared stylesheet object used to load `Current'

	top_level_elements: DS_ARRAYED_LIST [XM_XSLT_STYLE_ELEMENT]
			-- Top-level elements in this logical stylesheet (after include/import processing)

	import_precedence: INTEGER
			-- Import precedence for top-level elements

	minimum_import_precedence: INTEGER
			-- Lowest precedence of any stylesheet imported by `Current'

	rule_manager: XM_XSLT_RULE_MANAGER
			-- Manager of template-matching rules

	key_manager: XM_XSLT_KEY_MANAGER
			-- Manger of key definitions

	decimal_format_manager: XM_XSLT_DECIMAL_FORMAT_MANAGER
			-- Manager of decimal formats

	includes_processed: BOOLEAN
			-- Has import/include processing been performed?

	default_validation: INTEGER
			-- Default validation

	precedence: INTEGER is
			-- Import precedence of `Current'
		do
			if was_included then
				Result := importer.precedence
			else
				Result := import_precedence
			end
		end
	
	namespace_alias (a_uri_code: INTEGER): INTEGER is
			-- Declared namespace alias for a given namespace URI code if there is one.
			-- If there is more than one, we get the last.
		local
			an_index: INTEGER
		do
			if not has_namespace_aliases then
				Result := -1
			else
			
				-- if there are several matches, the last in stylesheet takes priority;
				-- but the list is in reverse stylesheet order
				
				from
					an_index := 1
				variant
					namespace_alias_uri_codes.count + 1 - an_index
				until
					an_index > namespace_alias_uri_codes.count
				loop
					if a_uri_code = namespace_alias_uri_codes.item (an_index) then
						Result := namespace_alias_namespace_codes.item (an_index)
						an_index := namespace_alias_uri_codes.count + 1
					else
						an_index := an_index + 1
					end
				end
			end
		end

	find_collator (a_collator_uri: STRING): ST_COLLATOR is
			-- Does `a_collator_uri' represent a defined collator?
		require
			collator_uri_not_void: a_collator_uri /= Void
			collator_is_defined: is_collator_defined (a_collator_uri)
		do
			Result := collation_map.item (a_collator_uri)
		ensure
			collator_not_void: Result /= Void
		end

	module_number (a_system_id: STRING): INTEGER is
			-- Module number of `a_system_id'
		require
			system_id_not_void: a_system_id /= Void
			module_registered: is_module_registered (a_system_id)
		do
			Result := stylesheet_module_map.item (a_system_id)
		end

feature -- Status report

	was_included: BOOLEAN
			-- Was `Current' pulled in by xsl:include?

	indices_built: BOOLEAN
			-- Have the indices been built?

	is_module_registered (a_system_id: STRING): BOOLEAN is
			-- Is `a_system_id' registered as a module?
		require
			system_id_not_void: a_system_id /= Void
		do
			Result := stylesheet_module_map.has (a_system_id)
		end

	has_namespace_aliases: BOOLEAN is
			-- Have any namespace aliases been declared?
		do
			Result := namespace_alias_uri_codes /= Void
		end

	is_alias_result_namespace (a_uri_code: INTEGER): BOOLEAN is
			-- Is `a_uri_code' included in the result-prefix of a namespace-alias?
		local
			an_index: INTEGER
		do
			if	namespace_alias_namespace_codes /= Void then
				from
					an_index := 1
				variant
					namespace_alias_namespace_codes.count + 1 - an_index
				until
					an_index > namespace_alias_namespace_codes.count
				loop
					if a_uri_code = uri_code_from_namespace_code (namespace_alias_namespace_codes.item (an_index)) then
						Result := True
						an_index := namespace_alias_namespace_codes.count + 1
					else
						an_index := an_index + 1
					end
				end
			end
		end

	is_collator_defined (a_collator_uri: STRING): BOOLEAN is
			-- Does `a_collator_uri' represent a defined collator?
		require
			collator_uri_not_void: a_collator_uri /= Void
		do
			Result := collation_map.has (a_collator_uri)
		end

feature -- Element change

	register_module (a_system_id: STRING) is
			-- Register `a_system_id' as a stylesheet module.
		require
			system_id_not_void: a_system_id /= Void
			module_not_registered: not is_module_registered (a_system_id)
		do
			if stylesheet_module_map.is_full then
				stylesheet_module_map.resize (2 * stylesheet_module_map.count)
			end
			stylesheet_module_map.put (stylesheet_module_map.count + 1, a_system_id)
		ensure
			module_registered: is_module_registered (a_system_id)
		end

	declare_collation (a_name: STRING; a_collator: ST_COLLATOR) is
			-- Declare a collation.
		require
			collation_name_not_void: a_name /= Void -- TODO and then is a URI
			collator_not_void: a_collator /= Void
		do
			if collation_map.has (a_name) then
				collation_map.replace (a_collator, a_name)
			else
				if collation_map.is_full then
					collation_map.resize (2 * collation_map.count)
				end
				collation_map.put (a_collator, a_name)
			end
		ensure
			collator_declared: is_collator_defined (a_name)
		end

	allocate_local_slots (a_variable_count: INTEGER) is
			-- Ensure there is enough space for local variables or parameters in any template.
		require
			positive_variable_count: a_variable_count >= 0
		do
			if a_variable_count > largest_stack_frame then
				largest_stack_frame := a_variable_count
			end
		ensure
			no_smaller: largest_stack_frame >= old largest_stack_frame
		end

	prepare_attributes is
			-- Set the attribute list for the element.
		local
			a_cursor: DS_ARRAYED_LIST_CURSOR [INTEGER]
			a_name_code: INTEGER
			an_expanded_name: STRING
		do
			default_validation := Validation_strip
			from
				a_cursor := attribute_collection.name_code_cursor
				a_cursor.start
			until
				a_cursor.after
			loop
				a_name_code := a_cursor.item
				an_expanded_name := document.name_pool.expanded_name_from_name_code (a_name_code)
				if STRING_.same_string (an_expanded_name, Version_attribute) then
					do_nothing
				elseif STRING_.same_string (an_expanded_name, Extension_element_prefixes_attribute) then
					do_nothing
				elseif STRING_.same_string (an_expanded_name, Exclude_result_prefixes_attribute) then
					do_nothing
				elseif STRING_.same_string (an_expanded_name, Id_attribute) then
					do_nothing
				elseif STRING_.same_string (an_expanded_name, Default_validation_attribute) then
					default_validation := validation_code (attribute_value_by_index (a_cursor.index))
					if default_validation = Validation_invalid then
						report_compile_error ("Invalid value for default-validation attribute. Permitted values are (strict, lax, preserve, strip)")
					elseif conformance.basic_xslt_processor and then default_validation /= Validation_strip then
						report_compile_error ("Invalid value for default-validation attribute. Only 'strip' is permitted for a basic XSLT processor)")
					end
				else
					check_unknown_attribute (a_name_code)
				end
				a_cursor.forth
			end
			if version = Void then
				report_absence ("version")
			end
			attributes_prepared := True
		end

	set_prepared_stylesheet (a_prepared_stylesheet: like prepared_stylesheet) is
			-- Set `prepared_stylesheet'.
		require
			prepared_stylesheet_not_void: a_prepared_stylesheet /= Void
		do
			prepared_stylesheet := a_prepared_stylesheet
			target_name_pool := a_prepared_stylesheet.target_name_pool
			create rule_manager.make
		ensure
			prepared_stylesheet_set: prepared_stylesheet = a_prepared_stylesheet
		end

	preprocess is
			-- Perform all the processing possible before the source document is available.
			-- Done once per stylesheet, so the stylesheet can be reused for multiple source documents.
		require
			indices_not_built: not indices_built
		local
			a_cursor: DS_ARRAYED_LIST_CURSOR [XM_XSLT_STYLE_ELEMENT]
			a_style_element: XM_XSLT_STYLE_ELEMENT
		do

			-- Process any xsl:include and xsl:import elements.

			splice_includes

			-- Build indices for selected top-level elements.

			build_indices

			-- Process the attributes of every node in the tree

			process_all_attributes

			-- Collect any namespace aliases.

			collect_namespace_aliases

			-- Fix up references from XPath expressions to variables and functions, for static typing

			from
				a_cursor := top_level_elements.new_cursor
				a_cursor.start
			variant
				top_level_elements.count + 1 - a_cursor.index
			until
				a_cursor.after
			loop
				a_style_element ?= a_cursor.item
				if a_style_element /= Void then
					a_style_element.fixup_references
				end
				
				a_cursor.forth
			end

			-- Validate the whole logical style sheet (i.e. with included and imported sheets)

			validate
				from
				a_cursor := top_level_elements.new_cursor
				a_cursor.start
			variant
				top_level_elements.count + 1 - a_cursor.index
			until
				a_cursor.after
			loop
				a_style_element ?= a_cursor.item
				if a_style_element /= Void then
					a_style_element.validate_subtree
				end
				
				a_cursor.forth
			end
			post_validated := True
		ensure
			indices_built: indices_built
		end

	splice_includes is
			-- Process xsl:include and xsl:import elements.
		require
			includes_not_processed: not includes_processed
		local
			a_previous_style_element: XM_XSLT_STYLE_ELEMENT
			a_child_iterator: XM_XPATH_SEQUENCE_ITERATOR [XM_XPATH_NODE]
			a_child: XM_XPATH_NODE
			a_data_element: XM_XSLT_DATA_ELEMENT
			a_module: XM_XSLT_MODULE
			found_non_import: BOOLEAN
		do
			create top_level_elements.make (children.count)
			minimum_import_precedence := import_precedence
			a_previous_style_element := Current
			register_module (system_id)
			from
				a_child_iterator := new_axis_iterator (Child_axis)
				a_child_iterator.start
			until
				a_child_iterator.after
			loop
				a_child := a_child_iterator.item
				if a_child.node_type = Text_node then

					-- In an embedded stylesheet, white space nodes may still be there

					if not is_all_whitespace (a_child.string_value) then
						 a_previous_style_element.report_compile_error ("No character data is allowed between top-level elements")
					end
				else
					a_data_element ?= a_child
					if a_data_element /= Void then
						found_non_import := True
					else
						a_previous_style_element ?= a_child
						check
							child_is_style_element: a_previous_style_element /= Void
							-- Only data elements, style elements and white-space text nodes may be present
						end
						a_module ?= a_child
						if a_module /= Void then
							todo ("splice_includes", True)
						else
							found_non_import := True
							if not top_level_elements.extendible (1) then
								top_level_elements.resize (2 * top_level_elements.count)
							end
							top_level_elements.put_last (a_previous_style_element)
						end
					end
				end
				a_child_iterator.forth
			end
		end

	process_all_attributes is
			-- Process the attributes of every node in the stylesheet.
		local
			a_cursor: DS_ARRAYED_LIST_CURSOR [XM_XSLT_STYLE_ELEMENT]
			a_style_element: XM_XSLT_STYLE_ELEMENT
		do
			create static_context.make (Current)
			process_attributes
			from
				a_cursor := top_level_elements.new_cursor
				a_cursor.start
			variant
				top_level_elements.count + 1 - a_cursor.index
			until
				a_cursor.after
			loop
				a_style_element ?= a_cursor.item
				if a_style_element /= Void then
					a_style_element.process_all_attributes
				end
				a_cursor.forth
			end
			includes_processed := True
		ensure then
			includes_processed: includes_processed		
		end

	validate is
			-- Check that the stylesheet element is valid.
			-- This is called once for each element, after the entire tree has been built.
			-- As well as validation, it can perform first-time initialisation.
		local
			a_document: XM_XPATH_DOCUMENT
		do
			if validation_error_message /= Void then
				report_compile_error (validation_error_message)
			else
				a_document ?= parent
				if a_document = Void then
					report_compile_error (STRING_.appended_string (node_name, " must be the outermost element"))
				end
			end
			validated := True
		end

	compile (an_executable: XM_XSLT_EXECUTABLE; compile_to_eiffel: BOOLEAN) is
			-- Compile `Current' to an excutable instruction, or to Eiffel code.
		do
			do_nothing -- `compile_stylesheet' is used instead
		end

	compile_stylesheet (a_configuration: XM_XSLT_CONFIGURATION; compile_to_eiffel: BOOLEAN) is
			-- Compile `Current' to an excutable instruction, or to Eiffel code.
		require
			configuration_not_void: a_configuration /= Void
			compile_to_eiffel_not_supported: not compile_to_eiffel
		local
			an_executable: XM_XSLT_EXECUTABLE
			a_cursor: DS_ARRAYED_LIST_CURSOR [XM_XSLT_STYLE_ELEMENT]
			an_instruction: XM_XSLT_INSTRUCTION
		do
			create an_executable.make (a_configuration)

			-- Call compile method for each top-level object in the stylesheet

			from
				a_cursor := top_level_elements.new_cursor
				a_cursor.start
			variant
				top_level_elements.count + 1 - a_cursor.index
			until
				any_compile_errors or else a_cursor.after
			loop
				a_cursor.item.compile (an_executable, compile_to_eiffel)
				if not compile_to_eiffel then
					if a_cursor.item.any_compile_errors then
						any_compile_errors := True -- this shouldn't happen
					else
						an_instruction := a_cursor.item.last_generated_instruction						
						-- TODO: add location information to the compiled instruction
					end
				else
					todo ("compile - compile-to-Eiffel not implemented", True)
				end
				a_cursor.forth
			end
				
			todo ("compile_stylesheet", True)
		end

feature {XM_XSLT_STYLE_ELEMENT} -- Local

	is_global_variable_declared (a_fingerprint: INTEGER): BOOLEAN is
			-- Does `a_fingerprint' represent a global variable?
		do
			if principal_stylesheet = Current then
				Result := variables_index.has (a_fingerprint)
			else
				check
					is_global_variable_declared_called_for_non_principal_stylesheet: False
				end
			end
		end

	bind_global_variable (a_fingerprint: INTEGER; a_static_context: XM_XSLT_EXPRESSION_CONTEXT) is
			-- Bind variable to it's declaration.
		require
			variable_declared: is_global_variable_declared (a_fingerprint)
			static_context_not_void: a_static_context /= Void
		do
			a_static_context.set_last_bound_variable (variables_index.item (a_fingerprint))
		ensure
			variable_bound: a_static_context.last_bound_variable /= Void
		end
	
feature {NONE} -- Implementation

	named_templates_index: DS_HASH_TABLE [XM_XSLT_TEMPLATE, INTEGER]
			-- Index of named templates by `template_fingerprint'
	
	variables_index: DS_HASH_TABLE [XM_XSLT_VARIABLE_DECLARATION, INTEGER]
			-- Index of varaibles by `variable_fingerprint'

			-- These next three are only used at compile time

	namespace_alias_list: DS_ARRAYED_LIST [XM_XSLT_NAMESPACE_ALIAS]
			-- List of namespace aliases

	namespace_alias_uri_codes: ARRAY [INTEGER]
			-- URI codes for each namespace alias

	namespace_alias_namespace_codes: ARRAY [INTEGER]
			-- Namespace codes for each namespace alias

	largest_stack_frame: INTEGER
			-- Maximum number of local variables in any template

	collation_map: DS_HASH_TABLE [ST_COLLATOR, STRING]
			-- Map of collation names to collators

	stylesheet_module_map: DS_HASH_TABLE [INTEGER, STRING]
			-- Map of SYSTEM IDs to module numbers

	build_indices is
			-- Build indices from selected top-level declarations.
		require
			indices_not_built: not indices_built
		local
			a_template: XM_XSLT_TEMPLATE
			a_variable_declaration: XM_XSLT_VARIABLE_DECLARATION
			a_namespace_alias: XM_XSLT_NAMESPACE_ALIAS
			a_cursor: DS_ARRAYED_LIST_CURSOR [XM_XSLT_STYLE_ELEMENT]
		do
			from
				a_cursor := top_level_elements.new_cursor
				a_cursor.finish
			until
				a_cursor.before
			loop
				a_template ?= a_cursor.item
				if a_template /= Void  then
					index_named_template (a_template)
				else
					a_variable_declaration ?= a_cursor.item
					if a_variable_declaration /= Void then
						index_variable_declaration (a_variable_declaration)
					else
						a_namespace_alias ?= a_cursor.item
						if a_namespace_alias /= Void then
							if not namespace_alias_list.extendible (1) then
								namespace_alias_list.resize (2 * namespace_alias_list.count)
							end
							namespace_alias_list.put_last (a_namespace_alias)
						end
					end
				end
				a_cursor.back
			end
			indices_built := True
		ensure
			indices_built: indices_built
		end

	index_named_template (a_template: XM_XSLT_TEMPLATE) is
			-- Conditionally add an index entry for `a_template'.
		require
			indices_not_built: not indices_built
			template_not_void: a_template /= Void
		local
			a_fingerprint: INTEGER
			another_template: XM_XSLT_TEMPLATE
			a_message: STRING
		do
			a_fingerprint := a_template.template_fingerprint
			if a_fingerprint /= -1 then

				-- Named template

				if named_templates_index.has (a_fingerprint) then

					-- Check the precedence.

					another_template := named_templates_index.item (a_fingerprint)
					if a_template.precedence = another_template.precedence then
						a_message := STRING_.appended_string ("Duplicate named template (see line ", "0") -- TODO another_template.line_number)
						a_message := STRING_.appended_string (a_message, " of ")
						-- TODO						a_message := STRING_.appended_string (a_message, another_template.system_id)
						a_message := STRING_.appended_string (a_message, ")")
						a_template.report_compile_error (a_message)
					elseif a_template.precedence < another_template.precedence then
						a_template.set_redundant_named_template
					else

						-- This is not supposed to happen

						another_template.set_redundant_named_template
						named_templates_index.replace (a_template, a_fingerprint)
					end
				else
					if named_templates_index.is_full then
						named_templates_index.resize (2 * named_templates_index.count)
					end
					named_templates_index.put (a_template, a_fingerprint)
				end
			end
		end

	index_variable_declaration (a_variable_declaration: XM_XSLT_VARIABLE_DECLARATION) is
			-- Conditionally add an index entry for `a_variable_declaration'.
		require
			indices_not_built: not indices_built
			variable_declaration_not_void: a_variable_declaration /= Void
		local
			a_fingerprint: INTEGER
			another_variable: XM_XSLT_VARIABLE_DECLARATION
			a_message: STRING
		do
			a_fingerprint := a_variable_declaration.variable_fingerprint
			if a_fingerprint /= -1 then

				-- See if there is already a global variable with this precedence

				if variables_index.has (a_fingerprint) then

					-- Check the precedence

					another_variable := variables_index.item (a_fingerprint)
					if another_variable.precedence = a_variable_declaration.precedence then
						a_message := STRING_.appended_string ("Duplicate global variable declaration (see line ", "0") -- TODO another_variable.line_number)
						a_message := STRING_.appended_string (a_message, " of ")
						-- TODO						a_message := STRING_.appended_string (a_message, another_variable.system_id)
						a_message := STRING_.appended_string (a_message, ")")
						a_variable_declaration.report_compile_error (a_message)
					elseif a_variable_declaration.precedence < another_variable.precedence then
						a_variable_declaration.set_redundant_variable
					else
						
						-- This is not supposed to happen

						another_variable.set_redundant_variable
						variables_index.replace (a_variable_declaration, a_fingerprint)
					end
				else
					if variables_index.is_full then
						variables_index.resize (2 * variables_index.count)
					end
					variables_index.put (a_variable_declaration, a_fingerprint)
				end
			end
		end

	collect_namespace_aliases is
			-- Collect any namespace aliases.
		require
			indices_built: indices_built
			namespaces_alias_list_not_void: namespace_alias_list /= Void
		local
			a_precedence_boundary, a_current_precedence, a_precedence, a_uri_code, a_namespace_code, an_index: INTEGER
			an_alias: XM_XSLT_NAMESPACE_ALIAS
			a_cursor: DS_ARRAYED_LIST_CURSOR [XM_XSLT_NAMESPACE_ALIAS]			
		do
			if namespace_alias_list.count > 0 then
				create namespace_alias_namespace_codes.make (1, namespace_alias_list.count)
				create namespace_alias_uri_codes.make (1, namespace_alias_list.count)
				a_current_precedence := -1

				-- Note that we are processing the list in reverse stylesheet order,
				--  that is, highest precedence first (as `build_indices' proceeds in that order).

				from
					a_cursor := namespace_alias_list.new_cursor
					a_cursor.start
				variant
					namespace_alias_list.count + 1 - a_cursor.index
				until
					a_cursor.after
				loop
					an_alias := a_cursor.item
					a_uri_code := an_alias.stylesheet_uri_code
					a_namespace_code := an_alias.result_namespace_code
					a_precedence := an_alias.precedence

					-- Check that there isn't a conflict with another xsl:namespace-alias
					--  at the same precedence

					if a_current_precedence /= a_precedence then
						a_current_precedence := a_precedence
						a_precedence_boundary := a_cursor.index
					end

					from
						an_index := a_precedence_boundary
					variant
						namespace_alias_list.count + 1 - an_index
					until
						an_index > namespace_alias_list.count
					loop
						if a_uri_code = namespace_alias_uri_codes.item (an_index) then
							if a_namespace_code \\ bits_20 /= namespace_alias_namespace_codes.item (an_index) // bits_20 then
								an_alias.report_compile_error ("Inconsistent namespace aliases")
							end
						end

						an_index := an_index + 1
					end

					namespace_alias_uri_codes.put (a_uri_code, a_cursor.index)
					namespace_alias_namespace_codes.put (a_namespace_code, a_cursor.index)

					a_cursor.forth
				end
				
			end
			namespace_alias_list := Void -- Now it can be garbage-collected
		ensure
			namespaces_alias_list_void: namespace_alias_list = Void
		end

invariant

	target_name_pool_not_void: target_name_pool /= Void
	named_templates_index_not_void: named_templates_index /= Void
	variables_index_not_void: variables_index /= Void
	positive_largest_stack_frame: largest_stack_frame >= 0
	key_manager_not_void: key_manager /= Void
	decimal_format_manager_not_void: decimal_format_manager /= Void
	stylesheet_module_map_not_void: stylesheet_module_map /= Void

end
