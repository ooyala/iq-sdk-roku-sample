# Ooyala IQ Roku SceneGraph example

This app shows you the Roku IQ library integrated with a SceneGraph channel example.

## Roku requirements

The minimum Roku OS version compatible with this library is v7.

## Getting started

The main difference with previous sample version is that IQ is handled as a task node now. This allows communication between a SceneGraph channel and IQ plugin. New plugin version contains two IQ files: **IQ.brs** and **IQ.xml**.

## Integrating the library in your project

Integrating the library in your project is as simple as copying **IQ.brs** to your source folder, like any other source file in your Roku channel. You also need to include **IQ.xml** file in the path where your VideoPlayer object is defined. In this sample app VideoPlayer node path is **components/screens/DetailsScreen**, so here is where you need to copy **IQ.xml** file.

Including both files will allow IQ plugin to have access to all player events. If you see issues when deploying your channel to a Roku device, make sure you have added the file in your zip build script/Makefile.

## Adding IQ to your channel

Using the library in a Roku channel is simple.

1. Instantiate the IQ object in your init code as a **roSGNode**. Make sure you do this in the file where your VideoPlayer object is located. In this sample file is **DetailsScreen.brs**, located in the path **components/screens/DetailsScreen**. You will also need to declare an array object to store player events.

```
Function Init()
    m.iq = CreateObject("roSGNode","IQ")
    m.events = CreateObject("roAssociativeArray")
```
  This step marks the start of the session, and does not report anything back to IQ.

2. Init your IQ session using your pcode and adding it to **IQ.brs** file. The pcode can be found in your Ooyala Backlot account. For more information, refer to Your API Credentials.

```
Sub Init()
    m.PCODE = "YOUR_BACKLOT_PCODE"
```

3.  In **IQ.brs** file you can also define your **userInfo** and **geoInfo** for analytics purposes. You can add this info in Init() method.

```
userInfo = {}
geoInfo = {}
ageGroup ={min : 25, max : 30}

userInfo.AddReplace("emailHashMD5", "dc250da0315f62bbb94dsfsdfvc")
userInfo.AddReplace("userId", "User")
userInfo.AddReplace("gender", "M")
userInfo.AddReplace("ageGroup", ageGroup)

geoInfo.AddReplace("countryCode", "US")
geoInfo.AddReplace("region", "CA")
geoInfo.AddReplace("city", "SANTACLARA")
geoInfo.AddReplace("latitude", 37.399092)
geoInfo.AddReplace("longitude", -121.985771)
geoInfo.AddReplace("geoVendor", "akamai")

```


4. Give IQ the metadata about the video you are about to play. This is done by calling **SetContentMetadata** function from IQ plugin. This is done in **DetailsScreen.brs** file, in the **OnContentChange** method.

```
Sub OnContentChange()
    metadata = {duration : 60, assetId : "AdDgFFGgEergergwrrehEj" , assetType: "external"}
    m.iq.CallFunc("SetContentMetadata", metadata)
```
This code is typically called when you have retrieved information about the content from a server, and before the video starts. The duration should be in seconds.

5. Add an observer to your video player object to get state and position data. This is done in **DetailsScreen.brs** file.

```
Sub onItemSelected()
    m.videoPlayer.observeField("state", "OnVideoPlayerStateChange")
    m.videoPlayer.observeField("position", "OnVideoPlayerStateChange")
```
6. Then modify **OnVideoPlayerStateChange** function to catch state and position data and store it in events array created previously. Then call function **SendEvent** to submit events to IQ plugin. This is done in **DetailsScreen.brs** file.

```
Sub OnVideoPlayerStateChange(message as Object)
    m.events["state"] = m.videoPlayer.state
    m.events["position"] = m.videoPlayer.position
    m.iq.callFunc("SendEvent", m.events)
```

7. When the user requests the content start, call reportPlayRequested. It takes one parameter isAutoplay. Set isAutoplay to true if the content was automatically played without user input.

```
Sub onVideoVisibleChange()
    if m.videoPlayer.visible = true
        m.iq.callFunc("ReportPlayRequested", false)
    end if
```

8. Replays can be reported with reportReplay(). Custom events can also be reported with reportCustomEvent(name, metadata). You can add this calls to **OnVideoPlayerStateChange** method, or add your own method to watch a player custom event.

```
m.iq.callFunc("ReportReplay")
m.iq.callFunc("ReportCustomEvent", "myCustomEvent", {myCustomValue : 42, myCustomParameter : "Scenegraph is awesome!"})
```

9. You can report data to other IQ functions that are declared in **IQ.xml** file. This allows the function to be visible from a Scenegraph channel. For example, here are the functions declarations we previously used like **SendEvent** and **SetContentMetadata**.

```
<interface>
    <function name="SendEvent"/>
    <function name="SetContentMetadata"/>
</interface>
```

## Changelog
### Version 1.0.0 - November 06, 2017

- First version of the Roku SceneGraph example with IQ library.

### Version 1.0.1 - February 12, 2018

- Updating code examples and adding further information.

<br><hr/>
