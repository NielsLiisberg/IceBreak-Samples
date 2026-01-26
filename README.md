# IceBreak-Samples
RPG samples using noxDB, Microservices

IceBreak is a powerful Web application server that provides a highly reliable, manageable, and scalable Web application infrastructure for the IBM i™. IceBreak runs natively on IBM i™ in the ILE environment - NOT using Apache, WebSphere, node.js or any other moving parts.

# Install IceBreak
First you need the IceBreak server for RPG / ILE. You can download i here from the official site:

https://install.icebreak.org/




___
## Install the samples via IBM i

Before you can clone this git repo - you first need to have **git** on your IBM i:

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
    WWWDFTDOC('default.html') DISPTHRMTH(*MULTITHREAD)         
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
2) In the URL type [http://MY_IBM_I:60060](http://MY_IBM_I:60060)  Where MY_IBM_I is the TCP/IP address or name of your IBM i. Or even add the name MY_IBM_I to your ```hosts``` file on your PC 
[Edit host file](https://www.howtogeek.com/howto/27350/beginner-geek-how-to-edit-your-hosts-file/)

Now you have a RPG services running with an MVVM application in ExtJS as you frontend.

# Using VSCode as you IDE
The Sitemule team has made a cool plugin for VSCode so you can edit and compile RPG code.

In your browser open, download and install VSCode 

https://code.visualstudio.com/download


When you open VSCode then:

Open "Extensions" and search for "RPG".
Click on "RPG for IBM i" and you have installed what you need.

If you now map a network drive to the /www/IceBreak-samples folder and "drag" that into the VSCode editor - it will open it as workspace (a project) and now the IceBreak compiler is available.

When you click and open a file with RPGLE or SQLRPGLE extension then you can press "Shift-Cmd-B" for build. Or find the build task in the menu.

# Microservices
In the samples above is as close as you can get with RPG to the Microservice architecture. It is build around a "router" program and a "JSON in/JSON out" service program. This design pattern hides the HTTP protocol so it can be used in stored procedures, data queues and even called directly from other RPG programs. This allows you to make unit test and let your RPG applications work better in a DevOps environment.

The "router" program is always called if the URL begins with "router". It is a regex set in the webconfig.xml. The router parses the URL, parse the input JSON and call the required service. Finally the router serializes the object graph into JSON for the HTTP client.

Take a look at "router.rpgle" and "msProduct.rpgle" - they carry the whole secret!


Happy IceBreak coding and keep me posted :)

*Niels Liisberg.*





