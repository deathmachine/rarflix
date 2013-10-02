'*****************************************************************
'**  Home screen: the entry display of the application
'**
'*****************************************************************

Function createHomeScreen(viewController) As Object
    ' At the end of the day, the home screen is just a grid with a custom loader.
    ' So create a regular grid screen and override/extend as necessary.
    obj = createGridScreen(viewController, "flat-square", "stop")

    obj.Screen.SetDisplayMode("photo-fit")
    obj.Loader = createHomeScreenDataLoader(obj)

    obj.Refresh = refreshHomeScreen

    obj.OnTimerExpired = homeScreenOnTimerExpired
    obj.SuperActivate = obj.Activate
    obj.Activate = homeScreenActivate

    obj.clockTimer = createTimer()
    obj.clockTimer.Name = "clock"
    obj.clockTimer.SetDuration(20000, true) ' A little lag is fine here
    viewController.AddTimer(obj.clockTimer, obj) 

    obj.npTimer = createTimer()
    obj.npTimer.Name = "nowplaying"
    obj.npTimer.SetDuration(10000, true) ' 10 seconds? too much?
    viewController.AddTimer(obj.npTimer, obj) 

    return obj
End Function

Sub refreshHomeScreen(changes)
    if type(changes) = "Boolean" and changes then
        changes = CreateObject("roAssociativeArray") ' hack for info button from grid screen (mark as watched) -- TODO later and find out why this is a Boolean
        'changes["servers"] = "true"
    end if
    ' printAny(5","1",changes) ' this prints better than printAA
    ' ljunkie Enum Changes - we could just look at changes ( but without _previous_ ) we don't know if this really changed.
    if changes.DoesExist("rf_hs_clock") and changes.DoesExist("_previous_rf_hs_clock") and changes["rf_hs_clock"] <> changes["_previous_rf_hs_clock"] then
        if changes["rf_hs_clock"] = "disabled" then
            m.Screen.SetBreadcrumbEnabled(false)
        else
            RRbreadcrumbDate(m)
        end if
    end if
    ' other rarflix changes?
    ' end ljunkie

    ' If myPlex state changed, we need to update the queue, shared sections,
    ' and any owned servers that were discovered through myPlex.
    if changes.DoesExist("myplex") then
        m.Loader.OnMyPlexChange()
    end if

    ' If a server was added or removed, we need to update the sections,
    ' channels, and channel directories.
    if changes.DoesExist("servers") then
        for each server in PlexMediaServers()
            if server.machineID <> invalid AND GetPlexMediaServer(server.machineID) = invalid then
                PutPlexMediaServer(server)
            end if
        next

        servers = changes["servers"]
        didRemove = false
        for each machineID in servers
            Debug("Server " + tostr(machineID) + " was " + tostr(servers[machineID]))
            if servers[machineID] = "removed" then
                DeletePlexMediaServer(machineID)
                didRemove = true
            else
                server = GetPlexMediaServer(machineID)
                if server <> invalid then
                    m.Loader.CreateServerRequests(server, true, false)
                end if
            end if
        next

        if didRemove then
            m.Loader.RemoveInvalidServers()
        end if
    end if

    ' Recompute our capabilities
    Capabilities(true)
End Sub

Sub ShowHelpScreen()
    header = "Welcome to Plex for Roku!"
    paragraphs = []
    paragraphs.Push("Plex for Roku automatically connects to Plex Media Servers on your local network and also works with myPlex to view queued items and connect to your published and shared servers.")
    paragraphs.Push("To download and install Plex Media Server on your computer, visit http://plexapp.com/getplex")
    paragraphs.Push("For more information on getting started, visit http://plexapp.com/roku")

    screen = createParagraphScreen(header, paragraphs, GetViewController())
    GetViewController().InitializeOtherScreen(screen, invalid)

    screen.Show()
End Sub


Sub homeScreenOnTimerExpired(timer)
    if timer.Name = "clock" AND m.ViewController.IsActiveScreen(m) then
        RRbreadcrumbDate(m.viewcontroller.screens[0])
        'm.Screen.SetBreadcrumbText("", CurrentTimeAsString())
    end if
    if timer.Name = "nowplaying" AND m.ViewController.IsActiveScreen(m) then
        ' print "update now playing"
        m.loader.NowPlayingChange() ' refresh now playing -- it will only update if available to eu
    else if timer.Name = "nowplaying" and type(m.viewcontroller.screens.peek()) = "roAssociativeArray" then
        screen = m.viewcontroller.screens.peek()
        if screen.metadata <> invalid and screen.metadata.nowplaying_user <> invalid then
            print "update NOW playing description with new time"
        end if
        ' to update!
        'm.metadata.description = "Progress: " + GetDurationString(int(m.metadata.viewOffset.toint()/1000),0,1,1) ' update progress - if we exit player
        'm.metadata.description = m.metadata.description + " on " + firstof(m.metadata.nowplaying_platform_title, m.metadata.nowplaying_platform, "")
        'm.metadata.description = m.metadata.description + chr(10) + m.metadata.nowPlaying_orig_description ' append the original description
    end if
End Sub 

Sub homeScreenActivate(priorScreen)
    RRbreadcrumbDate(m.viewcontroller.screens[0])
    'm.Screen.SetBreadcrumbText("", CurrentTimeAsString())
    m.SuperActivate(priorScreen)
End Sub 