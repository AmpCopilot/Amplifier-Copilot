; extractNetlistParams.il
; Function: Extract parameters from netlist file and set to current ADE L session

procedure( roundParamValue( value )
    let( (numPart unitPart floatVal result i ch)
        if( rexMatchp("^[0-9]+\\.[0-9]+[fpnumkMGT]$" value) then
            numPart = ""
            unitPart = ""
            for( i 1 strlen(value)
                ch = substring(value i i)
                if( rexMatchp("[0-9.]" ch) then
                    numPart = strcat(numPart ch)
                else
                    unitPart = substring(value i)
                    i = strlen(value) + 1
                )
            )
            when( numPart != ""
                floatVal = atof(numPart)
                floatVal = round(floatVal * 10.0) / 10.0
                sprintf(result "%.1f%s" floatVal unitPart)
                value = result
            )
        )
        value
    )
)

procedure( extractAndSetParams( netlistFile )
    let( (inPort line paramList varList session paramBlock inBlock tokens lineNum stopReading)
        unless( inPort = infile(netlistFile)
            error("Cannot open file: %s" netlistFile)
        )

        paramList = list()
        paramBlock = ""
        inBlock = nil
        stopReading = nil

        while( gets(line inPort) && !stopReading
            cond(
                (rexMatchp("subckt" line)
                    stopReading = t
                )
                (rexMatchp("parameters" line)
                    inBlock = t
                    tokens = parseString(line)
                    paramBlock = buildString(cdr(tokens) " ")
                )
                (inBlock
                    paramBlock = strcat(paramBlock " " line)
                    unless( rexMatchp("\\\\" line)
                        inBlock = nil
                    )
                )
            )
        )
        close(inPort)

        paramBlock = buildString(parseString(paramBlock "\\") " ")
        tokens = parseString(paramBlock)

        foreach( token tokens
            when( rexMatchp("=" token)
                parts = parseString(token "=")
                when( length(parts) == 2
                    paramName = car(parts)
                    paramValue = cadr(parts)
                    unless( rexMatchp("^_EXPR_" paramName)
                        paramValue = roundParamValue(paramValue)
                        paramList = append1(paramList list(paramName paramValue))
                    )
                )
            )
        )

        session = asiGetCurrentSession()
        unless( session
            error("No active ADE L session found. Please open ADE L window first.")
        )

        varList = foreach( mapcar param paramList
            list(car(param) cadr(param))
        )

        asiSetDesignVarList(session varList)

        printf("\n Successfully loaded %d parameters from netlist\n" length(paramList))
        printf(" Parameters set to ADE L session\n\n")

        paramList
    )
)
procedure( loadNetlistParams( @optional (netlistFile "Read_scs_Script/input_scs/1.scs") )
    let( (file)
        file = netlistFile

        when( file && file != ""
            extractAndSetParams(file)
        )
    )
)

; default
procedure( lnp( @optional (netlistFile "Read_scs_Script/input_scs/1.scs") )
    loadNetlistParams(netlistFile)
)

printf("\n========================================\n")
printf(" Netlist Parameter Loader Ready\n")
printf("========================================\n")
printf("Usage:\n")
printf("  lnp()                    - Load from default: Read_scs_Script/input_scs/1.scs\n")
printf("  lnp(\"path/to/file.scs\")  - Load from specified path\n")
printf("========================================\n\n")