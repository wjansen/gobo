indexing

	description:

		"Eiffel classic consumers of .NET assemblies"

	library: "Gobo Eiffel Tools Library"
	copyright: "Copyright (c) 2006, Eric Bezault and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class ET_DOTNET_ASSEMBLY_CLASSIC_CONSUMER

inherit

	ET_DOTNET_ASSEMBLY_CONSUMER

create

	make

feature {ET_DOTNET_ASSEMBLY} -- Consuming

	consume_assembly (an_assembly: ET_DOTNET_ASSEMBLY) is
			-- Eiffel classic compilers are not able to consume .NET assemblies.
		do
			error_handler.report_gaaaa_error (an_assembly)
		end

	consume_gac_assembly (an_assembly: ET_DOTNET_GAC_ASSEMBLY) is
			-- Eiffel classic compilers are not able to consume .NET assemblies.
		do
			error_handler.report_gaaaa_error (an_assembly)
		end

end
