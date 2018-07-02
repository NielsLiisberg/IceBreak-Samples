# IceBreak-Samples
RPG samples using noxDB, Microservices, ExtJs and Watson

IceBreak is a powerful Web application server that provides a highly reliable, manageable, and scalable Web application infrastructure for the IBM i™. IceBreak runs natively on IBM i™ in the ILE environment - NOT using Apache, WebSphere, node.js or any other moving parts.

# Install icebreak
First you need the icebreak server for RPG / ILE. You can download the latest stable community eddition from the offical site:

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

Now back you ACS:
1) Click SSH Terminal in ACS

Now you can open the ssh terminal in ACS 
and you can do ssh ( or you can use call qp2term)

From the ssh / shell prompt:
```
PATH=/QOpenSys/pkgs/bin:$PATH
cd /www
git -c http.sslVerify=false clone https://github.com/NielsLiisberg/IceBreak-Samples.git
```
Note1: You have to ajust your path to use the YUM packages ( here git) 
Note2: If you have already installed the YUM in acs you can install git at the same prompt
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
Now it is ttime to test the sample:

1) Open your browser
2) In the URL type  http://MyIbmi.60060  ( Where myibmi is the TCP/IP address ot name of your IBiMi)

And you have an RPG services running with an MVVM application in ExtJS ads you frontend.

# Microservices
The samples abowe is as close you can get with RPG to the Microservice architecture. It is build arround a "router" program and a "JSON in/JSON out" service program. This design pattern hides the HTTP protocol so it can be used in stored procedures, dataqueus and even called directly from other RPG programs. This allows you to make unit test and let your RPG applications work better in a DevOps environment.

# Consuming Services

