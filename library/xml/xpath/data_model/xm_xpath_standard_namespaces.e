indexing

	description:

		"Standard namespace URIs"

	library: "Gobo Eiffel XML Library"
	copyright: "Copyright (c) 2003, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class XM_XPATH_STANDARD_NAMESPACES

	-- all INTEGERs should be INTEGER_16
	
feature -- Access

	Null_prefix_index: INTEGER is 1
			-- The numeric code representing the null namespace

	Xml_prefix_index: INTEGER is 2
			-- Numeric code representing the XML namespace

	Xslt_prefix_index: INTEGER is 3
			-- Numeric code representing the XSLT namespace

	Null_uri: STRING is ""
			-- The null namespace
	
	Xml_uri: STRING is "http://www.w3.org/XML/1998/namespace"
			-- The reserved namespace for XML
	
	Xslt_uri: STRING is "http://www.w3.org/1999/XSL/Transform"
			-- The XSLT namespace

	Xml_schema_uri: STRING is "http://www.w3.org/2001/XMLSchema"
			-- The XML Schemas namespace (xs)

	Xml_schema_datatypes_uri: STRING is "http://www.w3.org/2001/XMLSchema-datatypes" 
			-- The XML Schemas datatypes namespace (xs)

	Xml_schema_instance_uri: STRING is "http://www.w3.org/2001/XMLSchema-instance"
			-- The XML Schema instance document namespace (xsi)

	Xpath_defined_datatypes_uri: STRING is "http://www.w3.org/2003/11/xpath-datatypes"
			-- Namespace for additional XPath-defined data types (xdt)

	Xpath_functions_uri: STRING is "http://www.w3.org/2003/11/xpath-functions"
			-- XPath functions and operators (fn)

	Microsoft_uri: STRING is "http://www.w3.org/TR/WD-xsl"
			-- Recognize the Microsoft namespace so we can give a suitably sarcastic error message
	
	Xhtml_uri: STRING is "http://www.w3.org/1999/xhtml"
			-- XHTML namespace

	Gexslt_eiffel_type_uri: STRING is "http://www.gobosoft.com/gexslt/eiffel-type"
			-- Namespace for extension functions written in Eiffel

feature -- Status report

	is_reserved_namespace (uri: STRING): BOOLEAN is
			-- Is `uri' a reserved namespace?
		require
			uri_not_void: uri /= Void
		do
			Result := uri.is_equal (Xslt_uri)
				or else uri.is_equal (Xpath_functions_uri)
				or else uri.is_equal (Xml_uri)
				or else uri.is_equal (Xml_schema_uri)
				or else uri.is_equal (Xml_schema_datatypes_uri)
				or else uri.is_equal (Xpath_defined_datatypes_uri)
				or else uri.is_equal (Xml_schema_instance_uri)
		end

end
