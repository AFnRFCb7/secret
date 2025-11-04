{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { } :
                        let
                            implementation =
                                { encrypted , identity } :
                                    {
                                        init =
                                            { pkgs , resources , self } :
                                                let
                                                    application =
                                                        pkgs.writeShellApplication
                                                            {
                                                                name = "init" ;
                                                                runtimeInputs = [ pkgs.age pkgs.coreutils ] ;
                                                                text =
                                                                    ''
                                                                        IDENTITY=${ identity ( setup : setup ) }
                                                                        ENCRYPTED=${ encrypted ( setup : setup ) }
                                                                        age --decrypt --identity "$IDENTITY" "$ENCRYPTED" > /mount/secret
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
                                            coreutils ,
                                            expected ,
                                            encrypted ,
                                            identity ,
                                            failure ,
                                            mkDerivation ,
                                            pkgs ? null ,
                                            resources ? null ,
                                            self ? null ,
                                            writeShellApplication
                                        } :
                                            mkDerivation
                                                {
                                                    installPhase =
                                                        ''
                                                            execute-test "$0"
                                                        '' ;
                                                    name = "check" ;
                                                    nativeBuildInputs =
                                                        [
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test" ;
                                                                        runtimeInputs = [ coreutils ] ;
                                                                        text =
                                                                            let
                                                                                init = instance.init { pkgs = pkgs ; resources = resources ; self = self ; } ;
                                                                                instance = implementation { encrypted = encrypted ; identity = identity ; } ;
                                                                                in
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        touch "$OUT"
                                                                                        ${ if [ "init" "targets" ] != builtins.attrNames instance then ''failure e1f8ac79 "We expected that the attributes names would be init and targets but we observed ${ builtins.toJSON ( builtins.attrNames instance ) }"'' else "#" }
                                                                                        ${ if [ "secret" ] != instance.targets then ''failure c2f1383e "We expected that the targets would be secret but we observed ${ builtins.toJSON instance.targets }"'' else "#" }
                                                                                        ${ if init != expected then ''failure f146b9fb "We expected that the init would be ${ builtins.toString expected } but we observed ${ builtins.toString init }"'' else "#" }
                                                                                    '' ;
                                                                    }
                                                            )
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
                                                                                observed = builtins.toString ( x.init { pkgs = pkgs ; resources = resources ; self = self ; } ) ;
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