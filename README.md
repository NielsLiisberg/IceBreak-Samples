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

Before you can clone this git repo - you first need to have git on your IBMi:

1) Open ACS and click on "Tools"
2) Click on "Open Source Package Management"
3) Open the "Available packages" tab
4) Click "git" and "Install"

You need to ensure that the ssh deamon is running on your IBM i. So from a IBM i menu prompt start the SSH deamon:

```
===> STRTCPSVR *SSHD
```

Now back to your ACS:

1) Click SSH Terminal in ACS ( or use your default terminal like putty) 

(or you can use call qp2term – but I suggest that you get use to ssh)

2) From the terminal. You can also install git with yum from the commandline if you don't like the above:  
```
ssh myibmi
PATH=/QOpenSys/pkgs/bin:$PATH
yum install git
```
And now i the same ssh session - clone the samples repo 
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
2) In the URL type  http://MyIbmi:60060  ( Where myibmi is the TCP/IP address or name of your IBiMi)

Now you have a RPG services running with an MVVM application in ExtJS as you frontend.

# Using vsCode as you IDE
The Sitemule team has made a cool plugin for vsCode so you can edit and compile RPG code.

In your browser open, download and install both vsCode and node.js 

https://code.visualstudio.com/download

https://nodejs.org/en/

When you open vsCode then:

Open "Extensions" and search for "RPG".
Click on "RPG for IBMi" and you have installed what you need.

If you now map a networkdrive to the /www/IceBreak-samples folder and "drag" that into the vsCode editor - it will open it as workspace (a project) and now the Icebreak compiler is available.

When you click and open a file with RPGLE or SQLRPGLE extension then you can press "Shift-Cmd-B" for build of find the build task in the menu.

# Microservices
In the samples above is as close as you can get with RPG to the Microservice architecture. It is build around a "router" program and a "JSON in/JSON out" service program. This design pattern hides the HTTP protocol so it can be used in stored procedures, data queues and even called directly from other RPG programs. This allows you to make unit test and let your RPG applications work better in a DevOps environment.

The "router" program is always called if the URL begins with "router". It is a regex set in the webconfig.xml. The router parses the URL, parse the input JSON and call the required service. Finally the router serializes the object graph into JSON for the HTTP client.

Take a look at "router.rpgle" and "msProduct.rpgle" - they carry the whole secret!


# Consuming Services
Take a look at msXlate.rpgle .This service is sending the request to Watson. Under the covers it uses cUrl so you have to installe that first:

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




