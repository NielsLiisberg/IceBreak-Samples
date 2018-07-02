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

Now - From a IBMi menu prompt start the SSH deamon:

```
===> STRTCPSVR *SSHD
```

Now back to your ACS:

1) Click SSH Terminal in ACS

(or you can use call qp2term – but I suggest that you get use to ssh)

From the ssh / shell prompt:
```
PATH=/QOpenSys/pkgs/bin:$PATH
cd /www
git -c http.sslVerify=false clone https://github.com/NielsLiisberg/IceBreak-Samples.git
```
Note1: You have to ajust your path to use the YUM packages ( here git) 

If you have already installed the YUM in ACS you can install git at the same prompt
```
PATH=/QOpenSys/pkgs/bin:$PATH
yum install git
cd /www
git -c http.sslVerify=false clone https://github.com/NielsLiisberg/IceBreak-Samples.git
```

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
You will see the samples' server running in the IceBreak subsystem. Now we need to compile some of the samples ( still in the 5250 with ICEBREAK on the library list):

```
CRTICEPGM STMF('/www/IceBreak-Samples/router.rpgle') SVRID(samples)
CRTICEPGM STMF('/www/IceBreak-Samples/msProduct.rpgle') SVRID(samples)
```

# Run the first sample
Now it is time to test the sample:

1) Open your browser
2) In the URL type  http://MyIbmi.60060  ( Where myibmi is the TCP/IP address or name of your IBiMi)

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


# Consuming Services
Take a look at msXlate.rpgle 
This service is sending the request to Watson. Under the covers it uses cUrl so you have to installe that first:

From the ssh / shell prompt:
```
PATH=/QOpenSys/pkgs/bin:$PATH
yum install curl
```

Now you can compile it in vsCode with "Shift-Cmd-B"

Before you run it you have to set the PATH environment for you job like:
```
PATH=/QOpenSys/pkgs/bin:$PATH
```


Have fun - and keep me posted :)




