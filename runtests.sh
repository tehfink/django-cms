#!/bin/bash
cd tests

args=("$@")
num_args=${#args[@]}
index=0

reuse_env=false
disable_coverage=false

while [ "$index" -lt "$num_args" ]
do
    case "${args[$index]}" in
        "--failfast")
            failfast="--failfast"
            ;;

        "--reuse-env")
            reuse_env=true
            ;;

        "--disable-coverage")
            disable_coverage=true
            ;;

        "--help")
            echo ""
            echo "usage:"
            echo "    runtests.sh"
            echo "    or runtests.sh [testcase]"
            echo "    or runtests.sh [flags] [testcase]"
            echo ""
            echo "flags:"
            echo "    --failfast - abort at first failing test"
            echo "    --disable-coverage - don't use coverage"
            echo "    --reuse-env - don't run builout, use last built environment" 
            exit 1
            ;;

        *)
            suite="cms.${args[$index]}"
    esac
    let "index = $index + 1"
done

if [ $reuse_env == false ]; then
    echo "setting up test environment (this might take a while)..."
    python bootstrap.py
    if [ $? != 0 ]; then
        echo "bootstrap.py failed"
        exit 1
    fi
    ./bin/buildout
    if [ $? != 0 ]; then
        echo "bin/buildout failed"
        exit 1
    fi
else
    echo "reusing current buildout environment"
fi

if [ "$failfast" ]; then
    echo "--failfast supplied, not using xmlrunner."
fi

if [ ! "$suite" ]; then
    suite="cms"
    echo "Running complete cms testsuite."
else
    echo "Running cms test $suite."
fi

if [ $disable_coverage == false ]; then
    ./bin/coverage run --rcfile=.coveragerc testapp/manage.py test $suite $failfast
    retcode=$?

    echo "Post test actions..."
    ./bin/coverage xml
    ./bin/coverage html
else
    ./bin/django test $suite $failfast
    retcode=$?
fi
cd ..
echo "done"
exit $retcode
