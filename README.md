# IceBreak-Samples
RPG samples using noxDB, Microservices, ExtJs and Watson

IceBreak is a powerful Web application server that provides a highly reliable, manageable, and scalable Web application infrastructure for the IBM i™. IceBreak runs natively on IBM i™ in the ILE environment - NOT using Apache, WebSphere, node.js or any other moving parts.

# Install IceBreak
First you need the IceBreak server for RPG / ILE. You can download the latest stable community edition from the official site:

http://www.system-method.com/en/page/download-icebreakce

Or you can find the bleeding edge versions here:

http://download.icebreak.org/webfiles/download/icebreak/ 

You need FTP open on your IBM and the install script runs only from Windows.

# Install the samples
You have two options: VSCode centric or IBM i centric

1. [Clone the repo from VSCode and run the **createServer.sh** script](#Install-the-samples-via-VSCode)
2. Install git on the IBM i and clone the repo from IBM i and run the CL commands show later. 

In the end you will have the same result - it is just a matter of taste.
___
## Install the samples via VSCode

You need to ensure that the ssh daemon is running on your IBM i. So from a IBM i menu prompt start the SSH daemon. You also need a ssh client on your PC - If not, please continue with *Install the samples via IBM i*  :

```
===> STRTCPSVR *SSHD
```


1. First install VSCode if you don't have it yet.
2. Ensure that VSCode is configured to have a git client: https://code.visualstudio.com/docs/sourcecontrol/overview
3. Map a drive pointing to your IBM i IFS. Mine is called MY_IBM_I in the following. I use root here where I have made a folder called **/www**    
4. From the VSCode "Explorer window" in a empty project - select the big "clone repository" button. https://code.visualstudio.com/docs/sourcecontrol/overview#_cloning-a-repository
5. When prompted for the repo name please enter: https://github.com/NielsLiisberg/IceBreak-Samples.git
6. Now - when prompted, enter the location of the mapped drive from step 3. For me that was **/www**
7. When the clone process is finished then the "Explorer" window in VSCode will show all the example programs you can play with. 
8. To configure and start you sample server - run this command from the VSCode **New Terminal** window: ```ssh MY_IBM_I "/www/icebreak-samples/createServer.sh";```     
9. When the script completes, it will show you a list of all active server. Among these you will have the **SAMPLES** IceBreak server listening on port 60060 ready to play with.
10. Open you browser and enter: [http://MY_IBM_I:60060](http://MY_IBM_I:60060) and the first application will appear. However - no data ?? Your service-layer wil first be made in a moment..  
11. Before you start editing the examples, please install the VSCode extension **"RPG for IBM i"** 


The **createServer.sh** simply run the following CL commands:
```
ICEBREAK/ADDICESVR SVRID(SAMPLES) TEXT('IceBreak samples') SVRPORT(60060) HTTPPATH('/www/icebreak-samples') WWWDFTDOC('default.html') 
ICEBREAK/STRICESVR SAMPLES
ICEBREAK/WRKICESBS
```
The installation is ready, however the data was missing in our example. now it is time to compile the service that provides the data store for our web-application:


1. Open the the source **msProduct.rpgle** by double clicking in the VSCode "Explorer" window.
2. The source for **msProduct.rpgle**  will now appear in editor window.
3. If you press <CTRL-b> for build OR click *"View"->"Command Palette"->"Build"->"Build: Run Build Task"* then the "IceBreak build system" kick in.
4. Now select the **IceBreak Compile From IFS to application library" will appear. Select that.
5. In the status bar ( The bottom left of the VSCode screen) You can see The number of **Warning, Info and Errors** in the code
6. Clicking on on one of **Warning, Info and Errors** will brin up the "PROBLEMS" window.
7. You will see the "msProduct.rpgle" / "OK compile of /www/icebreak-samples/msProduct.rpgle for server SAMPLES" with a blue info icon to the left.
8. If not... Click on the error icon and it will bring you to the "PROBLEM" in the code. It will place the cursor on the line with error and show the compiler error associated with that line.
9. Fix the error - and press <CTRL-b> for build again - continue from step 3.
10. Not errors? Great !! Click on the search icon in the browser applicatin you have running at [http://MY_IBM_I:60060](http://MY_IBM_I:60060) 
11. We have a service running !! Now examine all the other examples. Some treasures are hidden there ;) 


... Hey wait a minute!! When i look in the *browser console network trace* - it refers to a resource called **router** - is this a magic word? 

No! magic perhaps, but it actually the IceBreak (Just In Time) JIT compiler that behind the scenes compiles the router code. Please fell free to open and edit the **router.rpgle**  magick?  

Perhaps it is time to look at the documentation. The admin-server also provides that: http://MY_IBM_I:7000 or skip to the section *Run the first sample* that covers the above in more details.



Happy IceBreak coding.

*Niels Liisberg.*


___
## Install the samples via IBM i

Before you can clone this git repo - you first need to have git on your IBM i:

1) Open ACS and click on "Tools"
2) Click on "Open Source Package Management"
3) Open the "Available packages" tab
4) Click "git" and "Install"

You need to ensure that the ssh daemon is running on your IBM i. So from a IBM i menu prompt start the SSH daemon:

```
===> STRTCPSVR *SSHD
```

Now back to your ACS:

1) Click SSH Terminal in ACS ( or use your default terminal like putty) 

(or you can use call qp2term – but I suggest that you get use to ssh)

2) From the terminal. You can also install git with yum from the commandline if you don't like the above:  
```
ssh MY_IBM_I
PATH=/QOpenSys/pkgs/bin:$PATH
yum install git
```
And now in the same ssh session - clone the samples repo 
```
cd /www
git -c http.sslVerify=false clone https://github.com/NielsLiisberg/IceBreak-Samples.git
```
As you can see - you have to ajust your path to use yum, git and other opens source tooling  

Go back to a 5250 prompt
```
GO ICEBREAK 
CALL QCMD
ADDICESVR SVRID(SAMPLES) TEXT('IceBreak samples') 
    SVRPORT(60060) HTTPPATH('/www/icebreak-samples') 
    WWWDFTDOC('default.html')          
STRICESVR SAMPLES
WRKICESBS 
```
You will see the samples server running in the IceBreak subsystem. Now we need to compile some of the samples ( still in the 5250 with ICEBREAK on the library list):

```
CRTICEPGM STMF('/www/IceBreak-Samples/router.rpgle') SVRID(samples)
CRTICEPGM STMF('/www/IceBreak-Samples/msProduct.rpgle') SVRID(samples)
```

# Run the first sample
Now it is time to test the sample:

1) Open your browser
2) In the URL type  http://MY_IBM_I:60060  ( Where MY_IBM_I is the TCP/IP address or name of your IBM i)

Now you have a RPG services running with an MVVM application in ExtJS as you frontend.

# Using VSCode as you IDE
The Sitemule team has made a cool plugin for VSCode so you can edit and compile RPG code.

In your browser open, download and install VSCode 

https://code.visualstudio.com/download


When you open VSCode then:

Open "Extensions" and search for "RPG".
Click on "RPG for IBM i" and you have installed what you need.

If you now map a network drive to the /www/IceBreak-samples folder and "drag" that into the VSCode editor - it will open it as workspace (a project) and now the IceBreak compiler is available.

When you click and open a file with RPGLE or SQLRPGLE extension then you can press "Shift-Cmd-B" for build of find the build task in the menu.

# Microservices
In the samples above is as close as you can get with RPG to the Microservice architecture. It is build around a "router" program and a "JSON in/JSON out" service program. This design pattern hides the HTTP protocol so it can be used in stored procedures, data queues and even called directly from other RPG programs. This allows you to make unit test and let your RPG applications work better in a DevOps environment.

The "router" program is always called if the URL begins with "router". It is a regex set in the webconfig.xml. The router parses the URL, parse the input JSON and call the required service. Finally the router serializes the object graph into JSON for the HTTP client.

Take a look at "router.rpgle" and "msProduct.rpgle" - they carry the whole secret!


# Consuming Services
Take a look at msXlate.rpgle .This service is sending the request to Watson. Under the covers it uses cUrl so you have to installed that first:

From the ssh / shell prompt:
```
PATH=/QOpenSys/pkgs/bin:$PATH
yum install curl
```
Before you run the Watson example you have to set up two things: 

1) Get a application key from IBM / Watson: 

https://cloud.ibm.com/docs/iam?topic=iam-manapikey

2) Set the PATH environment for you job to include the opensource tooling - like:

System wide once:

```
ADDENVVAR 
    ENVVAR(PATH) 
    VALUE('/QOpenSys/pkgs/bin:/QOpenSys/usr/bin:/usr/ccs/bin:/QOpenSys/usr/bin/X11:/usr/sbin:.:/usr/bin')
    LEVEL(*SYS)                                                   
```

Or within the job
PATH=/QOpenSys/pkgs/bin:$PATH


Have fun - and keep me posted :)




