@rem
@rem Copyright 2020 the original author jacky.eastmoon
@rem All commad module need 3 method :
@rem [command]        : Command script
@rem [command]-args   : Command script options setting function
@rem [command]-help   : Command description
@rem Basically, CLI will not use "--options" to execute function, "--help, -h" is an exception.
@rem But, if need exception, it will need to thinking is common or individual, and need to change BREADCRUMB variable in [command]-args function.
@rem NOTE, batch call [command]-args it could call correct one or call [command] and "-args" is parameter.
@rem

:: ------------------- batch setting -------------------
@rem setting batch file
@rem ref : https://www.tutorialspoint.com/batch_script/batch_script_if_else_statement.htm
@rem ref : https://poychang.github.io/note-batch/

@echo off
setlocal
setlocal enabledelayedexpansion

:: ------------------- declare CLI file variable -------------------
@rem retrieve project name
@rem Ref : https://www.robvanderwoude.com/ntfor.php
@rem Directory = %~dp0
@rem Object Name With Quotations=%0
@rem Object Name Without Quotes=%~0
@rem Bat File Drive = %~d0
@rem Full File Name = %~n0%~x0
@rem File Name Without Extension = %~n0
@rem File Extension = %~x0

set CLI_DIRECTORY=%~dp0
set CLI_FILE=%~n0%~x0
set CLI_FILENAME=%~n0
set CLI_FILEEXTENSION=%~x0

:: ------------------- declare CLI variable -------------------

set BREADCRUMB=cli
set COMMAND=
set COMMAND_BC_AGRS=
set COMMAND_AC_AGRS=

:: ------------------- declare variable -------------------

for %%a in ("%cd%") do (
    set PROJECT_NAME=%%~na
)
set PROJECT_ENV=dev
set PROJECT_SSH_USER=somesshuser
set PROJECT_SSH_PASS=somesshpass

:: ------------------- execute script -------------------

call :main %*
goto end

:: ------------------- declare function -------------------

:main (
    call :argv-parser %*
    call :%BREADCRUMB%-args %COMMAND_BC_AGRS%
    call :main-args %COMMAND_BC_AGRS%
    IF defined COMMAND (
        set BREADCRUMB=%BREADCRUMB%-%COMMAND%
        call :main %COMMAND_AC_AGRS%
    ) else (
        call :%BREADCRUMB%
    )
    goto end
)
:main-args (
    for %%p in (%*) do (
        if "%%p"=="-h" ( set BREADCRUMB=%BREADCRUMB%-help )
        if "%%p"=="--help" ( set BREADCRUMB=%BREADCRUMB%-help )
    )
    goto end
)
:argv-parser (
    set COMMAND=
    set COMMAND_BC_AGRS=
    set COMMAND_AC_AGRS=
    set is_find_cmd=
    for %%p in (%*) do (
        IF NOT defined is_find_cmd (
            echo %%p | findstr /r "\-" >nul 2>&1
            if errorlevel 1 (
                set COMMAND=%%p
                set is_find_cmd=TRUE
            ) else (
                set COMMAND_BC_AGRS=!COMMAND_BC_AGRS! %%p
            )
        ) else (
            set COMMAND_AC_AGRS=!COMMAND_AC_AGRS! %%p
        )
    )
    goto end
)

:: ------------------- Main mathod -------------------

:cli (
    goto cli-help
)

:cli-args (
    goto end
)

:cli-help (
    echo This is a Command Line Interface with project %PROJECT_NAME%
    echo If not input any command, at default will show HELP
    echo.
    echo Options:
    echo      --help, -h        Show more information with CLI.
    echo.
    echo Command:
    echo      angular           Build client website for angular.
    echo      node              Control node server.
    echo      dotnet            Control .net core server.
    echo.
    echo Run 'cli [COMMAND] --help' for more information on a command.
    goto end
)

:: ------------------- Command "angular" mathod -------------------

:cli-angular (
    @rem Initial cache
    IF NOT EXIST cache\angular\modules (
        mkdir cache\angular\modules
    )
    IF NOT EXIST cache\angular\publish (
        mkdir cache\angular\publish
    )
    echo ^> Build image
    docker build --rm^
        -t msw.angular:%PROJECT_NAME%^
        ./docker/client/angular

    echo ^> Startup docker container instance
    docker rm -f %PROJECT_NAME%-client-angular
    docker run -ti -d ^
        -v %cd%\src\client\angular\:/repo^
        -v %cd%\cache\angular\modules/:/repo/node_modules^
        -v %cd%\cache\angular\publish/:/repo/dist^
        -p 8083:4200^
        --name %PROJECT_NAME%-client-angular^
        msw.angular:%PROJECT_NAME%

    echo ^> Install package dependencies
    docker exec -ti %PROJECT_NAME%-client-angular bash -l -c "yarn install"

    @rem Execute command
    IF defined DEVELOPER_ANGULAR (
        echo ^> Start deveopment server
        docker exec -ti %PROJECT_NAME%-client-angular bash -l -c "ng serve --host 0.0.0.0"
    )
    IF defined INTO_ANGULAR (
        echo ^> Into container instance
        docker exec -ti %PROJECT_NAME%-client-angular bash
    )
    IF defined BUILD_ANGULAR (
        echo ^> Build project
        docker exec -ti %PROJECT_NAME%-client-angular bash -l -c "yarn build"
    )

    @rem close server
    docker rm -f %PROJECT_NAME%-client-angular
    goto end
)

:cli-angular-args (
    set BUILD_ANGULAR=1
    for %%p in (%*) do (
        if "%%p"=="--dev" (
            set DEVELOPER_ANGULAR=1
            set BUILD_ANGULAR=
        )
        if "%%p"=="--into" (
            set INTO_ANGULAR=1
            set BUILD_ANGULAR=
        )
    )
    goto end
)

:cli-angular-help (
    echo Build angular.js project.
    echo.
    echo Options:
    echo      --dev             Run dev mode.
    echo      --into            Go into container.
    echo.
    goto end
)

:: ------------------- Command "node" mathod -------------------

:cli-node (
    @rem Initial cache
    IF NOT EXIST cache\node\modules (
        mkdir cache\node\modules
    )
    IF NOT EXIST cache\node\publish (
        mkdir cache\node\publish
    )

    IF defined BUILD_NODE (
        echo ^> Publish server
        docker build --rm^
            -t msw.node:publish^
            ./src/server/node
        docker save ^
            --output %cd%\cache\node\publish\server.tar^
            msw.node:publish
    ) else (

        echo ^> Build image
        docker build --rm^
            -t msw.node:%PROJECT_NAME%^
            ./docker/server/node

        echo ^> Startup docker container instance
        docker rm -f %PROJECT_NAME%-server-node
        docker run -ti -d ^
            -v %cd%\src\server\node\:/repo^
            -v %cd%\cache\node\modules/:/repo/node_modules^
            -p 8001:3000^
            --name %PROJECT_NAME%-server-node^
            msw.node:%PROJECT_NAME%

        echo ^> Install package dependencies
        docker exec -ti %PROJECT_NAME%-server-node bash -l -c "yarn install"

        @rem Execute command
        IF defined DEVELOPER_NODE (
            echo ^> Start deveopment server
            docker exec -ti %PROJECT_NAME%-server-node bash -l -c "yarn start"
        )
        IF defined INTO_NODE (
            echo ^> Into container instance
            docker exec -ti %PROJECT_NAME%-server-node bash
        )

        @rem close server
        docker rm -f %PROJECT_NAME%-server-node
    )
    goto end
)

:cli-node-args (
    set BUILD_NODE=1
    for %%p in (%*) do (
        if "%%p"=="--dev" (
            set DEVELOPER_NODE=1
            set BUILD_NODE=
        )
        if "%%p"=="--into" (
            set INTO_NODE=1
            set BUILD_NODE=
        )
    )
    goto end
)

:cli-node-help (
    echo Build angular.js project.
    echo.
    echo Options:
    echo      --dev             Run dev mode.
    echo      --into            Go into container.
    echo.
    goto end
)

:: ------------------- Command "dotnet" mathod -------------------

:cli-dotnet (
    @rem Initial cache
    IF NOT EXIST cache\dotnet\publish (
        mkdir cache\dotnet\publish
    )

    echo ^> Build image
    docker build --rm^
        -t msw.dotnet:%PROJECT_NAME%^
        ./docker/server/dotnet

    echo ^> Startup docker container instance
    docker rm -f %PROJECT_NAME%-server-dotnet
    docker run -ti -d ^
        -v %cd%\src\server\dotnet\:/repo^
        -p 5000:5000^
        -p 5001:5001^
        --name %PROJECT_NAME%-server-dotnet^
        msw.dotnet:%PROJECT_NAME%

    @rem Execute command
    IF defined DEVELOPER_DOTNET (
        echo ^> Start deveopment server
        docker exec -ti %PROJECT_NAME%-server-dotnet bash -l -c "dotnet run"
    )
    IF defined INTO_DOTNET (
        echo ^> Into container instance
        docker exec -ti %PROJECT_NAME%-server-dotnet bash
    )
    IF defined BUILD_DOTNET (
        echo ^> Publish server
        docker exec -ti %PROJECT_NAME%-server-dotnet bash -l -c "rm -rf published && dotnet publish --configuration Release -o published"
        docker build --rm^
            -t msw.dotnet:publish^
            ./src/server/dotnet
        docker save ^
            --output %cd%\cache\dotnet\publish\server.tar^
            msw.dotnet:publish
    )

    @rem close server
    docker rm -f %PROJECT_NAME%-server-dotnet
    goto end
)

:cli-dotnet-args (
    set BUILD_DOTNET=1
    for %%p in (%*) do (
        if "%%p"=="--dev" (
            set DEVELOPER_DOTNET=1
            set BUILD_DOTNET=
        )
        if "%%p"=="--into" (
            set INTO_DOTNET=1
            set BUILD_DOTNET=
        )
    )
    goto end
)

:cli-dotnet-help (
    echo Build angular.js project.
    echo.
    echo Options:
    echo      --dev             Run dev mode.
    echo      --into            Go into container.
    echo.
    goto end
)

:: ------------------- End method-------------------

:end (
    endlocal
)
