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
                                                            execute-test "$out"
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
                                                        ] ;
                                                    src = ./. ;
                                                } ;
                                    implementation = implementation ;
                                } ;
            } ;
}