<cfcomponent hint="bringing some sweet growl lovin to coldFusion apps">
	<!---
		Growl service for coldFusion!
		Author:		David Sirr (david@sparkit.biz)
		Version:	0.1
		Purpose:	Allow users to subscribe to cf apps and recieve data/notifications via Growl
		Notes:		obviously would work best if you've got a static IP as the subscription is mapped to an IP address,
					may be best suited to intranet apps where you're clients IPs may change infrequently.
		Credits:	inspired by growl implementations in java, ruby, and python
					christian cantrell for solving my custom sized byteArray dilemma via an old blog post
		
		Usage:
			1. init CFC with appname
			2. add notification types
			3. register client hosts
			4. send notifications
				sendNotification(notificationType, title, message[, priority = 0, sticky = false])
	 --->
	<cffunction name="Init" returntype="growl" output="false">
		<cfargument name="appName" required="true" type="string" hint="the application identifier for growl" />
		<cfscript>
			variables.instance = structNew();
			variables.instance.appName = arguments.appName;
			variables.instance.aHosts = arrayNew(1);
			variables.instance.aHostsPW = arrayNew(1);
			variables.instance.aNotifications = arrayNew(1);
			variables.instance.aDefaults = arrayNew(1);
			
			// setup growl socket
			variables.instance.growlSocket = createObject('java','java.net.DatagramSocket').Init();
			// setup address object
			variables.instance.InetAddress = createObject('java','java.net.InetAddress');
			variables.instance.growlPort = 9887;
			
			// return instance
			return this;
		</cfscript>
	</cffunction>
	
	<cffunction name="getHosts" returntype="array" output="false">
		<cfscript>
			return variables.instance.aHosts;
		</cfscript>
	</cffunction>
	<cffunction name="getNotifications" returntype="array" output="false">
		<cfscript>
			return variables.instance.aNotifications;
		</cfscript>
	</cffunction>
		
	<cffunction name="getByteArray" access="private" returntype="any" output="false" hint="courtesy christian cantrell's blog">
		<cfargument name="size" type="numeric" required="true"/>
		<cfscript>
			var emptyByteArray = createObject('java','java.io.ByteArrayOutputStream').init().toByteArray();
			var byteClass = emptyByteArray.getClass().getComponentType();
			var byteArray = createObject('java','java.lang.reflect.Array').newInstance(byteClass,javaCast('int',arguments.size));
			return byteArray;
		</cfscript>
	</cffunction>
	
	<cffunction name="addHost" output="false" returntype="void" hint="add host/password to hosts array">
		<cfargument name="host" type="string" required="yes" hint="The host to send message to.">
		<cfargument name="password" type="string" default="" hint="Only needed if client's growl is password protected">
	
		<cfscript>
			var stHost = structNew();
			
			// check whether host is already present
			if(arrayLen(variables.instance.aHosts) EQ 0 OR listFindNoCase(arrayToList(variables.instance.aHosts),arguments.host) EQ 0){
				// add host to array
				arrayAppend(variables.instance.aHosts,arguments.host);
				arrayAppend(variables.instance.aHostsPW,arguments.password);
				// register host
				sendRegistration();
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="addNotification" output="false" returntype="void" hint="add notification type">
		<cfargument name="notification" type="string" required="yes" hint="The notification type">
		<cfargument name="enabled" type="boolean" default="false" hint="is it enabled in growl gui">
	
		<cfscript>
			// check whether notification already present
			if(arrayLen(variables.instance.aNotifications) EQ 0 OR listFindNoCase(arrayToList(variables.instance.aNotifications),arguments.notification) EQ 0){
				// add to the notifications array
				arrayAppend(variables.instance.aNotifications,arguments.notification);
				// add index of this notification to the defaults array if enabled, (index from 0 for java arrays)
				if(arguments.enabled)
					arrayAppend(variables.instance.aDefaults,arrayLen(variables.instance.aNotifications)-1);
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="sendNotification" output="false" returntype="void" hint="send message to growl subscribers with a notification">
		<cfargument name="notificationType" type="string" required="yes" hint="notification type">
		<cfargument name="title" type="string" required="yes" hint="title of message">
		<cfargument name="message" type="string" required="yes" hint="message text">
		<cfargument name="priority" type="numeric" default="0" hint="priority of message, -2 to 2">
		<cfargument name="sticky" type="boolean" default="false" hint="flag to make message sticky or not">
	
		<cfscript>
			var bout = createObject('java','java.io.ByteArrayOutputStream').Init();
			var bytes = arguments.notificationType.getBytes("UTF-8"); // utility var, to be overwritten
			var i = 1;
			
			// Add the growl protocol info and packet type
			bout.write(1); //GROWL_PROTOCOL_VERSION (1)
			bout.write(1); //GROWL_TYPE_NOTIFICATION (1) : The packet type of notification packets with MD5 authentication.
			
			// Encode the flags
			flags = javacast('int',(bitAnd(arguments.priority,7) * 2));
			if (arguments.priority lt 0)
			    flags = bitOr(flags,8);
			if (arguments.sticky)
			    flags = bitOr(flags,1);
			bout.write(bitSHRN(abs(flags),8));
			bout.write(bitAnd(flags,255));
			
			// Encode the lengths of the strings
			bout.write(bitSHRN(len(arguments.notificationType),8));
			bout.write(bitAnd(len(arguments.notificationType),255));
			bout.write(bitSHRN(len(arguments.title),8));
			bout.write(bitAnd(len(arguments.title),255));
			bout.write(bitSHRN(len(arguments.message),8));
			bout.write(bitAnd(len(arguments.message),255));
			bout.write(bitSHRN(len(variables.instance.appName),8));
			bout.write(bitAnd(len(variables.instance.appName),255));
			
			// Encode the strings
			bout.write(bytes);
			bytes = arguments.title.getBytes("UTF-8");
			bout.write(bytes);
			bytes = arguments.message.getBytes("UTF-8");
			bout.write(bytes);
			bytes = variables.instance.appName.getBytes("UTF-8");
			bout.write(bytes);
			
			sendPacket(bout.toByteArray());
		</cfscript>
	</cffunction>
	
	<cffunction name="sendRegistration" output="false" returntype="void" hint="register a new growl recipient with a regisitration notification">
		<cfscript>
			var bout = createObject('java','java.io.ByteArrayOutputStream').Init();
			var bytes = variables.instance.appName.getBytes("UTF-8"); // utility var, to be overwritten
			var i = 1;
			
			// Add the growl protocol info and packet type
			bout.write(1); //GROWL_PROTOCOL_VERSION (1)
			bout.write(0); //GROWL_TYPE_REGISTRATION (0) : The packet type of registration packets with MD5 authentication.
			
			// Add the length of the application name to the packet
			bout.write(bitSHRN(arrayLen(bytes),8));
		    bout.write(bitAnd(arrayLen(bytes),255));
			
			// Append the number of notifications and the number of defaults to the packet
			bout.write(arrayLen(variables.instance.aNotifications));
			bout.write(arrayLen(variables.instance.aDefaults));
			
			// Add the application name to the packet
			bout.write(bytes);
			
			// Write each of the notifications
			for(i=1; i lte arrayLen(variables.instance.aNotifications); i=i+1) {
			    // Write the notification
			    bytes = variables.instance.aNotifications[i].getBytes("UTF-8");
			  	bout.write(bitSHRN(arrayLen(bytes),8));
			    bout.write(bitAnd(arrayLen(bytes),255));
			    bout.write(bytes);
			}
			
			// Write the defauts list
			for(i=1; i lte arrayLen(variables.instance.aDefaults); i=i+1) {
			    bout.write(javaCast('int',variables.instance.aDefaults[i]));
			}
			
			// send the encoded bytes
			sendPacket(bout.toByteArray());
		</cfscript>
	</cffunction>
	
	<cffunction name="sendPacket" access="private" returntype="void" output="false" hint="encodes and sends packet to host subscribers">
		<cfargument name="packet" type="any" hint="data packet, type: java byte array" />
		
		<cfscript>
			var i = 1;
			var finalPacket = arrayNew(1);
			
			// init checksum object
			var md5 = createObject('java','java.security.MessageDigest').getInstance('MD5');
			// init UDP data packet object
			var dataGramPacket = 0;
			// init system object
			var objSystem = createObject('java','java.lang.System');
			
			for(i=1;i lte arrayLen(variables.instance.aHosts);i=i+1){
				// reset md5 checksum
				md5.reset();
				// checksum on data packet
				md5.update(arguments.packet);
				
				// append checksum password if present
				if(variables.instance.aHostsPW[i] NEQ '')
					md5.update(variables.instance.aHostsPW[i].getBytes('UTF-8'));
				
				// create new byte array and append checksum data to packet data
				finalPacket = getByteArray(arrayLen(arguments.packet)+16);
	            objSystem.arraycopy(arguments.packet, 0, finalPacket, 0, arraylen(arguments.packet));
	            objSystem.arraycopy(md5.digest(), 0, finalPacket, arraylen(arguments.packet), 16);
	
				// reinit datagram packet with new data
				dataGramPacket = createObject('java','java.net.DatagramPacket');
				dataGramPacket = dataGramPacket.Init(finalPacket,JavaCast("int",arrayLen(finalPacket)),variables.instance.InetAddress.getByName(variables.instance.aHosts[i]),JavaCast("int",variables.instance.growlPort));
				
				// send packet!
				variables.instance.growlSocket.send(dataGramPacket);
			}
		</cfscript>
	</cffunction>
</cfcomponent>