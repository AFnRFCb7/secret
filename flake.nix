
{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { failure } :
                        let
                            implementation =
                                { setup } :
                                    {
                                        init =
                                            { mount , pkgs , resources , root , wrap } @primary :
                                                let
                                                    application =
                                                        pkgs.writeShellApplication
                                                            {
                                                                name = "init" ;
                                                                runtimeInputs = [ pkgs.age pkgs.coreutils ] ;
                                                                text =
                                                                    let
                                                                        stage =
                                                                            let
                                                                                application =
                                                                                    pkgs.writeShellApplication
                                                                                        {
                                                                                            name = "stage" ;
                                                                                            runtimeInputs = [ pkgs.coreutils ] ;
                                                                                            text = setup primary ;
                                                                                        } ;
                                                                                in "${ application }/bin/stage" ;
                                                                        in
                                                                            ''
                                                                                ${ stage }
                                                                                age --decrypt --identity /scratch/identity /scratch/encrypted > /mount/secret
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
                                            setup ,
                                            failure ,
                                            mount ? null ,
                                            pkgs ,
                                            resources ? null ,
                                            root ? "e6471e78" ,
                                            wrap ? "66ff96f9"
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
                                                                                init = instance.init { mount = mount ; pkgs = pkgs ; resources = resources ; root = root ; wrap = wrap ; } ;
                                                                                instance = implementation { setup = setup ; } ;
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