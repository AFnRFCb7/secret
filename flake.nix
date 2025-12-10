{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { failure } :
                        let
                            implementation =
                                { encrypted , identity } :
                                    {
                                        init =
                                            { mount , pkgs , resources , wrap } :
                                                let
                                                    application =
                                                        pkgs.writeShellApplication
                                                            {
                                                                name = "init" ;
                                                                runtimeInputs = [ pkgs.age pkgs.coreutils ] ;
                                                                text =
                                                                    ''
                                                                        if [[ -t 0 ]]
                                                                        then
                                                                            # shellcheck disable=SC2034
                                                                            HAS_STANDARD_INPUT=false
                                                                            # shellcheck disable=SC2034
                                                                            STANDARD_INPUT=
                                                                        else
                                                                            # shellcheck disable=SC2034
                                                                            HAS_STANDARD_INPUT=true
                                                                            # shellcheck disable=SC2034
                                                                            STANDARD_INPUT="$( cat )" || failure ca6dd82a
                                                                        fi
                                                                        if $HAS_STANDARD_INPUT
                                                                        then
                                                                            IDENTITY=${ identity ( setup : ''echo "$STANDARD_INPUT" | ${ setup } "$@"'' ) }
                                                                            ENCRYPTED=${ encrypted ( setup : ''echo "$STANDARD_INPUT" | ${ setup } "@"'' ) }
                                                                        else
                                                                            IDENTITY=${ identity ( setup : ''${ setup } "$@"'' ) }
                                                                            ENCRYPTED=${ encrypted ( setup : ''${ setup } "@"'' ) }
                                                                        fi
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
                                            mount ? null ,
                                            pkgs ,
                                            resources ? null
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
                                                                        name = "execute-test" ;
                                                                        runtimeInputs = [ pkgs.coreutils failure ] ;
                                                                        text =
                                                                            let
                                                                                init = instance.init { mount = mount ; pkgs = pkgs ; resources = resources ; wrap = wrap ; } ;
                                                                                instance = implementation { encrypted = encrypted ; identity = identity ; } ;
                                                                                in
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        touch "$OUT"
                                                                                        ${ if [ "init" "targets" ] != builtins.attrNames instance then ''failure c8b01223 "We expected the secret names to be init targets but we observed ${ builtins.toJSON ( builtins.attrNames instance ) }"'' else "#" }
                                                                                        ${ if expected != init then ''failure 2e2ca58a "We expected the secret init to be ${ builtins.toString expected } but we observed ${ builtins.toString init }"'' else "#" }
                                                                                        ${ if [ "secret" ] != instance.targets then ''failure 2c9823c8 "We expected the secret targets to be secret but we observed ${ builtins.toJSON instance.targets }"'' else "#" }
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