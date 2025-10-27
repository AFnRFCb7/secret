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
                                                                        echo 8c127ed0-7763-49d5-8dad-4eacf26d952b >&2
                                                                        IDENTITY=${ identity ( setup : setup ) }
                                                                        echo 7f33b896-20a5-45c4-99db-231179a89edd >&2
                                                                        ENCRYPTED=${ encrypted ( setup : setup ) }
                                                                        echo 13d73313-0621-4bc9-8b06-969e1ef2bbc5 >&2
                                                                        age --decrypt --identity "$IDENTITY" "$ENCRYPTED" > /mount/secret
                                                                        echo 03c27d5a-129c-4337-925c-7b3b1f8cddc6 >&2
                                                                        chmod 0400 /mount/secret
                                                                        echo e1c9a9b7-fbd6-46e3-ae4f-1e4ce29f1059 >&2
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