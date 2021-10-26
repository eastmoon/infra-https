@rem This batch script is work on build all project
@rem Build client

call dockerw angular

@rem Build server

call dockerw node
call dockerw dotnet
