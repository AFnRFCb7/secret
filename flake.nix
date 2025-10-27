{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { age , coreutils , writeShellApplication } :
                        let
                            implementation =
                                { encrypted , identity } :
                                    {
                                        init =
                                            { resources , self } :
                                                let
                                                    application =
                                                        writeShellApplication
                                                            {
                                                                name = "init" ;
                                                                runtimeInputs = [ age ] ;
                                                                text =
                                                                    ''
                                                                        IDENTITY=${ identity ( setup : setup ) }
                                                                        ENCRYPTED=${ encrypted ( setup : setup ) }
                                                                        age --identity "$IDENTITY" "$ENCRYPTED" > /mount/secret
                                                                        chmod 0400 /mount/secret
                                                                    '' ;
                                                            } ;
                                                    in "${ application }/bin/init" ;
                                        targets = [ "secret" ] ;
                                    } ;
                            in
                                {
                                    check =
                                        {
                                            expected ,
                                            encrypted ,
                                            identity ,
                                            failure ,
                                            mkDerivation ,
                                            resources ? null ,
                                            self ? null
                                        } :
                                            mkDerivation
                                                {
                                                    installPhase =
                                                        ''
                                                            execute-test-attributes "$out"
                                                            execute-test-init "$out"
                                                            execute-test-targets "$out"
                                                        '' ;
                                                    name = "check" ;
                                                    nativeBuildInputs =
                                                        [
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test-attributes" ;
                                                                        runtimeInputs = [ coreutils ( failure.implementation "375e898a" ) ] ;
                                                                        text =
                                                                            let
                                                                                x = implementation { encrypted = encrypted ; identity = identity ; } ;
                                                                                observed = builtins.attrNames x ;
                                                                                in
                                                                                    if [ "init" "targets" ] == observed
                                                                                    then
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                        ''
                                                                                    else
                                                                                        ''
                                                                                            OUT=$1
                                                                                            touch "$OUT"
                                                                                            failure 'attributes ${ builtins.toJSON observed }'
                                                                                        '' ;
                                                                    }
                                                            )
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test-init" ;
                                                                        runtimeInputs = [ coreutils ( failure.implementation "9507ef9d" ) ] ;
                                                                        text =
                                                                            let
                                                                                x = implementation { encrypted = encrypted ; identity = identity ; } ;
                                                                                observed = builtins.toString ( x.init { resources = resources ; self = self ; } ) ;
                                                                            in
                                                                                if expected == observed then
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        touch "$OUT"
                                                                                    ''
                                                                                else
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        touch "$OUT"
                                                                                        failure init "We expected ${ expected } but we observed ${ observed }"
                                                                                    '' ;
                                                                    }
                                                            )
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test-targets" ;
                                                                        runtimeInputs = [ coreutils ( failure.implementation "8eadd518" ) ] ;
                                                                        text =
                                                                            let
                                                                                x = implementation { encrypted = encrypted ; identity = identity ; } ;
                                                                                observed = x.targets ;
                                                                                in
                                                                                    if [ "secret" ] == observed
                                                                                    then
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                        ''
                                                                                    else
                                                                                        ''
                                                                                            OUT=$1
                                                                                            touch "$OUT"
                                                                                            failure targets
                                                                                        '' ;
                                                                    }
                                                            )
                                                        ] ;
                                                    src = ./. ;
                                                } ;
                                    implementation = implementation ;
                                } ;
            } ;
}