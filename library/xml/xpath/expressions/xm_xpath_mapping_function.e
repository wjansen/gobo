indexing

	description:

	"Objects that can be passed to an XM_XPATH_MAPPING_ITERATOR.%
	%Such objects, when given an XM_XPATH_ITEM, can generate an%
	%XM_XPATH_SEQUENCE_ITERATOR [XM_XPATH_ITEM] which delivers%
	%a series of such items."

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

deferred class XM_XPATH_MAPPING_FUNCTION

feature -- Evaluation

	map (an_item: XM_XPATH_ITEM; a_context: XM_XPATH_CONTEXT; an_information_object: ANY): XM_XPATH_MAPPED_ITEM is
			-- Map `an_item' to a sequence
		require
			item_not_void: an_item /= Void
--			context_item: a_context /= Void implies an_item.is_equal (a_context.context_item)
			information: True -- /= Void implies must be immutable and read-only for the duration of the iteration
		deferred
		end

end