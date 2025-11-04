{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
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
                                                            runtimeInputs = [ pkgs.age ] ;
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
                                        expected ,
                                        encrypted ,
                                        identity ,
                                        failure ,
                                        pkgs ,
                                        resources ? null ,
                                        self ? null
                                    } :
                                        pkgs.stdenv.mkDerivation
                                            {
                                                installPhase =
                                                    ''
                                                        execute-test "$out"
                                                    '' ;
                                                name = "check" ;
                                                nativeBuildInputs =
                                                    [
                                                        (
                                                            pkgs.writeShellApplication
                                                                {
                                                                    name = "execute-test-attributes" ;
                                                                    runtimeInputs = [ pkgs.coreutils failure ] ;
                                                                    text =
                                                                        let
                                                                            init = implementation { pkgs = pkgs ; resources = resources ; self = self ; } ;
                                                                            instance = implementation { encrypted = encrypted ; identity = identity ; } ;
                                                                            in
                                                                                ''
                                                                                    OUT="$1"
                                                                                    touch "$OUT"
                                                                                    ${ if [ "init" "targets" ] != builtins.attrNames instance then ''failure c8b01223 "We expected the secret names to be init targets but we observed ${ builtins.toJSON ( builtins.attrNames instance ) }"'' else "#" }
                                                                                    ${ if expected != init then ''failure 2e2ca58a "We expected the init to be ${ builtins.toString expected } but we observed ${ builtins.toString init }"'' else "#" }
                                                                                    ${ if [ "secret" ] != instance.targets then ''failure 2c9823c8 "We expected the targets to be secret but we observed ${ builtins.toJSON instance.targets }"'' else "#" }
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